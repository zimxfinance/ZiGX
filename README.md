# ZMIX Finance

A dual-token DeFi ecosystem featuring a USD-pegged reserve-backed token (ZiGX) and a utility governance token (ZIMX), built on Ethereum with comprehensive security features and transparent Proof-of-Reserve mechanisms.

## 🎯 Overview

ZMIX Finance introduces an innovative tokenomics model combining:
- **ZiGX**: A 100%+ USD-backed stablecoin with on-chain reserve verification
- **ZIMX**: A fixed-supply utility token with governance capabilities
- **Transparent Operations**: Full on-chain transparency with Proof-of-Reserve attestations
- **Multi-signature Governance**: Timelock-controlled parameter changes for security

## 📊 Key Contracts

### 1. ZiGX (Reserve-Backed Token)

**File:** `src/ZiGX_Advanced_MainnetFinal.sol`

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
- **Reserve Lock:** Until January 1, 2030 (timestamp: 1,735,689,600)
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
```

---

### 2. ZIMX Token (Utility Token)

**File:** `src/ZIMXTokenFINALDEPLOY.sol`

Fixed-supply utility token with governance capabilities and permit functionality.

**Key Features:**
- ✅ **Fixed Supply**: 1,000,000,000 tokens (1B) at 6 decimals
- ✅ **ERC-20 Compatible**: Full standard compliance
- ✅ **ERC-2612 Permit**: Gasless approvals via signatures
- ✅ **Burnable**: Token holders can burn their tokens
- ✅ **Pausable**: Emergency stop mechanism
- ✅ **Governance Controls**: Timelock-enforced administrative actions

**Core Specifications:**
- **Decimals:** 6
- **Total Supply:** 1,000,000,000 tokens (fixed at deployment)
- **Initial Mint:** 100% to treasury at deployment
- **Supply Management:** Treasury can distribute to presale, vesting, etc.

**Token Distribution:**
- 🎫 **Presale**: 100M tokens (10%)
- 👥 **Team Vesting**: Allocated via vesting contract
- 🏛️ **Treasury**: Remaining tokens for ecosystem growth

**Security Features:**
- Pause mechanism for emergencies
- Timelock-controlled treasury operations
- Guardian emergency unpause
- ERC-20 token recovery for accidentally sent tokens
- Two-step governance transfer

**Governance:**
- Timelock-enforced parameter changes
- Treasury sealing mechanism (permanent lock)
- On-chain promise tracking for commitments

---

### 3. ZIMX Presale

**File:** `src/ZIMXPresale.sol`

Presale contract for ZIMX token distribution with KYC enforcement and reserve funding.

**Key Features:**
- ✅ **KYC Enforcement**: Only verified participants can purchase
- ✅ **Stablecoin Purchases**: Accepts USDC/USDT
- ✅ **Per-Wallet Caps**: Prevents whale concentration
- ✅ **Hard Cap**: 100M tokens maximum
- ✅ **Reserve Funding**: 50% of proceeds to ZiGX reserve
- ✅ **Timelock Protection**: Parameter changes require time delay

**Core Specifications:**
- **Hard Cap:** 100,000,000 tokens (10% of ZIMX supply)
- **Raise Target:** £10,000,000 (normalized to 18 decimals)
- **Default Buyer Max:** 1,000,000 tokens per wallet
- **Reserve Split:** 50% to reserve vault, 50% to operations

**Presale Flow:**
```
1. Governance sets sale parameters (rate, times, vaults)
2. KYC provider approves participants
3. Users purchase with stablecoin during sale period
4. After end time, governance finalizes:
   - Validates proceeds meet expected total
   - Splits funds: 50% reserve, 50% ops
   - Handles unsold tokens (burn or transfer)
5. Dust sweeping after 7-day delay
```

**Security Features:**
- ReentrancyGuard on all purchase/finalization functions
- Timelock-controlled parameter changes
- Parameter freeze mechanism
- Expected total validation with tolerance
- Finalization delay enforcement
- KYC reference tracking

**ETH Purchases:**
⚠️ **Disabled** - This presale only accepts stablecoins

---

### 4. ZIMX Vesting

**File:** `src/ZIMXVesting.sol`

Linear vesting contract for team token allocations with cliff and revocation support.

**Key Features:**
- ✅ **Linear Vesting**: Tokens unlock proportionally over time
- ✅ **Cliff Period**: Initial waiting period before vesting starts
- ✅ **Batch Operations**: Create multiple schedules efficiently
- ✅ **Revocable Vesting**: Governance can revoke unvested tokens
- ✅ **Self-Service Claims**: Beneficiaries claim their vested tokens
- ✅ **Accounting Protection**: TotalLocked tracking prevents over-distribution

**Core Specifications:**
- **Presale Allocation Reference:** 100,000,000 tokens (for analytics)
- **Vesting Type:** Linear (proportional to elapsed time)
- **Cliff Support:** Configurable cliff period from start
- **Global Parameters:** Set at deployment (start, cliff, duration)

**Vesting Schedule:**
```
Constructor Parameters:
- token: ZIMX token address
- governance: Multisig address
- start: Vesting start timestamp
- cliffDuration: Cliff period (e.g., 6 months)
- duration: Total vesting period (e.g., 4 years)
- revocable: Whether schedules can be revoked

Vesting Calculation:
If time < start + cliff:
  vested = 0
Else if time >= start + duration:
  vested = totalAmount
Else:
  vested = (totalAmount * elapsed) / duration
  where elapsed = time - start
```

**Vesting Flow:**
```
1. Governance funds contract with ZIMX tokens
2. Timelock creates vesting schedules via batchCreateSchedules()
3. Time passes...
4. Beneficiaries call release() to claim vested tokens
5. Governance can revoke() unvested tokens if revocable
```

**Security Features:**
- ReentrancyGuard on all token operations
- Total locked accounting (prevents over-distribution)
- Underflow protection in vesting calculations
- Batch size limits to prevent gas issues
- Revocation safeguards (pays vested, returns unvested)
- Two-step governance transfer

**On-Chain Promises:**
- Record commitments on-chain
- Track promise status (Pending/Kept/Broken)
- Transparency for community

---

## 🏗️ Architecture

### Contract Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                      Governance (Multisig)                  │
│                            +                                │
│                         Timelock                            │
└────────────────┬────────────────┬──────────────────────────┘
                 │                │
                 │                │
      ┌──────────▼─────┐   ┌─────▼──────────┐
      │  ZIMX Token    │   │  ZiGX Token    │
      │  (Utility)     │   │  (Stablecoin)  │
      └────────┬───────┘   └───────┬────────┘
               │                   │
               │                   │
      ┌────────▼───────┐   ┌───────▼────────┐
      │ ZIMX Presale   │   │ Reserve Oracle │
      └────────┬───────┘   └────────────────┘
               │
      ┌────────▼───────┐
      │ ZIMX Vesting   │
      └────────────────┘
```

### Token Lifecycle

**ZIMX Distribution:**
```
1. Deploy ZIMX Token → Mints 1B to Treasury
2. Transfer tokens to Presale contract
3. Presale sells 100M tokens (10% of supply)
4. Proceeds split: 50% → ZiGX Reserve, 50% → Operations
5. Remaining tokens → Vesting contracts for team
6. Treasury → Ecosystem development, partnerships
```

**ZiGX Lifecycle:**
```
1. Deploy ZiGX Token
2. Set up Reserve Oracle
3. Configure Reserve Vault
4. Governance submits mint proof
5. Oracle validates reserves
6. Tokens minted (1:1 USD backing)
7. Users can burn anytime (redemption)
```

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

- ✅ **176+ Unit Tests** (100% passing)
- ✅ **Comprehensive Fuzz Testing** (1,280+ test runs)
- ✅ **Invariant Tests** for critical properties
- ✅ **Integration Tests** for deploy scripts
- ✅ **Event Verification** for all state changes
- ✅ **Coverage Reports** available in `/coverage` (run with `forge coverage --ir-minimum -vv`)
- ✅ **Static Analysis** via Aderyn (see `report.md` - run with `aderyn .`)

**Test Coverage:**
- ZiGX: 168 tests
- ZIMX Token: [Run `forge test --match-contract ZIMXToken`]
- ZIMX Presale: [Run `forge test --match-contract ZIMXPresale`]
- ZIMX Vesting: [Run `forge test --match-contract ZIMXVesting`]

---
