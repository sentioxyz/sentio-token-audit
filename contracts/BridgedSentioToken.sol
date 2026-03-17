// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {
    IOptimismMintableERC20,
    ILegacyMintableERC20
} from "@eth-optimism/contracts-bedrock/src/universal/IOptimismMintableERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title BridgedSentioToken
 * @notice ERC20 token deployed on L2 chains, compatible with Optimism Standard Bridge.
 * @dev Implements IOptimismMintableERC20 for bridge compatibility.
 *      Tokens can be minted/burned by the Optimism Standard Bridge.
 */
contract BridgedSentioToken is ERC20, Ownable, ERC20Permit, ERC165, IOptimismMintableERC20, ILegacyMintableERC20, ERC20Burnable {
    /// @notice Address of the corresponding token on the remote chain (L1).
    address public immutable REMOTE_TOKEN;

    /// @notice Address of the Optimism Standard Bridge on this chain.
    address public immutable BRIDGE;

    /// @notice Emitted when tokens are minted by the bridge.
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted when tokens are burned by the bridge.
    event Burn(address indexed account, uint256 amount);

    /// @notice Error thrown when caller is not the bridge.
    error OnlyBridge();

    /// @notice Modifier to restrict access to bridge only.
    modifier onlyBridge() {
        if (msg.sender != BRIDGE) revert OnlyBridge();
        _;
    }

    constructor(
        address _remoteToken,
        address _bridge
    ) ERC20("Sentio Token", "ST") ERC20Permit("Sentio Token") Ownable(msg.sender) {
        REMOTE_TOKEN = _remoteToken;
        BRIDGE = _bridge;
    }

    /// @inheritdoc IOptimismMintableERC20
    function remoteToken() external view override returns (address) {
        return REMOTE_TOKEN;
    }

    /// @inheritdoc IOptimismMintableERC20
    function bridge() external view override returns (address) {
        return BRIDGE;
    }

    /// @inheritdoc ILegacyMintableERC20
    function l1Token() external view override returns (address) {
        return REMOTE_TOKEN;
    }

    /// @inheritdoc IOptimismMintableERC20
    function mint(
        address _to,
        uint256 _amount
    ) external override(IOptimismMintableERC20, ILegacyMintableERC20) onlyBridge {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /// @inheritdoc IOptimismMintableERC20
    function burn(
        address _from,
        uint256 _amount
    ) external override(IOptimismMintableERC20, ILegacyMintableERC20) onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            _interfaceId == type(IOptimismMintableERC20).interfaceId ||
            _interfaceId == type(ILegacyMintableERC20).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}
