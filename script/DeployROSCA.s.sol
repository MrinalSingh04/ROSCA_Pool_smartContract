// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ROSCA} from "../src/ROSCA.sol";
import "forge-std/Script.sol";

contract DeployROSCA is Script {
    function run() external {
        // Start broadcasting to the chain
        vm.startBroadcast();

        // Deploy ROSCA contract without constructor args
        ROSCA rosca = new ROSCA();

        // Optionally log the deployed address
        console.log("ROSCA deployed at:", address(rosca));

        vm.stopBroadcast();
    }
}
