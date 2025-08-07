// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol";

contract ZiGX is ERC20, Ownable {
    uint8 private constant CUSTOM_DECIMALS = 6;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 6; // 100M ZiGX with 6 decimals

    struct Phase {
        string name;
        uint256 cap;
        uint256 minted;
        bool isOpen;
    }

    mapping(string => Phase) public phases;
    string[] public phaseList;

    // USDC reserve value, 6 decimals
    uint256 public reserveBacking;

    event PhaseCreated(string name, uint256 cap);
    event PhaseStatusChanged(string name, bool isOpen);
    event ReserveUpdated(uint256 newReserve);
    event MintedWithAudit(address indexed to, uint256 amount, string phase, uint256 reserveAfter);

    constructor() ERC20("ZiGX", "ZiGX") {}

    function decimals() public view virtual override returns (uint8) {
        return CUSTOM_DECIMALS;
    }

    function setReserveBacking(uint256 _newBacking) external onlyOwner {
        require(_newBacking >= totalSupply(), "ZiGX: backing below supply");
        reserveBacking = _newBacking;
        emit ReserveUpdated(_newBacking);
    }

    // phase-based unlock logic
    function createPhase(string memory _name, uint256 _cap) external onlyOwner {
        require(_cap > 0, "Cap must be greater than zero");
        require(phases[_name].cap == 0, "Phase already exists");
        phases[_name] = Phase(_name, _cap, 0, false);
        phaseList.push(_name);
        emit PhaseCreated(_name, _cap);
    }

    function setPhaseStatus(string memory _name, bool _isOpen) external onlyOwner {
        require(phases[_name].cap > 0, "Phase not found");
        phases[_name].isOpen = _isOpen;
        emit PhaseStatusChanged(_name, _isOpen);
    }

    // controlled reserve-backed mint
    function mintWithAudit(address to, uint256 amount, string memory phaseName) external onlyOwner {
        Phase storage p = phases[phaseName];
        require(p.cap > 0, "Invalid phase");
        require(p.isOpen, "Phase closed");
        require(p.minted + amount <= p.cap, "Phase cap exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "ZiGX: total cap exceeded");
        require(totalSupply() + amount <= reserveBacking, "ZiGX: exceeds reserve backing");

        p.minted += amount;
        _mint(to, amount);

        emit MintedWithAudit(to, amount, phaseName, reserveBacking);
    }

    function getPhaseInfo(string memory name) external view returns (string memory, uint256, uint256, bool) {
        Phase memory p = phases[name];
        return (p.name, p.cap, p.minted, p.isOpen);
    }

    function getAllPhases() external view returns (string[] memory) {
        return phaseList;
    }
}
