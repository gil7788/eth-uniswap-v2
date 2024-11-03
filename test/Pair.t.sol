// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialAmount
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialAmount);
    }
}

contract TestPair is Test {
    Pair private pair;
    MockERC20 token1;
    MockERC20 token2;
    address private owner;
    uint256 initialLiquidity;
    uint8 decimals = 18;

    function setUp() public {
        owner = address(this);
        uint256 token1Amount = 1000 * 10 ** decimals;
        uint256 token2Amount = 1000 * 10 ** decimals;
        token1 = new MockERC20("Token1", "TK1", token1Amount);
        token2 = new MockERC20("Token2", "TK2", token2Amount);
        pair = new Pair("TEST-LPT", "TLPT", token1, token2);

        // Approve Pair contract to transfer tokens on behalf of the owner
        token1.approve(address(pair), type(uint256).max);
        token2.approve(address(pair), type(uint256).max);

        // Transfer initial liquidity to the pair contract
        token1.transfer(address(pair), 500 * 10 ** decimals);
        token2.transfer(address(pair), 500 * 10 ** decimals);
        initialLiquidity =
            token1.balanceOf(address(pair)) *
            token2.balanceOf(address(pair));
    }

    function testProvideInitLiquidity() public {
        uint256 token1Amount = 100 * 10 ** decimals;
        uint256 token2Amount = 100 * 10 ** decimals;

        // Provide initial liquidity
        pair.provideInitLiqudity(token1Amount, token2Amount);

        // Check pair contract's balance for token1 and token2
        assertEq(token1.balanceOf(address(pair)), 600 * 10 ** decimals);
        assertEq(token2.balanceOf(address(pair)), 600 * 10 ** decimals);
    }

    function testSwapToken1ToToken2() public {
        uint256 amountToSwap = 10 * 10 ** decimals;

        // Perform swap: token1 -> token2
        pair.swap(address(token1), address(token2), amountToSwap);

        // Check balances after swap
        assertEq(token1.balanceOf(owner), 490 * 10 ** decimals); // 1000 - 10
        assertTrue(token2.balanceOf(owner) > 0); // Received some token2
        uint256 liquidity = token1.balanceOf(address(pair)) *
            token2.balanceOf(address(pair));
        assertGe(liquidity, initialLiquidity);
    }

    function testSwapToken2ToToken1() public {
        uint256 amountToSwap = 10 * 10 ** decimals;

        // Perform swap: token2 -> token1
        pair.swap(address(token2), address(token1), amountToSwap);

        // Check balances after swap
        assertEq(token2.balanceOf(owner), 490 * 10 ** decimals); // 1000 - 10
        assertTrue(token1.balanceOf(owner) > 0); // Received some token1
        uint256 liquidity = token1.balanceOf(address(pair)) *
            token2.balanceOf(address(pair));
        assertGe(liquidity, initialLiquidity);
    }

    function testAddLiquidityToken1() public {
        uint256 token1Amount = 50 * 10 ** decimals;
        pair.addLiquidity(address(token1), token1Amount);
        // Check pair contract's token1 balance
        assertEq(token1.balanceOf(address(pair)), 550 * 10 ** decimals);
    }

    function testAddLiquidityToken2() public {
        uint256 token2Amount = 50 * 10 ** decimals;
        pair.addLiquidity(address(token2), token2Amount);
        // Check pair contract's token2 balance
        assertEq(token2.balanceOf(address(pair)), 550 * 10 ** decimals);
    }

    function testFailSwapInvalidTokenPair() public {
        uint256 amountToSwap = 10 * 10 ** decimals;
        pair.swap(address(0), address(token1), amountToSwap);
    }

    function testFailAddLiquidityZeroToken() public {
        uint256 amountToAdd = 50 * 10 ** decimals;
        pair.addLiquidity(address(0), amountToAdd);
    }

    /* ceilDiv */
    function testCeilDivZeroNominator() public {
        uint256 result = pair.ceilDiv(0, 100);
        assertEq(result, 0);
    }

    function testCeilDivByZero() public {
        vm.expectRevert("Invalid division by 0");
        pair.ceilDiv(100, 0);
    }

    function testCeilDivOne() public {
        uint256 result = pair.ceilDiv(1, 100);
        assertTrue(result == 1);
    }

    function testCeilDiv() public {
        uint256 result = pair.ceilDiv(455, 100);
        assertTrue(result == 5);
    }
}
