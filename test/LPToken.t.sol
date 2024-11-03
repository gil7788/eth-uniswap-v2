// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LPToken.sol";

contract LPTokenTest is Test {
    LPToken public token;
    address public owner;
    address public user1;
    address public user2;
    uint256 public initialSupply;
    uint256 public user1InitialBalance;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        initialSupply = 1_000_000 * 10 ** 18; // 1 million tokens with 18 decimals
        user1InitialBalance = 100_000 * 10 ** 18; // user1 receives 100,000 tokens

        token = new LPToken("LPToken", "LPT", initialSupply);

        // Transfer initial balance to user1
        token.transfer(user1, user1InitialBalance);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), initialSupply, "Total supply should match initial supply");
        assertEq(
            token.balanceOf(owner),
            initialSupply - user1InitialBalance,
            "Owner should hold the initial supply minus user1's initial balance"
        );
        assertEq(token.balanceOf(user1), user1InitialBalance, "User1 should hold the initial transferred balance");
    }

    function testNameAndSymbol() public {
        assertEq(token.name(), "LPToken", "Token name should be LPToken");
        assertEq(token.symbol(), "LPT", "Token symbol should be LPT");
        assertEq(token.decimals(), 18, "Token decimals should be 18");
    }

    function testTransfer() public {
        uint256 transferAmount = 10_000 * 10 ** 18;

        vm.prank(user1);
        token.transfer(user2, transferAmount);
        assertEq(token.balanceOf(user2), transferAmount, "User2 should receive the transfer amount");
        assertEq(
            token.balanceOf(user1), user1InitialBalance - transferAmount, "User1 balance should decrease accordingly"
        );
    }

    function testTransferFailInsufficientBalance() public {
        uint256 transferAmount = user1InitialBalance + 1;

        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, transferAmount);
    }

    function testTransferFromFailWithoutAllowance() public {
        uint256 transferAmount = 50 * 10 ** 18;

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(owner, user2, transferAmount);
    }

    function testApproveAndAllowance() public {
        uint256 approveAmount = 200 * 10 ** 18;
        token.approve(user1, approveAmount);
        assertEq(token.allowance(owner, user1), approveAmount, "Allowance should match approved amount");
    }

    function testTransferFromWithAllowance() public {
        uint256 approveAmount = 300 * 10 ** 18;
        uint256 transferAmount = 150 * 10 ** 18;

        token.approve(user1, approveAmount);
        vm.prank(user1); // user1 will call the function
        token.transferFrom(owner, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount, "User2 should receive the transfer amount");
        assertEq(
            token.balanceOf(owner),
            initialSupply - user1InitialBalance - transferAmount,
            "Owner balance should decrease"
        );
        assertEq(
            token.allowance(owner, user1),
            approveAmount - transferAmount,
            "Allowance should decrease by transfer amount"
        );
    }

    function testApproveMaxAllowance() public {
        uint256 maxAllowance = type(uint256).max;
        token.approve(user1, maxAllowance);

        assertEq(token.allowance(owner, user1), maxAllowance, "Allowance should be set to max");

        // Test transferFrom with max allowance
        uint256 transferAmount = 500 * 10 ** 18;
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount, "User2 should receive the transfer amount");
        assertEq(
            token.balanceOf(owner),
            initialSupply - user1InitialBalance - transferAmount,
            "Owner balance should decrease"
        );
        assertEq(token.allowance(owner, user1), maxAllowance, "Allowance should remain unchanged for max allowance");
    }
}
