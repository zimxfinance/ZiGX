# ZiGX Token (Advanced Edition)

ZiGX is a fully reserve-backed, phase-controlled ERC-20 token designed to serve as a sovereign digital asset, pegged 1:1 to USDC with 6 decimal precision. This advanced version includes:

- 🔒 Reserve Locking (cannot mint more than held USD)
- 🧩 Phase-Based Minting Controls (structured rollout)
- 📜 Full Mint Audit Logging (for trust + regulators)
- 🔐 OpenZeppelin-based, Ownable minting only

## Token Details

| Field            | Value                    |
|------------------|--------------------------|
| Name             | ZiGX                     |
| Symbol           | ZiGX                     |
| Decimals         | 6 (USDC-style)           |
| Max Supply       | 100,000,000 ZiGX         |
| Mintable By      | Owner (treasury wallet)  |
| Burnable         | ❌ Disabled              |

## Key Functions

- `setReserveBacking(uint256)` – Update reserve ceiling (manual or oracle-backed)
- `createPhase(string, uint256)` – Create structured rollout phases
- `setPhaseStatus(string, bool)` – Open or close a minting phase
- `mintWithAudit(address, uint256, string)` – Mint only within active phase + reserve limit

## Security & Compliance

- All logic based on OpenZeppelin 4.9.3
- Matches ZiGX whitepaper (2025–2030 vision)
- Designed to support diaspora off-ramps & trust infrastructure

## License

MIT
