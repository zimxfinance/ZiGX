// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol";

/// @title ZIMX Token
/// @notice Fixed-supply ERC20 token with ownership and updatable treasury and vesting hooks.
contract ZIMX is ERC20, Ownable {
    /// @notice Address that receives protocol treasury funds.
    address public treasuryWallet;

    /// @notice Address of the vesting contract.
    address public vestingContract;

    /// @notice Emitted when the treasury wallet address is updated.
    /// @param oldWallet Previous treasury wallet address.
    /// @param newWallet New treasury wallet address.
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);

    /// @notice Emitted when the vesting contract address is updated.
    /// @param oldContract Previous vesting contract address.
    /// @param newContract New vesting contract address.
    event VestingContractUpdated(address indexed oldContract, address indexed newContract);

    /// @notice Total supply of ZIMX tokens (1 billion tokens).
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    /// @notice Deploys the ZIMX token contract.
    /// @param initialOwner Address that will own the contract and receive the total supply.
    /// @param initialTreasuryWallet Initial treasury wallet address.
    constructor(address initialOwner, address initialTreasuryWallet)
        ERC20("ZIMX Token", "ZIMX")
        Ownable(initialOwner)
    {
        require(initialOwner != address(0), "Invalid initial owner address");
        require(initialTreasuryWallet != address(0), "Invalid treasury wallet address");

        _mint(initialOwner, TOTAL_SUPPLY);
        treasuryWallet = initialTreasuryWallet;
    }

    /// @notice Updates the treasury wallet address.
    /// @param newTreasury New treasury wallet address.
    function updateTreasuryWallet(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        address oldWallet = treasuryWallet;
        treasuryWallet = newTreasury;
        emit TreasuryWalletUpdated(oldWallet, newTreasury);
    }

    /// @notice Sets the vesting contract address.
    /// @param newVesting New vesting contract address.
    function setVestingContract(address newVesting) external onlyOwner {
        require(newVesting != address(0), "Invalid address");
        address oldContract = vestingContract;
        vestingContract = newVesting;
        emit VestingContractUpdated(oldContract, newVesting);
    }
}

