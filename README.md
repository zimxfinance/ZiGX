# ZiGX Mainnet Deployment Package

This package contains the final, production-ready smart contract for the ZiGX token to be deployed on Base Mainnet.

## Purpose

ZiGX is a reserve-backed digital token pegged 1:1 to the US dollar. Its architecture is designed to guarantee stability, transparency, and immutability through fixed-supply minting phases and auditable reserve control.

## Files

- `ZiGX_Advanced_MainnetFinal.sol`: The full, verified ZiGX smart contract with NatSpec comments and frontend-ready pagination support.
- `README.md`: This documentation.

## Deployment Notes

- Solidity Version: `^0.8.19`
- Verifiable on: `BaseScan`
- Ownership controlled via `Ownable` (transferable to multisig post-deployment)
- Minting is limited to predefined `phases` with strict caps and reserve backing enforcement.
- No upgradeability or burn logic to preserve transparency and immutability.

## Verification Instructions

After deploying to Base Mainnet using Remix or Hardhat:
1. Verify contract on BaseScan using the included `.sol` file.
2. Ensure constructor has no arguments.
3. Match compiler version to `0.8.19`, optimization enabled.

## Legal & Technical Notice

This smart contract is final, immutable, and non-upgradeable. The architecture deliberately excludes proxies, upgradable patterns, or administrative minting powers outside of predefined reserve phases. This design aligns with best practices for public trust, auditability, and regulatory readiness.

---

Blackmass Enterprises Ltd | ZiGX Token Project