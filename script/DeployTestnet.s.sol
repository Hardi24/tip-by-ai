// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {TipJar} from "../src/TipJar.sol";
import {MockAgentID} from "../src/MockAgentID.sol";

/// @notice BSC TESTNET deployment (chain 97). Deploys a MockAgentID registry
///         (the real Agent ID contract is mainnet-only), mints a few demo
///         names to the deployer, then deploys TipJar pointing at the mock.
///         Usage:
///           forge script script/DeployTestnet.s.sol --rpc-url <testnet-rpc> \
///             --private-key <deployer-key> --broadcast
///         The deployer key is a throwaway testnet-only key; never reuse it
///         on mainnet and never commit it.
contract DeployTestnet is Script {
    function run() external returns (MockAgentID, TipJar) {
        vm.startBroadcast();
        MockAgentID registry = new MockAgentID();
        // Demo names owned by the deployer (change as needed).
        registry.mint("kobong", msg.sender);
        registry.mint("tipjar", msg.sender);
        registry.mint("demo", msg.sender);
        TipJar jar = new TipJar(address(registry));
        vm.stopBroadcast();
        console.log("MockAgentID deployed at:", address(registry));
        console.log("TipJar deployed at:     ", address(jar));
        console.log("Demo names (kobong, tipjar, demo) owned by deployer:", msg.sender);
        return (registry, jar);
    }
}
