// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IReserveOracle {
    function confirmMint(address to, uint256 amount, bytes calldata proof)
        external
        view
        returns (bool ok, uint256 usdReserves, bool stale, uint256 validUntil, bytes32 domain);
}

contract ZiGX is ERC20 {
    uint8 private constant CUSTOM_DECIMALS = 6;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** CUSTOM_DECIMALS;
    uint256 public constant RESERVE_LOCK_UNTIL = 1_735_689_600; // Jan 1, 2030 UTC

    address public governance; // Gnosis Safe
    IReserveOracle public reserveOracle;
    address public reserveVault;

    mapping(bytes32 => bool) public usedProof;

    uint256 public reserveDataStalePeriod = 1 days;
    uint256 private _cachedReserveRatioBps;
    uint256 private _cachedUsdReserves;
    uint256 private _lastReserveUpdate;

    uint256 public oracleTtl = 15 minutes;
    uint256 public lastOracleUpdateAt;

    uint256 public ratioFloorBps = 10_000;

    uint256 public maxMintPerTx;
    uint256 public maxMintPerDayBps;
    uint256 public mintedToday;
    uint256 public currentMintDay;
    uint256 public maxMintPerHourBps;
    uint256 public mintedInHour;
    uint256 public currentMintHour;

    uint256 public parameterChangeDelay = 1 hours;
    address public pendingReserveOracle;
    uint256 public reserveOracleChangeReadyAt;
    address public pendingReserveVault;
    uint256 public reserveVaultChangeReadyAt;

    uint8 public oracleDecimals = 6;
    uint256 public lastReserveUsd;
    uint256 public lastReserveUpdateAt;

    mapping(uint256 => bytes32) public auditReportHash;
    string public porDashboardRef;
    bool public porRefLocked;
    bytes32 public contractCommitmentHash;

    bool private _paused;

    bytes32 private _lastPoRMerkleRoot;
    string private _lastPoRReportCID;
    uint256 private _lastPoRUpdateAt;

    address public timelock; // OZ TimelockController
    address public guardian; // emergency unpause only

    error NotGovernance();
    error NotTimelock();
    error NotGuardian();

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }

    modifier onlyTimelock() {
        if (msg.sender != timelock) revert NotTimelock();
        _;
    }

    modifier onlyGuardian() {
        if (msg.sender != guardian) revert NotGuardian();
        _;
    }

    event AttestedMint(
        address indexed custodian,
        address indexed to,
        uint256 amount,
        bytes32 indexed depositId,
        uint256 validUntil
    );
    event Redeemed(address indexed from, uint256 amount, bytes32 offchainRef);
    event PoRRootUpdated(bytes32 indexed merkleRoot, string reportCID, uint256 timestamp);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event ReserveOracleUpdated(address indexed prev, address indexed next);
    event ReserveVaultUpdated(address indexed prev, address indexed next);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event MintLimitsUpdated(uint256 maxMintPerTx, uint256 maxMintPerDayBps);
    event HourlyMintLimitUpdated(uint256 maxMintPerHourBps);
    event ProofOfReserveUsed(address indexed to, uint256 amount, uint256 usdReserves, uint256 reserveRatioBps, bytes32 proofHash);
    event ProofConsumed(bytes32 indexed proofHash);
    event MintWindowRolled(uint256 newHourStart);
    event MintedAgainstReserve(address indexed to, uint256 amount);
    event MintApproved(address indexed to, uint256 amount, uint256 newSupply, uint256 confirmedReservesUsd);
    event UserBurned(address indexed from, uint256 amount);
    event GovernanceBurned(address indexed from, uint256 amount, string reason);
    event AuditReportPosted(uint256 indexed quarter, bytes32 hash);
    event PoRDashboardPinned(string ref);
    event PoRRefLocked();
    event CommitmentHashSet(bytes32 hash);
    event EmergencyHalt(string reason);
    event ResumeOperations(string note);
    event OracleTtlUpdated(uint256 previousTtl, uint256 nextTtl);
    event RatioFloorUpdated(uint256 previousFloorBps, uint256 nextFloorBps);
    event ParameterChangeDelayUpdated(uint256 previousDelay, uint256 nextDelay);
    event OracleDecimalsUpdated(uint8 previousDecimals, uint8 nextDecimals);
    event ReserveOracleProposed(address indexed proposedOracle, uint256 readyAt);
    event ReserveOracleActivated(address indexed previousOracle, address indexed newOracle);
    event ReserveVaultProposed(address indexed proposedVault, uint256 readyAt);
    event ReserveVaultActivated(address indexed previousVault, address indexed newVault);

    modifier whenNotPaused() {
        require(!_paused, "ZiGX: mint/burn paused");
        _;
    }

    constructor() ERC20("ZiGX", "ZiGX") {
        governance = msg.sender;
        timelock = msg.sender;
        emit GovernanceTransferred(address(0), msg.sender);
    }

    function setGovernance(address g) external onlyTimelock {
        governance = g;
    }

    function setTimelock(address t) external onlyTimelock {
        timelock = t;
    }

    function setGuardian(address g) external onlyTimelock {
        guardian = g;
    }

    function decimals() public view virtual override returns (uint8) {
        return CUSTOM_DECIMALS;
    }

    function transferGovernance(address newGovernance) external onlyTimelock {
        require(newGovernance != address(0), "ZiGX: zero governance");
        emit GovernanceTransferred(governance, newGovernance);
        governance = newGovernance;
    }

    function setMintLimits(uint256 _maxMintPerTx, uint256 _maxMintPerDayBps) external onlyTimelock {
        require(_maxMintPerDayBps <= 10_000, "ZiGX: day bps too high");
        require(_maxMintPerTx <= MAX_SUPPLY, "ZiGX: tx limit too high");
        maxMintPerTx = _maxMintPerTx;
        maxMintPerDayBps = _maxMintPerDayBps;
        emit MintLimitsUpdated(_maxMintPerTx, _maxMintPerDayBps);
    }

    function setHourlyMintLimit(uint256 _maxMintPerHourBps) external onlyTimelock {
        require(_maxMintPerHourBps <= 10_000, "ZiGX: hour bps too high");
        maxMintPerHourBps = _maxMintPerHourBps;
        emit HourlyMintLimitUpdated(_maxMintPerHourBps);
    }

    function setOracleTtl(uint256 newOracleTtl) external onlyTimelock {
        require(newOracleTtl >= 5 minutes && newOracleTtl <= 24 hours, "ZiGX: ttl range");
        emit OracleTtlUpdated(oracleTtl, newOracleTtl);
        oracleTtl = newOracleTtl;
    }

    function setRatioFloorBps(uint256 newRatioFloorBps) external onlyTimelock {
        require(newRatioFloorBps >= 10_000, "ZiGX: floor too low");
        emit RatioFloorUpdated(ratioFloorBps, newRatioFloorBps);
        ratioFloorBps = newRatioFloorBps;
    }

    function setParameterChangeDelay(uint256 newDelay) external onlyTimelock {
        require(newDelay >= 10 minutes && newDelay <= 48 hours, "ZiGX: delay range");
        emit ParameterChangeDelayUpdated(parameterChangeDelay, newDelay);
        parameterChangeDelay = newDelay;
    }

    function setOracleDecimals(uint8 nextOracleDecimals) external onlyTimelock {
        require(nextOracleDecimals >= 2 && nextOracleDecimals <= 18, "ZiGX: decimals range");
        emit OracleDecimalsUpdated(oracleDecimals, nextOracleDecimals);
        oracleDecimals = nextOracleDecimals;
    }

    function proposeReserveOracle(address newOracle) external onlyTimelock {
        require(newOracle != address(0), "ZiGX: zero oracle");
        require(newOracle.code.length > 0, "ZiGX: oracle !contract");
        pendingReserveOracle = newOracle;
        reserveOracleChangeReadyAt = block.timestamp + parameterChangeDelay;
        emit ReserveOracleProposed(newOracle, reserveOracleChangeReadyAt);
    }

    function activateReserveOracle() external onlyTimelock {
        require(pendingReserveOracle != address(0), "ZiGX: no pending oracle");
        require(block.timestamp >= reserveOracleChangeReadyAt, "ZiGX: oracle change pending");
        address previousOracle = address(reserveOracle);
        reserveOracle = IReserveOracle(pendingReserveOracle);
        pendingReserveOracle = address(0);
        reserveOracleChangeReadyAt = 0;
        emit ReserveOracleActivated(previousOracle, address(reserveOracle));
        emit ReserveOracleUpdated(previousOracle, address(reserveOracle));
    }

    function proposeReserveVault(address newVault) external onlyTimelock {
        require(newVault != address(0), "ZiGX: zero vault");
        require(newVault.code.length > 0, "ZiGX: vault !contract");
        pendingReserveVault = newVault;
        reserveVaultChangeReadyAt = block.timestamp + parameterChangeDelay;
        emit ReserveVaultProposed(newVault, reserveVaultChangeReadyAt);
    }

    function activateReserveVault() external onlyTimelock {
        require(pendingReserveVault != address(0), "ZiGX: no pending vault");
        require(block.timestamp >= reserveVaultChangeReadyAt, "ZiGX: vault change pending");
        address previousVault = reserveVault;
        reserveVault = pendingReserveVault;
        pendingReserveVault = address(0);
        reserveVaultChangeReadyAt = 0;
        emit ReserveVaultActivated(previousVault, reserveVault);
        emit ReserveVaultUpdated(previousVault, reserveVault);
    }

    function setReserveOracle(IReserveOracle newOracle) external onlyTimelock {
        emit ReserveOracleUpdated(address(reserveOracle), address(newOracle));
        reserveOracle = newOracle;
    }

    function setReserveVault(address newVault) external onlyTimelock {
        require(newVault != address(0), "RESERVE_VAULT_ZERO");
        emit ReserveVaultUpdated(reserveVault, newVault);
        reserveVault = newVault;
    }

    function setReserveDataStalePeriod(uint256 newPeriod) external onlyTimelock {
        reserveDataStalePeriod = newPeriod;
    }

    function pause() external onlyGovernance {
        require(!_paused, "ZiGX: already paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function emergencyHalt(string calldata reason) external onlyGovernance {
        emit EmergencyHalt(reason);
        pause();
    }

    function unpause() external onlyGovernance {
        _unpauseInternal("standard");
    }

    function unpause(string calldata note) external onlyGovernance {
        _unpauseInternal(note);
    }

    function guardianUnpause() external onlyGuardian {
        _unpause();
    }

    function _unpauseInternal(string memory note) internal {
        require(_paused, "ZiGX: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
        emit ResumeOperations(note);
    }

    function _unpause() internal {
        _unpauseInternal("guardian");
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function mint(address to, uint256 amount, bytes calldata proof)
        external
        onlyGovernance
        whenNotPaused
    {
        require(address(reserveOracle) != address(0), "ORACLE_NOT_SET");
        require(totalSupply() + amount <= MAX_SUPPLY, "MAX_SUPPLY");

        (bool ok, uint256 usdReserves, bool stale, uint256 validUntil, ) =
            reserveOracle.confirmMint(to, amount, proof);

        require(ok, "ORACLE_REJECTED");
        require(!stale, "ORACLE_STALE");
        require(block.timestamp <= validUntil, "ORACLE_EXPIRED");

        bytes32 depositId = keccak256(proof);

        _finalizeMint(to, amount, usdReserves);

        emit AttestedMint(msg.sender, to, amount, depositId, validUntil);
    }

    function mintAgainstReserve(uint256 amount, bytes calldata proof) external onlyGovernance whenNotPaused {
        require(amount > 0, "ZiGX: amount zero");
        require(totalSupply() + amount <= MAX_SUPPLY, "ZiGX: max supply exceeded");
        if (maxMintPerTx != 0) {
            require(amount <= maxMintPerTx, "ZiGX: tx mint limit");
        }

        uint256 hour = block.timestamp / 1 hours;
        if (hour != currentMintHour) {
            currentMintHour = hour;
            mintedInHour = 0;
            emit MintWindowRolled(hour * 1 hours);
        }

        uint256 day = block.timestamp / 1 days;
        if (day != currentMintDay) {
            currentMintDay = day;
            mintedToday = 0;
        }

        if (maxMintPerDayBps != 0) {
            uint256 dailyLimit = (MAX_SUPPLY * maxMintPerDayBps) / 10_000;
            require(mintedToday + amount <= dailyLimit, "ZiGX: day mint limit");
        }

        if (maxMintPerHourBps != 0) {
            uint256 hourlyLimit = (MAX_SUPPLY * maxMintPerHourBps) / 10_000;
            require(mintedInHour + amount <= hourlyLimit, "ZiGX: hour mint limit");
        }

        require(address(reserveOracle) != address(0), "ORACLE_NOT_SET");
        (bool ok, uint256 usdReserves, bool stale, uint256 validUntil, bytes32 domain) =
            reserveOracle.confirmMint(msg.sender, amount, proof);
        require(ok, "ORACLE_REJECTED");
        require(!stale, "ORACLE_STALE");
        require(block.timestamp <= validUntil, "ORACLE_EXPIRED");

        bytes32 expectedDomain = keccak256(abi.encode(block.chainid, address(this)));
        require(domain == expectedDomain, "ZiGX: oracle domain");

        if (lastOracleUpdateAt != 0) {
            require(block.timestamp - lastOracleUpdateAt <= oracleTtl, "ZiGX: oracle ttl");
        }

        bytes32 proofHash = keccak256(proof);
        require(!usedProof[proofHash], "ZiGX: proof used");

        uint256 normalizedReserves = _normalizeUsdReserves(usdReserves);

        uint256 newSupply = totalSupply() + amount;
        uint256 postRatioBps = (normalizedReserves * 10_000) / newSupply;
        require(postRatioBps >= ratioFloorBps, "ZiGX: reserve ratio");

        mintedToday += amount;
        mintedInHour += amount;
        usedProof[proofHash] = true;

        _finalizeMint(msg.sender, amount, usdReserves);

        emit ProofConsumed(proofHash);
        emit ProofOfReserveUsed(msg.sender, amount, normalizedReserves, _cachedReserveRatioBps, proofHash);
        emit MintedAgainstReserve(msg.sender, amount);
    }

    function _finalizeMint(address to, uint256 amount, uint256 usdReserves) internal {
        uint256 reserves6 = _to6(usdReserves);
        require(totalSupply() + amount <= reserves6, "INSUFFICIENT_RESERVES");

        _mint(to, amount);

        lastReserveUsd = reserves6;
        lastReserveUpdateAt = block.timestamp;

        _updateReserveData(reserves6, totalSupply());

        emit MintApproved(to, amount, totalSupply(), reserves6);
    }

    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit UserBurned(msg.sender, amount);
    }

    function burnForRedemption(uint256 amount, bytes32 offchainRef) external whenNotPaused {
        require(offchainRef != bytes32(0), "ZiGX: invalid offchain ref");
        _burn(msg.sender, amount);
        emit UserBurned(msg.sender, amount);
        emit Redeemed(msg.sender, amount, offchainRef);
    }

    function burnFrom(address account, uint256 amount) external whenNotPaused {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
        emit UserBurned(account, amount);
    }

    function governanceBurn(address account, uint256 amount) external onlyGovernance whenNotPaused {
        _governanceBurn(account, amount, "");
    }

    function governanceBurn(address account, uint256 amount, string calldata reason) external onlyGovernance whenNotPaused {
        _governanceBurn(account, amount, reason);
    }

    function _governanceBurn(address account, uint256 amount, string memory reason) internal {
        require(account != address(0), "ZiGX: burn zero");
        _burn(account, amount);
        emit GovernanceBurned(account, amount, reason);
    }

    function postAuditReport(uint256 quarter, bytes32 hash) external onlyTimelock {
        require(hash != bytes32(0), "ZiGX: invalid hash");
        require(auditReportHash[quarter] == bytes32(0), "ZiGX: quarter set");
        auditReportHash[quarter] = hash;
        emit AuditReportPosted(quarter, hash);
    }

    function pinPoRDashboard(string calldata ref) external onlyTimelock {
        require(bytes(ref).length != 0, "ZiGX: empty ref");
        require(!porRefLocked, "ZiGX: dashboard locked");
        porDashboardRef = ref;
        emit PoRDashboardPinned(ref);
        porRefLocked = true;
        emit PoRRefLocked();
    }

    function setCommitmentHash(bytes32 hash) external onlyTimelock {
        require(hash != bytes32(0), "ZiGX: invalid hash");
        require(contractCommitmentHash == bytes32(0), "ZiGX: commitment set");
        contractCommitmentHash = hash;
        emit CommitmentHashSet(hash);
    }

    function setPoRRoot(bytes32 merkleRoot, string calldata reportCID) external onlyTimelock {
        require(merkleRoot != bytes32(0), "ZiGX: invalid PoR root");
        require(bytes(reportCID).length != 0, "ZiGX: empty report CID");

        _lastPoRMerkleRoot = merkleRoot;
        _lastPoRReportCID = reportCID;
        _lastPoRUpdateAt = block.timestamp;

        emit PoRRootUpdated(merkleRoot, reportCID, block.timestamp);
    }

    function lastPoR()
        external
        view
        returns (bytes32 merkleRoot, string memory reportCID, uint256 updatedAt)
    {
        merkleRoot = _lastPoRMerkleRoot;
        reportCID = _lastPoRReportCID;
        updatedAt = _lastPoRUpdateAt;
    }

    function supplyTelemetry()
        external
        view
        returns (uint256 totalSupplyZiGX, uint256 maxSupplyZiGX)
    {
        totalSupplyZiGX = totalSupply();
        maxSupplyZiGX = MAX_SUPPLY;
    }

    function reserveLockStatement() external view returns (uint256 lockUntil, bool isPastLock) {
        lockUntil = RESERVE_LOCK_UNTIL;
        isPastLock = block.timestamp >= lockUntil;
    }

    function reserveRatioBps() external view returns (uint256 ratio, bool stale) {
        ratio = _cachedReserveRatioBps;
        stale = _isReserveDataStale();
    }

    function cachedUsdReserves() external view returns (uint256 usdReserves, uint256 updatedAt) {
        usdReserves = _cachedUsdReserves;
        updatedAt = _lastReserveUpdate;
    }

    function pegInfo()
        external
        view
        returns (uint256 maxSupply, uint256 total, uint256 reserveRatio, bool oracleStale, uint256 lockUntil, bytes32 commitmentHash, string memory dashboardRef)
    {
        maxSupply = MAX_SUPPLY;
        total = totalSupply();
        reserveRatio = _cachedReserveRatioBps;
        oracleStale = _isReserveDataStale();
        lockUntil = RESERVE_LOCK_UNTIL;
        commitmentHash = contractCommitmentHash;
        dashboardRef = porDashboardRef;
    }

    function _to6(uint256 v) internal view returns (uint256) {
        if (oracleDecimals == 6) return v;
        if (oracleDecimals > 6) return v / (10 ** (oracleDecimals - 6));
        return v * (10 ** (6 - oracleDecimals));
    }

    function _updateReserveData(uint256 usdReserves, uint256 supply) internal {
        _cachedUsdReserves = usdReserves;
        _lastReserveUpdate = block.timestamp;
        lastOracleUpdateAt = block.timestamp;
        if (supply == 0) {
            _cachedReserveRatioBps = 0;
        } else {
            _cachedReserveRatioBps = (usdReserves * 10_000) / supply;
        }
    }

    function _normalizeUsdReserves(uint256 usdReserves) internal view returns (uint256) {
        return _to6(usdReserves);
    }

    function _isReserveDataStale() internal view returns (bool) {
        if (_lastReserveUpdate == 0) {
            return true;
        }
        if (reserveDataStalePeriod == 0) {
            return false;
        }
        return block.timestamp > _lastReserveUpdate + reserveDataStalePeriod;
    }
}
