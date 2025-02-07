// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LendingPool.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        new LendingPool();
        vm.stopBroadcast();
    }
}
