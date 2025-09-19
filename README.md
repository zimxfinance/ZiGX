# ZiGX Contracts

Smart contracts for the **ZiGX token**, to be deployed on Base L2.  
ZiGX is a USDC-backed settlement token used for reserves, remittances and SME payments.

🌐 [zigx.io](https://zigx.io)

---

## Contracts
- **ZiGX_Advanced_MainnetFinal.sol** – capped supply settlement token (100M max supply)

---

## Features
- Fixed supply (100,000,000 ZiGX)
- Minting only with signed custodian attestations (EIP-712)
- Burn-for-redemption with off-chain payout references
- Proof-of-Reserves anchoring (merkle root + report CID)
- Governance functions locked until 2027
- Admin through multisig + timelock

