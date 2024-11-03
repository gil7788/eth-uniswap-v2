// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    constructor(string memory tokenName, string memory tokenSymbol, uint256 initialSupply)
        ERC20(tokenName, tokenSymbol)
    {
        _mint(msg.sender, initialSupply);
    }
}
