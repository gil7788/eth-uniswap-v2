// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Factory {
    mapping(address => mapping(address => address)) private _pairs;

    function getPair(
        address token0,
        address token1
    ) external view returns (Pair) {
        Pair pair = Pair(_pairs[token0][token1]);
        require(address(pair) != address(0), "Pair does not exist");
        return pair;
    }

    function createPair(address token0, address token1) external {
        require(
            token0 != token1,
            "Invalid Tokens, token0 and token1 Must be Different"
        );

        require(
            token0 != address(0) && token1 != address(0),
            "Invalid Zero Address"
        );
        require(_pairs[token0][token1] == address(0), "Pair Already Exists");
        ERC20 _token0 = ERC20(token0);
        ERC20 _token1 = ERC20(token1);

        string memory token0Symb = _token0.symbol();
        string memory token1Symb = _token1.symbol();

        string memory tokenName = string(
            abi.encodePacked("uniswap-", token0Symb, "/", token1Symb)
        );
        string memory tokenSymbol = string(
            abi.encodePacked("LTP-", token0Symb, "/", token1Symb)
        );

        Pair pair = new Pair(tokenName, tokenSymbol, _token0, _token1);
        _pairs[token0][token1] = address(pair);
        _pairs[token1][token0] = address(pair);
    }
}
