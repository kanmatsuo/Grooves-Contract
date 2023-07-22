// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Library.sol";

contract GroovesCoin is ERC20 {
    constructor() ERC20("GroovesCoin", "GRVC") {
        _mint(msg.sender, 2000000000 * 10 ** decimals());
    }
}