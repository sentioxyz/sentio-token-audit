// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Sentio Token Contract
/// @notice Implements an ERC20 token with a cap, pausability, ownership, and a whitelist feature.
contract SentioTokenOnBSC is OFT, ERC20Permit, Pausable, AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public immutable cap;

    uint256 public totalMinted;

    mapping(address => bool) private _isWhitelisted;

    event WhitelistUpdated(address indexed account, bool isWhitelisted);

    constructor(
        address _lzEndpoint,
        address _delegate,
        uint256 _cap,
        address admin,
        address pauser
    ) OFT("Sentio Token", "ST", _lzEndpoint, _delegate) ERC20Permit("Sentio Token") Ownable(_delegate) {
        require(_cap > 0, "cap must be greater than 0");
        cap = _cap;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _pause();
    }

    /// @notice Allows the pause controller address to pause all token transfers for non-whitelisted addresses.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Allows the pause controller address to unpause the token transfers.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Allows the minter to mint new tokens, up to the cap. The cap only applies to minting who has the MINTER_ROLE, not to OFT minting.
    /// the OTF burns tokens on the source chain and mints them on the destination chain, this is by design.  
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalMinted + amount <= cap, "cap exceeded");
        totalMinted += amount;
        _mint(to, amount);
    }

    /// @notice Returns true if the account is whitelisted.
    /// @param account The address to check.
    function isWhitelisted(address account) external view returns (bool) {
        return _isWhitelisted[account];
    }

    /// @notice Adds an address to the whitelist.
    /// @param account The address to add to the whitelist.
    function addToWhitelist(address account) external onlyRole(PAUSER_ROLE) {
        require(account != address(0), "cannot whitelist the zero address");
        _isWhitelisted[account] = true;
        emit WhitelistUpdated(account, true);
    }

    /// @notice Removes an address from the whitelist.
    /// @param account The address to remove from the whitelist.
    function removeFromWhitelist(address account) external onlyRole(PAUSER_ROLE) {
        require(account != address(0), "cannot un-whitelist the zero address");
        _isWhitelisted[account] = false;
        emit WhitelistUpdated(account, false);
    }

    /// @notice Overrides the _update function to enforce the whitelist and pause functionality.
    /// @param from The address from which tokens are being transferred.
    /// @param to The address to which tokens are being transferred.
    /// @param amount The amount of tokens being transferred.
    function _update(address from, address to, uint256 amount) internal override {
        if (paused()) {
            require(from == address(0) || (_isWhitelisted[from] && _isWhitelisted[to]), "paused and not whitelisted");
        }

        super._update(from, to, amount);
    }
}
