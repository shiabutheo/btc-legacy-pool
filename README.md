 BTC Legacy Pool

**BTC Legacy Pool** is a Clarity smart contract that provides a secure and decentralized crypto inheritance mechanism on the Stacks blockchain. It enables STX holders to create legacy vaults with customizable deadman switch conditions, ensuring assets can be claimed by a designated heir if the owner becomes inactive.

---

 Features

- **Create Legacy Vaults:** Vault owners can assign an heir and define a timeout period (in blocks).
- **Deadman Switch:** Owners must periodically ping the contract (`signal-alive`) to retain control.
- **Auto-Transfer on Inactivity:** If the owner fails to signal within the timeout, the heir can claim the vault assets.
- **Multi-Asset Support:** Supports STX and SIP-010 tokens (optionally extensible).
- **Off-Chain BTC Recovery Linkage:** Owners can store a hash reference to Bitcoin multisig recovery info.
- **Read-Only Views:** Anyone can inspect vault status, heir info, and timeout details.

---

 Contract Overview

| Function | Type | Description |
|-----------|------|-------------|
| `create-vault` | Public | Initialize a legacy vault with heir and timeout. |
| `signal-alive` | Public | Owner updates the last active block height. |
| `claim-inheritance` | Public | Heir claims assets if owner inactive beyond timeout. |
| `get-vault` | Read-only | Get vault details for an owner. |
| `get-last-active` | Read-only | Get the last active block height of an owner. |

---

 Getting Started

### Requirements
- [Stacks blockchain](https://stacks.co/)
- [Clarinet](https://docs.hiro.so/clarinet/overview) for local testing
 Local Development

```bash
# Clone repository
git clone https://github.com/your-username/btc-legacy-pool.git
cd btc-legacy-pool

# Run Clarinet tests (to be added)
clarinet test
