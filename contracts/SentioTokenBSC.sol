// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Sentio Token Contract on BSC
/// @notice Implements an ERC20 OFT token with a time-locked transfer and whitelist feature.
contract SentioTokenOnBSC is OFT, ERC20Permit, ERC20Burnable {
    // Timestamp after which transfers are allowed for non-whitelisted users
    uint256 public transferAllowedTimestamp;
    uint256 internal ETA;

    mapping(address => bool) private _isWhitelisted;

    event NewTransferAllowedTimestamp(uint256 newTimestamp);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    constructor(
        address _lzEndpoint,
        address _delegate,
        address _tokenOwner,
        uint256 totalSupply,
        uint256 transferAllowedTimestamp_
    ) OFT("Sentio Token", "ST", _lzEndpoint, _delegate) ERC20Permit("Sentio Token") Ownable(_delegate) {
        require(transferAllowedTimestamp_ >= block.timestamp, "Incorrect timestamp");
        transferAllowedTimestamp = transferAllowedTimestamp_;
        _isWhitelisted[_tokenOwner] = true;
        _mint(_tokenOwner, totalSupply);
    }

    /// @notice Set the new timestamp after which transfers will be allowed for non-whitelisted addresses.
    /// @param newTimestamp The new timestamp.
    function setTransferAllowedTimestamp(uint256 newTimestamp) external onlyOwner {
        if (transferAllowedTimestamp > block.timestamp && ETA == 0) {
            transferAllowedTimestamp = newTimestamp;
        } else {
            if (ETA == 0) {
                ETA = transferAllowedTimestamp + 1 days;
            }
            require(newTimestamp <= ETA, "The timestamp exceeds the ETA");
            transferAllowedTimestamp = newTimestamp;
        }

        emit NewTransferAllowedTimestamp(newTimestamp);
    }

    /// @notice Returns true if the account is whitelisted.
    /// @param account The address to check.
    function isWhitelisted(address account) external view returns (bool) {
        return _isWhitelisted[account];
    }

    /// @notice Adds an address to the whitelist.
    /// @param account The address to add to the whitelist.
    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(!_isWhitelisted[account], "Already whitelisted");
        _isWhitelisted[account] = true;
        emit WhitelistAdded(account);
    }

    /// @notice Removes an address from the whitelist.
    /// @param account The address to remove from the whitelist.
    function removeFromWhitelist(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(_isWhitelisted[account], "Not whitelisted");
        _isWhitelisted[account] = false;
        emit WhitelistRemoved(account);
    }

    /// @notice Overrides the _update function to enforce time lock and whitelist.
    /// @param from The address from which tokens are being transferred.
    /// @param to The address to which tokens are being transferred.
    /// @param amount The amount of tokens being transferred.
    function _update(address from, address to, uint256 amount) internal override {
        if (block.timestamp < transferAllowedTimestamp) {
            // Allow mint: from = address(0) skips whitelist check
            // burn is still restricted - requires whitelist
            if (from != address(0)) {
                require(_isWhitelisted[from], "Not allowed");
            }
        }

        super._update(from, to, amount);
    }
}
