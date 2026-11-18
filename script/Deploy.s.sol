// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {TipJar} from "../src/TipJar.sol";

/// @notice Deploy TipJar.
///         Usage (BSC testnet):
///           forge script script/Deploy.s.sol --rpc-url <testnet-rpc> \
///             --private-key <deployer-key> --broadcast
///         The Agent ID registry address is read from env AGENT_ID, or
///         defaults to the real mainnet contract. On BSC testnet there is
///         no Agent ID registry, so deploy MockAgentID first (see
///         script/DeployTestnet.s.sol) and pass its address as AGENT_ID.
contract Deploy is Script {
    function run() external returns (TipJar) {
        address agentId = vm.envOr("AGENT_ID", address(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F));
        vm.startBroadcast();
        TipJar jar = new TipJar(agentId);
        vm.stopBroadcast();
        console.log("TipJar deployed at:", address(jar));
        console.log("Agent ID registry:", agentId);
        return jar;
    }
}
