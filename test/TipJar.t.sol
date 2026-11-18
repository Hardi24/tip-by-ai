// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TipJar, IAgentID} from "../src/TipJar.sol";

/// @notice Minimal mock of the Agent ID registry: ownerOf reverts for
///         unclaimed tokenIds, exactly like the real ERC-721.
contract MockAgentID is IAgentID {
    mapping(uint256 => address) public owners;

    function mint(string calldata name, address to) external {
        owners[uint256(keccak256(bytes(name)))] = to;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        if (owner == address(0)) revert("ERC721NonexistentToken");
        return owner;
    }
}

/// @notice A recipient contract that rejects BNB (no receive/fallback).
contract RejectingRecipient {}

contract TipJarTest is Test {
    TipJar public jar;
    MockAgentID public registry;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        registry = new MockAgentID();
        registry.mint("kobong", alice);
        registry.mint("mitachuki", bob);
        jar = new TipJar(address(registry));
        vm.deal(address(this), 10 ether);
        vm.deal(alice, 0);
        vm.deal(bob, 0);
    }

    function testTipForwardsExactAmount() public {
        uint256 before = alice.balance;
        vm.expectEmit(true, true, false, true);
        emit TipJar.Tip(address(this), "kobong", alice, 0.01 ether, block.timestamp);
        jar.tip{value: 0.01 ether}("kobong");
        assertEq(alice.balance - before, 0.01 ether, "recipient must receive exact tip");
        assertEq(address(jar).balance, 0, "contract must hold no funds");
    }

    function testTipWithAiSuffix() public {
        jar.tip{value: 0.005 ether}("kobong.ai");
        assertEq(alice.balance, 0.005 ether);
    }

    function testTipUppercaseName() public {
        jar.tip{value: 0.005 ether}("KOBONG.AI");
        assertEq(alice.balance, 0.005 ether);
    }

    function testResolveView() public view {
        assertEq(jar.resolve("kobong"), alice);
        assertEq(jar.resolve("mitachuki.ai"), bob);
    }

    function testTipUnclaimedNameReverts() public {
        vm.expectRevert(abi.encodeWithSelector(TipJar.NameNotClaimed.selector, "nobodyxyz123"));
        jar.tip{value: 0.01 ether}("nobodyxyz123");
        assertEq(address(jar).balance, 0, "no funds stuck after revert");
    }

    function testTipZeroReverts() public {
        vm.expectRevert(TipJar.ZeroTip.selector);
        jar.tip{value: 0}("kobong");
    }

    function testInvalidNamesRevert() public {
        string[7] memory bad = [
            "",
            "ab",
            "abcdefghijklmnop", // 16 chars
            "ko bong",
            "kobong!",
            ".ai",
            "kobong..ai"
        ];
        for (uint256 i = 0; i < bad.length; i++) {
            vm.expectRevert();
            jar.tip{value: 0.01 ether}(bad[i]);
        }
    }

    function testRejectingRecipientReverts() public {
        address rejecter = address(new RejectingRecipient());
        registry.mint("rejecter", rejecter);
        vm.expectRevert(
            abi.encodeWithSelector(TipJar.TransferFailed.selector, rejecter, 0.01 ether)
        );
        jar.tip{value: 0.01 ether}("rejecter");
        assertEq(address(jar).balance, 0, "no funds stuck after failed transfer");
    }

    function testNoFundsRetainedAfterManyTips() public {
        jar.tip{value: 0.01 ether}("kobong");
        jar.tip{value: 0.02 ether}("mitachuki");
        jar.tip{value: 0.003 ether}("KOBONG.AI");
        assertEq(address(jar).balance, 0);
        assertEq(alice.balance, 0.013 ether);
        assertEq(bob.balance, 0.02 ether);
    }

    function testPlainTransferReverts() public {
        (bool ok, ) = address(jar).call{value: 0.01 ether}("");
        assertFalse(ok, "plain BNB transfer must revert (no receive)");
        assertEq(address(jar).balance, 0);
    }

    receive() external payable {}
}
