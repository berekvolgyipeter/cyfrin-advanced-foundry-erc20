// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    OurToken public ourToken;
    DeployOurToken public deployer;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCanNotMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    /* ---------- approval & allowance ---------- */
    function testAllowance() public {
        uint256 amount = 1000;

        vm.prank(msg.sender);
        ourToken.approve(bob, amount);

        assertEq(ourToken.allowance(msg.sender, bob), amount);
    }

    function testFailApproveExceedsBalance() public {
        uint256 amount = STARTING_BALANCE + 1;

        vm.expectRevert();
        vm.prank(bob);
        ourToken.approve(alice, amount);
    }

    function testApprovalEvent() public {
        uint256 amount = 1000;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, amount);
        ourToken.approve(alice, amount);
    }

    /* ---------- transfer ---------- */
    function testTransfer() public {
        uint256 amount = 1000;

        vm.prank(bob);
        ourToken.transfer(alice, amount);

        assertEq(ourToken.balanceOf(alice), amount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - amount);
    }

    function testTransferFrom() public {
        uint256 initialAllowance = 1000;
        uint256 transferAmount = 500;

        // Bob approves Alice to spend 1000 tokens.
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testFailTransferExceedsBalance() public {
        uint256 amount = STARTING_BALANCE + 1;

        vm.prank(bob);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        ourToken.transfer(alice, amount);
    }

    function testTransferEvent() public {
        uint256 amount = 1000;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, amount);
        ourToken.transfer(alice, amount);
    }
}
