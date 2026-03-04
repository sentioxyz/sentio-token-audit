// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SentioToken is OFT, ERC20Permit {
    constructor(
        address _lzEndpoint,
        address _delegate
    ) OFT("Sentio Token", "ST", _lzEndpoint, _delegate) ERC20Permit("Sentio Token") Ownable(_delegate) {}
}
