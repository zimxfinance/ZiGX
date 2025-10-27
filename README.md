# ZiGX By ZimX Finance 

ZimX Finance introduces its dual-token DeFi ecosystem featuring a USD-pegged reserve-backed token (ZiGX) and a utility governance token (ZIMX), built on Ethereum with comprehensive security features and transparent Proof-of-Reserve mechanisms.

## 🎯 Overview

ZMIX Finance introduces an innovative tokenomics model combining:
- **ZiGX**: A 100%+ USD-backed stablecoin with on-chain reserve verification
- **ZIMX**: A fixed-supply utility token with governance capabilities
- **Transparent Operations**: Full on-chain transparency with Proof-of-Reserve attestations
- **Multi-signature Governance**: Timelock-controlled parameter changes for security


### 1. ZiGX (Reserve-Backed Token)

A USD-pegged token backed by 100%+ reserves with on-chain verification and rate limiting.

**Key Features:**
- ✅ **100%+ Reserve Backing**: Every token minted requires verified USD reserves
- ✅ **Oracle-Verified Minting**: All mints validated by external reserve oracle
- ✅ **Rate Limiting**: Per-transaction, hourly, and daily mint limits
- ✅ **Proof-of-Reserve**: On-chain merkle root and IPFS attestations
- ✅ **Time-Delayed Parameter Changes**: Security through timelock governance
- ✅ **Reentrancy Protection**: Comprehensive guards against attacks
- ✅ **Emergency Controls**: Pause mechanism with guardian override

**Core Specifications:**
- **Decimals:** 6
- **Max Supply:** 1,000,000,000 tokens (1B)
- **Minimum Reserve Ratio:** 100% (10,000 bps)

**Security Features:**
- ReentrancyGuard on all mint/burn functions
- Checks-Effects-Interactions (CEI) pattern
- Domain verification for oracle calls
- Proof replay protection
- Overflow/underflow protection in decimal conversions

**Governance:**
- Three-role model: `governance`, `timelock`, `guardian`
- Timelock-enforced parameter changes (1 hour delay)
- Propose/activate pattern for critical updates (oracle, vault)

**Minting Process:**
```
1. Governance submits mint request with proof
2. Oracle validates reserves and returns attestation
3. Contract verifies:
   - Reserve ratio >= 100%
   - Rate limits not exceeded
   - Proof not previously used
   - Oracle data not stale
4. Tokens minted, reserves cached
5. Events emitted for transparency

---

## 🔒 Security Features

### Multi-Layer Protection

1. **Reentrancy Guards**
   - OpenZeppelin ReentrancyGuard on all contracts
   - Checks-Effects-Interactions pattern enforced
   - State updates before external calls

2. **Access Control**
   - Three-role governance (governance/timelock/guardian)
   - Time-delayed parameter changes
   - Two-step ownership transfers
   - Zero-address protections

3. **Rate Limiting (ZiGX)**
   - Per-transaction limits
   - Hourly mint limits
   - Daily mint limits
   - Proof replay protection

4. **Oracle Security**
   - Domain verification (chain ID + contract address)
   - Staleness checks (TTL enforcement)
   - Proof expiration validation
   - Reserve ratio enforcement (>=100%)

5. **Emergency Controls**
   - Pause mechanism on all contracts
   - Guardian emergency unpause
   - Parameter freeze (presale)
   - Emergency halt with reason logging

### Audit & Testing

- ✅ **Unit Tests** 
- ✅ **Comprehensive Fuzz Testing** 
- ✅ **Invariant Tests**
- ✅ **Integration Tests** 
- ✅ **Event Verification** 
- ✅ **Coverage Reports**
- ✅ **Static Analysis** 

**Test Coverage:**
- ZiGX: 168 tests

---
