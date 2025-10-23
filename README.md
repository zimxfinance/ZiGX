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

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20
- OpenZeppelin Contracts
- [Aderyn](https://github.com/Cyfrin/aderyn) (optional - for static analysis)

### Installing Foundry

```bash
# Install Foundry (foundryup)
curl -L https://foundry.paradigm.xyz | bash

# Run foundryup to install forge, cast, anvil, and chisel
foundryup

# Verify installation
forge --version
```

### Installing Aderyn (Static Analysis Tool)

```bash
# Install Aderyn using cargo
cargo install aderyn

# Or download pre-built binary from releases
# https://github.com/Cyfrin/aderyn/releases

# Verify installation
aderyn --version
```

### Project Setup

```bash
# Clone the repository
git clone <repository-url>
cd **zmixfinance**

# Install dependencies
forge install

# Build contracts
forge build
```

## 🔐 Environment Configuration

### Step 1: Create `.env` file

```bash
# Copy the example environment file
cp .env.example .env
```

### Step 2: Configure your `.env` file

Open `.env` and set the following variables:

```bash
# Network RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY

# Private key for deployment (WITHOUT 0x prefix)
PRIVATE_KEY=your_private_key_here

# Etherscan API key for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

**⚠️ SECURITY WARNING:**
- **NEVER** commit your `.env` file to git
- The `.env` file is already in `.gitignore`
- Never share your private keys or API keys
- Use a dedicated deployment wallet, not your main wallet

### Step 3: Load environment variables

```bash
# Load environment variables (automatically loaded by forge)
source .env
```

### ⚙️ Setting Up HelperConfig Before Deployment

Before deploying the contracts, make sure that all constants in `HelperConfig.s.sol` are properly configured for your target network (Mainnet, Sepolia, or local Anvil). This is critical for correct token distribution and proper functioning of presale/vesting contracts.


> **Important:** All deployment scripts (`DeployScript`) read configuration directly from `HelperConfig`. If `HelperConfig` is not set correctly, the deployment will use placeholder addresses and default values, which will break the deployment and token distribution.

**Note:** The basic network configuration version is set up for **Ethereum Mainnet** and **local Anvil**. You can extend it by adding more chains and their specific configuration as needed.

#### Steps to Configure:

**Set the correct addresses for Mainnet or test network:**

```solidity
   address constant GOVERNANCE = 0x...; // Multisig address
    address constant TREASURY = 0x...; // Treasury address
    IERC20 constant ZIMX_TOKEN = IERC20(0x...); // ZIMX token address
    IERC20 constant STABLECOIN = IERC20(0x...); // USDC address
    uint256 constant PRESALE_RATE_STABLE = ...; // e.g., 100 ZIMX per 1 USDC (6 decimals)
    uint256 constant PRESALE_RATE_ETH = ...; // 0
    uint64 constant PRESALE_START = ...; // e.g., block.timestamp + 1 day
    uint64 constant PRESALE_END = ...; // e.g., PRESALE_START + 7 days
    address constant PRESALE_RESERVE_VAULT = 0x...; // ZiGX Reserve Vault address
    address constant PRESALE_OPS_TREASURY = 0x...; // Operations treasury address
    uint64 constant VESTING_START = ...; // e.g., PRESALE_END + 1 day
    uint64 constant VESTING_CLIFF_DURATION = ...; // e.g., 6 months in seconds
    uint64 constant VESTING_DURATION = ...; // e.g., 4 years in seconds
    address constant VOUCHER_ESCROW = 0x...; // Voucher escrow address
    bool VESTING_REVOCABLE = true/false; // true if vesting can be revoked
```

### Deploying & Verifing Contracts

Deploy and automatically verify a contract on Etherscan. \
Ensure your .env file has all required variables set. \
Remove –verify if you want to deploy without automatic verification.

```bash
forge script script/<ScriptName>.s.sol:<ContractName> \
  --rpc-url $RPC_URL \        # RPC URL of the target network
  --private-key $PRIVATE_KEY \ # Private key for deployment
  --broadcast \               # Send the transaction to the network
  --verify \                  # Automatically verify contract on Etherscan
  --etherscan-api-key $ETHERSCAN_API_KEY # API key for Etherscan verification
```

##### Running Tests

```bash
# Run all tests
forge test

# Run specific contract tests
forge test --match-contract ZiGXTest
forge test --match-contract ZIMXPresaleTest
forge test --match-contract ZIMXVestingTest

# Run with verbosity
forge test -vvv

# Generate coverage report (requires --ir-minimum flag)
forge coverage --ir-minimum -vv

# Generate coverage with lcov output
forge coverage --ir-minimum --report lcov
```

### Running Fuzz Tests

```bash
# Run fuzz tests with increased runs
forge test --fuzz-runs 10000

# Run specific fuzz tests
forge test --match-test "testFuzz" -vv
```

### Gas Reporting

#### Run gas reports for all tests

```bash
forge test --gas-report
```

#### Save detailed gas report

```bash
forge test --gas-report > gas-report.txt
```

### Running Static Analysis (Aderyn)

```bash
# Run Aderyn on the entire project
aderyn .

# Run Aderyn on specific directory
aderyn ./src

# Generate report with specific output
aderyn . -o report.md

# Run with more verbose output
aderyn . --verbose

# The static analysis report is available in: report.md
```

**Note:** The current Aderyn report is included as `report.md` in the repository.

### Troubleshooting

**Coverage Issues:**
If `forge coverage` fails, use the `--ir-minimum` flag:
```bash
forge coverage --ir-minimum -vv
```
This flag is required for complex contracts with inheritance and large codebases.

**Foundry Not Found:**
If `foundryup` command is not found after installation, restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc depending on your shell
```

**Aderyn Installation Issues:******
If you don't have Rust/Cargo installed, first install Rust:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## 📖 Documentation

Comprehensive documentation available in `/docs`:

- **`AUDIT_PLAN`** - Full security audit plan
- **`CRITICAL_AUDIT_FINDINGS.md`** - Security vulnerabilities and fixes
- **`ZIGX_FIXES_APPLIED.md`** - Detailed changelog of security improvements
- **`FIXES_QUICK_REFERENCE.md`** - Quick reference for developers
- **`TEST_UPDATES_SUMMARY.md`** - Test coverage documentation
- **`FUZZ_TESTING_SUMMARY.md`** - Fuzz testing results
- **`ZiGX_Advanced_MainnetFinal.md`** - ZiGX technical documentation
- **`ZiGX_Audit_Plan.md`** - Detailed audit methodology

---

## 🔧 Configuration

### Foundry Configuration

See `foundry.toml` for build settings:
- Solidity version: 0.8.20
- Optimizer: Enabled (200 runs)
- EVM version: Default (supports PUSH0)
- Test depth: Extensive fuzz runs
****

## 🎯 Key Parameters

### ZiGX Token
| Parameter | Value | Description |
|-----------|-------|-------------|
| Max Supply | 1,000,000,000 | Maximum tokens (1B at 6 decimals) |
| Reserve Ratio Floor | 10,000 bps | Minimum 100% backing |
| Reserve Lock Until | Jan 1, 2030 | Reserves locked until this date |
| Oracle TTL | 15 minutes | Maximum oracle data age |
| Parameter Delay | 1 hour | Timelock delay for changes |

### ZIMX Token
| Parameter | Value | Description |
|-----------|-------|-------------|
| Total Supply | 1,000,000,000 | Fixed supply (1B at 6 decimals) |
| Decimals | 6 | Token precision |
| Governance Enable | Jan 1, 2027 | Future governance activation |

### ZIMX Presale
| Parameter | Value | Description |
|-----------|-------|-------------|
| Hard Cap | 100,000,000 | Maximum tokens for sale (10%) |
| Raise Target | £10,000,000 | Target raise amount |
| Reserve Split | 50% | Portion to ZiGX reserves |
| Buyer Max | 1,000,000 | Default per-wallet limit |

---

## 🛡️ Security Considerations

### For Integrators

1. **ZiGX Reserve Backing**
   - Always verify reserve ratio via `reserveRatioBps()`
   - Check reserve data staleness
   - Monitor Proof-of-Reserve updates via events

2. **Rate Limits**
   - ZiGX has transaction, hourly, and daily mint limits
   - Large mints may need to be split across time periods
   - Monitor rate limit events

3. **Pause Mechanism**
   - All contracts can be paused in emergencies
   - Implement pause checks in integration logic
   - Guardian can unpause without timelock

4. **Oracle Dependency**
   - ZiGX requires functional reserve oracle
   - Oracle outages prevent minting (by design)
   - Burning always available regardless of oracle

### For Users

1. **ZIMX Presale**
   - Complete KYC before presale period
   - Check buyer limits before purchasing
   - Verify sale is active (between start/end times)

2. **ZIMX Vesting**
   - Vested tokens must be claimed via `release()`
   - Check vesting progress via `releasable(address)`
   - Revocable vesting can be cancelled by governance

3. **ZiGX Stability**
   - Backed 100%+ by reserves
   - Burns enable redemption path
   - Monitor reserve ratio for over-collateralization

---

## 📞 Support & Resources

### Audit Documents
- Static analysis report: `report.md` (Aderyn)
- Security audit: `docs/CRITICAL_AUDIT_FINDINGS.md`
- Test coverage: `docs/TEST_UPDATES_SUMMARY.md`

### Contract Addresses

*To be added after deployment*

- **ZIMX Token:** `0x...`
- **ZiGX Token:** `0x...`
- **ZIMX Presale:** `0x...`
- **ZIMX Vesting:** `0x...`
- **Reserve Oracle:** `0x...`
- **Governance Multisig:** `0x...`
- **Timelock Controller:** `0x...`

---

## 🤝 Contributing

This is a production-ready DeFi protocol. Any proposed changes should:

1. Include comprehensive tests
2. Pass all existing tests
3. Maintain or improve coverage
4. Follow security best practices
5. Include relevant documentation

---

## ⚖️ License

MIT License - See `LICENSE` file for details

---

## 🏆 Key Achievements

✅ **Security Hardened**
- 8 critical vulnerabilities fixed
- Comprehensive reentrancy protection
- Zero-address and overflow protections

✅ **Extensively Tested**
- 176+ tests with 100% pass rate
- 1,280+ fuzz test runs
- Invariant testing for critical properties

✅ **Production Ready**
- Static analysis clean (Aderyn)
- Event emissions for all state changes
- Comprehensive documentation

✅ **Transparent**
- On-chain Proof-of-Reserve
- Audit reports published
- All code open-source

---

## 📊 Metrics

```
Total Contracts:     4 (ZiGX, ZIMX, Presale, Vesting)
Total Lines (src):   ~1,600 SLOC
Test Coverage:       176+ tests passing
Fuzz Runs:          1,280+ successful
Security Level:     🟢 Production Ready
Documentation:      Comprehensive
```

---

**Built with security, transparency, and community in mind. 🚀**

For technical questions or security concerns, please refer to the documentation in `/docs` or review the audit findings.
