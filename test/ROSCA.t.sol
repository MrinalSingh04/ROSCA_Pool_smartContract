// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/ROSCA.sol";

contract ROSCATest is Test {
    ROSCA rosco;

    address alice = address(0x1);
    address bob = address(0x2);
    address eve = address(0x3);

    function setUp() public {
        rosco = new ROSCA();
    }

    function testFullCycle() public {
        uint256 poolId = rosco.createPool(1 ether, 1 days);

        // Members join pool
        vm.prank(alice);
        rosco.joinPool(poolId);

        vm.prank(bob);
        rosco.joinPool(poolId);

        vm.prank(eve);
        rosco.joinPool(poolId);

        rosco.startPool(poolId);

        // Fund test addresses so they can send ETH
        vm.deal(alice, 5 ether);
        vm.deal(bob, 5 ether);
        vm.deal(eve, 5 ether);

        // Contributions by members
        vm.prank(alice);
        rosco.contribute{value: 1 ether}(poolId);

        vm.prank(bob);
        rosco.contribute{value: 1 ether}(poolId);

        vm.prank(eve);
        rosco.contribute{value: 1 ether}(poolId);

        // Move forward in time beyond round duration
        vm.warp(block.timestamp + 1 days + 1 seconds);

        // Execute round and pay recipient
        rosco.executeRound(poolId);
    }
}
