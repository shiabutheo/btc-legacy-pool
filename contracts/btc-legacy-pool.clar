;; Legacy Vault Smart Contract
;; Allows users to create inheritance vaults with time-locked access

(define-constant ERR_INVALID_LOCK_PERIOD (err u100))
(define-constant ERR_NO_BALANCE (err u101))
(define-constant ERR_VAULT_INACTIVE (err u102))
(define-constant ERR_NO_HEIR (err u103))
(define-constant ERR_NOT_HEIR (err u104))
(define-constant ERR_STILL_LOCKED (err u105))
(define-constant ERR_VAULT_NOT_FOUND (err u106))
(define-constant ERR_TRANSFER_FAILED (err u107))

(define-data-var admin principal tx-sender)

(define-map vaults
  principal ;; owner
  { 
    heir: (optional principal),
    unlock-block: uint,
    balance: uint,
    active: bool 
  }
)

(define-public (create-vault (heir principal) (lock-period uint) (amount uint))
  (begin
    (asserts! (> lock-period u0) ERR_INVALID_LOCK_PERIOD)
    (asserts! (> amount u0) ERR_NO_BALANCE)
    
    (let ((current-block stacks-block-height))
      ;; Transfer STX to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Create vault entry
      (map-set vaults tx-sender
        { 
          heir: (some heir),
          unlock-block: (+ current-block lock-period),
          balance: amount,
          active: true 
        }
      )
      (ok true)
    )
  )
)

(define-public (signal-alive)
  (match (map-get? vaults tx-sender)
    vault
    (begin
      (map-set vaults tx-sender
        { 
          heir: (get heir vault),
          unlock-block: (+ stacks-block-height u10000), ;; extend by 10k blocks
          balance: (get balance vault),
          active: true 
        }
      )
      (ok true)
    )
    ERR_VAULT_NOT_FOUND
  )
)

(define-public (claim-inheritance (owner principal))
  (match (map-get? vaults owner)
    vault
    (begin
      (asserts! (get active vault) ERR_VAULT_INACTIVE)
      (asserts! (is-some (get heir vault)) ERR_NO_HEIR)
      (asserts! (is-eq (unwrap-panic (get heir vault)) tx-sender) ERR_NOT_HEIR)
      (asserts! (> stacks-block-height (get unlock-block vault)) ERR_STILL_LOCKED)
      
      ;; Transfer STX from contract to heir
      (let ((amount (get balance vault)))
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-delete vaults owner)
        (ok amount)
      )
    )
    ERR_VAULT_NOT_FOUND
  )
)

(define-public (cancel-vault)
  (match (map-get? vaults tx-sender)
    vault
    (begin
      (asserts! (get active vault) ERR_VAULT_INACTIVE)
      
      ;; Return STX to owner
      (let ((amount (get balance vault)))
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-delete vaults tx-sender)
        (ok amount)
      )
    )
    ERR_VAULT_NOT_FOUND
  )
)

(define-public (update-heir (new-heir principal))
  (match (map-get? vaults tx-sender)
    vault
    (begin
      (asserts! (get active vault) ERR_VAULT_INACTIVE)
      
      (map-set vaults tx-sender
        {
          heir: (some new-heir),
          unlock-block: (get unlock-block vault),
          balance: (get balance vault),
          active: true
        }
      )
      (ok true)
    )
    ERR_VAULT_NOT_FOUND
  )
)

(define-public (deactivate-vault)
  (match (map-get? vaults tx-sender)
    vault
    (begin
      (asserts! (get active vault) ERR_VAULT_INACTIVE)
      
      (map-set vaults tx-sender
        {
          heir: (get heir vault),
          unlock-block: (get unlock-block vault),
          balance: (get balance vault),
          active: false
        }
      )
      (ok true)
    )
    ERR_VAULT_NOT_FOUND
  )
)

;; Read-only functions
(define-read-only (get-vault (owner principal))
  (map-get? vaults owner)
)

(define-read-only (get-vault-status (owner principal))
  (match (map-get? vaults owner)
    vault
    (ok {
      active: (get active vault),
      has-heir: (is-some (get heir vault)),
      blocks-until-unlock: (if (> (get unlock-block vault) stacks-block-height)
                            (- (get unlock-block vault) stacks-block-height)
                            u0),
      balance: (get balance vault)
    })
    ERR_VAULT_NOT_FOUND
  )
)

(define-read-only (can-claim-inheritance (owner principal) (claimer principal))
  (match (map-get? vaults owner)
    vault
    (ok (and 
      (get active vault)
      (is-some (get heir vault))
      (is-eq (unwrap-panic (get heir vault)) claimer)
      (> stacks-block-height (get unlock-block vault))
    ))
    ERR_VAULT_NOT_FOUND
  )
)

(define-read-only (get-admin)
  (ok (var-get admin))
)
