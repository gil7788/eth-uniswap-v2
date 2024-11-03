// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/Factory.sol";
import "src/Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}

contract TestFactory is Test {
    Factory factory;
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockERC20 tokenC;

    function setUp() public {
        factory = new Factory();
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");
        tokenC = new MockERC20("TokenC", "TKC");
    }

    function testCreatePair() public {
        factory.createPair(address(tokenA), address(tokenB));
        Pair pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(address(pair) != address(0), "Pair should be created");
        assertEq(pair.name(), "uniswap-TKA/TKB", "Name should be correct");
        assertEq(pair.symbol(), "LTP-TKA/TKB", "Symbol should be correct");
    }

    function testAddExistingPair() public {
        factory.createPair(address(tokenA), address(tokenB));
        Pair pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(address(pair) != address(0), "Pair should be created");
        assertEq(pair.name(), "uniswap-TKA/TKB", "Name should be correct");
        assertEq(pair.symbol(), "LTP-TKA/TKB", "Symbol should be correct");

        vm.expectRevert("Pair Already Exists");
        factory.createPair(address(tokenA), address(tokenB));
    }

    function testAddSymetricExistingPair() public {
        factory.createPair(address(tokenA), address(tokenB));
        Pair pair = factory.getPair(address(tokenA), address(tokenB));

        assertTrue(address(pair) != address(0), "Pair should be created");
        assertEq(pair.name(), "uniswap-TKA/TKB", "Name should be correct");
        assertEq(pair.symbol(), "LTP-TKA/TKB", "Symbol should be correct");

        vm.expectRevert("Pair Already Exists");
        factory.createPair(address(tokenB), address(tokenA));
    }

    function testSameTokenPair() public {
        // Attempting to create a pair with the same token should revert
        vm.expectRevert("Invalid Tokens, token0 and token1 Must be Different");
        factory.createPair(address(tokenA), address(tokenA));
    }

    function testZeroAddress() public {
        vm.expectRevert("Invalid Zero Address");
        factory.createPair(address(0), address(tokenB));
    }
}
