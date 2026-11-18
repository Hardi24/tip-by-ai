// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

/// @notice Fork test against BSC MAINNET and the REAL Agent ID contract.
///         Run with: forge test --match-contract TipJarForkTest
///                   --fork-url https://bsc.publicnode.com
///         Nothing here moves real funds: the fork is local state only.
///         "kobong" is really owned by 0x3d39bbD8ad419dbe7165f44673DA74c032c0A41B.
contract TipJarForkTest is Test {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address constant KOBONG_OWNER = 0x3d39bbD8ad419dbe7165f44673DA74c032c0A41B;

    TipJar public jar;

    function setUp() public {
        jar = new TipJar(AGENT_ID);
    }

    function testResolveRealKobong() public view {
        assertEq(jar.resolve("kobong"), KOBONG_OWNER);
        assertEq(jar.resolve("kobong.ai"), KOBONG_OWNER);
        assertEq(jar.resolve("KOBONG.AI"), KOBONG_OWNER);
    }

    function testTipRealKobongOnFork() public {
        address tipper = address(0x71A2);
        vm.deal(tipper, 1 ether);
        uint256 before = KOBONG_OWNER.balance;
        vm.prank(tipper);
        jar.tip{value: 0.001 ether}("kobong");
        assertEq(KOBONG_OWNER.balance - before, 0.001 ether);
        assertEq(address(jar).balance, 0);
    }

    function testTipUnclaimedRealNameReverts() public {
        vm.expectRevert();
        jar.tip{value: 0.001 ether}("namabelumdiklaimxyz123");
    }
}
