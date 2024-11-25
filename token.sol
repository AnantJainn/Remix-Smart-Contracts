// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Test is ERC20 {

    constructor(uint _initialSupply) ERC20("Test Token", "Test") {
        _mint(msg.sender, _initialSupply * 10**decimals());
    }
}
