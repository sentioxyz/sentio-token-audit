// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Sentio Token Lock Contract
 * @notice Stores ST tokens and allows:
 *         - Minter (IDO Contract) to mint (distribute) tokens to users
 *         - Owner (Multisig) to rescue leftover tokens after releaseTime
 */
contract SentioTokenLock is Ownable {
    using SafeERC20 for IERC20Metadata;

    /// @notice The Sentio Token (ST)
    IERC20Metadata public immutable ST;

    /// @notice Address allowed to mint tokens (the IDO Contract)
    address public minter;

    /// @notice Timestamp after which the owner can rescue leftover ST
    uint256 public immutable releaseTime;

    /// Events
    event MinterUpdated(address indexed newMinter);
    event Minted(address indexed to, uint256 amount);
    event Rescued(address indexed to, uint256 amount);

    /**
     * @param st_ Address of the ST token
     * @param owner_ Multisig owner
     * @param delayHours Hours after which owner can rescue leftover ST
     */
    constructor(address st_, address owner_, uint256 delayHours)
        Ownable(owner_)
    {
        require(st_ != address(0), "ST address zero");
        require(owner_ != address(0), "Owner address zero");

        ST = IERC20Metadata(st_);
        releaseTime = block.timestamp + (delayHours * 1 hours);
    }

    // -------------------------------------------------------------------------
    //  Minter Logic
    // -------------------------------------------------------------------------

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    /**
     * @notice Set the IDO contract as the minter
     * @dev Only Owner (multisig) can set this
     */
    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Minter zero");
        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    // -------------------------------------------------------------------------
    //  Mint (Distribution)
    // -------------------------------------------------------------------------

    /**
     * @notice Mint (distribute) tokens to a user
     * @dev Called only by the IDO contract
     */
    function mint(address to, uint256 amount) external onlyMinter {
        require(to != address(0), "Recipient zero address");
        require(amount > 0, "Amount > 0");
        require(balanceOf(address(this)) >= amount, "Insufficient balance");

        ST.safeTransfer(to, amount);
        emit Minted(to, amount);
    }

    // -------------------------------------------------------------------------
    //  Rescue Logic
    // -------------------------------------------------------------------------

    /**
     * @notice Owner (multisig) rescues leftover tokens after releaseTime
     */
    function rescue(address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= releaseTime, "Time lock active");
        require(to != address(0), "Recipient zero address");
        require(amount > 0, "Amount > 0");
        require(balanceOf(address(this)) >= amount, "Not enough balance");

        ST.safeTransfer(to, amount);
        emit Rescued(to, amount);
    }

    // -------------------------------------------------------------------------
    //  Public View Helpers
    // -------------------------------------------------------------------------

    function name() external view returns (string memory) {
        return ST.name();
    }

    function symbol() external view returns (string memory) {
        return ST.symbol();
    }

    function decimals() external view returns (uint8) {
        return ST.decimals();
    }

    function balanceOf(address account) public view returns (uint256) {
        return ST.balanceOf(account);
    }
}
