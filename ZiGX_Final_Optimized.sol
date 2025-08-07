
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZiGX is ERC20, Ownable {
    uint8 private constant CUSTOM_DECIMALS = 6;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**6; // 100M ZiGX with 6 decimals
    event Minted(address indexed to, uint256 amount);

    constructor() ERC20("ZiGX", "ZiGX") {}

    function decimals() public view virtual override returns (uint8) {
        return CUSTOM_DECIMALS;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "ZiGX: cap exceeded");
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
