// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/ERC20.sol";

interface IReserveOracle {
    function confirmMint(address to, uint256 amount, bytes calldata proof)
        external
        view
        returns (bool ok, uint256 usdReserves, bool stale);
}

contract ZiGX is ERC20 {
    uint8 private constant CUSTOM_DECIMALS = 6;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** CUSTOM_DECIMALS;
    uint256 public constant RESERVE_LOCK_UNTIL = 1_735_689_600; // Jan 1, 2030 UTC

    address public governance;
    address public reserveOracle;
    address public reserveVault;

    uint256 public reserveDataStalePeriod = 1 days;
    uint256 private _cachedReserveRatioBps;
    uint256 private _cachedUsdReserves;
    uint256 private _lastReserveUpdate;

    uint256 public maxMintPerTx;
    uint256 public maxMintPerDayBps;
    uint256 public mintedToday;
    uint256 public currentMintDay;

    mapping(uint256 => bytes32) public auditReportHash;
    string public porDashboardRef;
    bytes32 public contractCommitmentHash;

    bool private _paused;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event ReserveOracleUpdated(address indexed previousOracle, address indexed newOracle);
    event ReserveVaultUpdated(address indexed previousVault, address indexed newVault);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event MintLimitsUpdated(uint256 maxMintPerTx, uint256 maxMintPerDayBps);
    event ProofOfReserveUsed(address indexed to, uint256 amount, uint256 usdReserves, uint256 reserveRatioBps, bytes32 proofHash);
    event MintedAgainstReserve(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event GovernanceBurned(address indexed from, uint256 amount);
    event AuditReportPosted(uint256 indexed quarter, bytes32 hash);
    event PoRDashboardPinned(string ref);
    event CommitmentHashSet(bytes32 hash);

    modifier onlyGovernance() {
        require(msg.sender == governance, "ZiGX: not governance");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "ZiGX: mint/burn paused");
        _;
    }

    constructor() ERC20("ZiGX", "ZiGX") {
        governance = msg.sender;
        emit GovernanceTransferred(address(0), msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return CUSTOM_DECIMALS;
    }

    function transferGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "ZiGX: zero governance");
        emit GovernanceTransferred(governance, newGovernance);
        governance = newGovernance;
    }

    function setReserveOracle(address newOracle) external onlyGovernance {
        require(newOracle != address(0), "ZiGX: zero oracle");
        emit ReserveOracleUpdated(reserveOracle, newOracle);
        reserveOracle = newOracle;
    }

    function setReserveVault(address newVault) external onlyGovernance {
        require(newVault != address(0), "ZiGX: zero vault");
        emit ReserveVaultUpdated(reserveVault, newVault);
        reserveVault = newVault;
    }

    function setMintLimits(uint256 _maxMintPerTx, uint256 _maxMintPerDayBps) external onlyGovernance {
        require(_maxMintPerDayBps <= 10_000, "ZiGX: day bps too high");
        require(_maxMintPerTx <= MAX_SUPPLY, "ZiGX: tx limit too high");
        maxMintPerTx = _maxMintPerTx;
        maxMintPerDayBps = _maxMintPerDayBps;
        emit MintLimitsUpdated(_maxMintPerTx, _maxMintPerDayBps);
    }

    function setReserveDataStalePeriod(uint256 newPeriod) external onlyGovernance {
        reserveDataStalePeriod = newPeriod;
    }

    function pause() external onlyGovernance {
        require(!_paused, "ZiGX: already paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyGovernance {
        require(_paused, "ZiGX: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function mintAgainstReserve(uint256 amount, bytes calldata proof) external onlyGovernance whenNotPaused {
        require(amount > 0, "ZiGX: amount zero");
        require(totalSupply() + amount <= MAX_SUPPLY, "ZiGX: max supply exceeded");
        if (maxMintPerTx != 0) {
            require(amount <= maxMintPerTx, "ZiGX: tx mint limit");
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

        require(reserveOracle != address(0), "ZiGX: oracle unset");
        (bool ok, uint256 usdReserves, bool stale) = IReserveOracle(reserveOracle).confirmMint(msg.sender, amount, proof);
        require(ok, "ZiGX: oracle denied");
        require(!stale, "ZiGX: oracle stale");

        mintedToday += amount;

        uint256 newSupply = totalSupply() + amount;
        _updateReserveData(usdReserves, newSupply);

        _mint(msg.sender, amount);

        bytes32 proofHash = keccak256(proof);
        emit ProofOfReserveUsed(msg.sender, amount, usdReserves, _cachedReserveRatioBps, proofHash);
        emit MintedAgainstReserve(msg.sender, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external whenNotPaused {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
        emit Burned(account, amount);
    }

    function governanceBurn(address account, uint256 amount) external onlyGovernance whenNotPaused {
        _burn(account, amount);
        emit GovernanceBurned(account, amount);
    }

    function postAuditReport(uint256 quarter, bytes32 hash) external onlyGovernance {
        require(hash != bytes32(0), "ZiGX: invalid hash");
        require(auditReportHash[quarter] == bytes32(0), "ZiGX: quarter set");
        auditReportHash[quarter] = hash;
        emit AuditReportPosted(quarter, hash);
    }

    function pinPoRDashboard(string calldata ref) external onlyGovernance {
        require(bytes(ref).length != 0, "ZiGX: empty ref");
        require(bytes(porDashboardRef).length == 0, "ZiGX: dashboard set");
        porDashboardRef = ref;
        emit PoRDashboardPinned(ref);
    }

    function setCommitmentHash(bytes32 hash) external onlyGovernance {
        require(hash != bytes32(0), "ZiGX: invalid hash");
        require(contractCommitmentHash == bytes32(0), "ZiGX: commitment set");
        contractCommitmentHash = hash;
        emit CommitmentHashSet(hash);
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

    function _updateReserveData(uint256 usdReserves, uint256 supply) internal {
        _cachedUsdReserves = usdReserves;
        _lastReserveUpdate = block.timestamp;
        if (supply == 0) {
            _cachedReserveRatioBps = 0;
        } else {
            _cachedReserveRatioBps = (usdReserves * 10_000) / supply;
        }
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
