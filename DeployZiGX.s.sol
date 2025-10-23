// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ZiGX} from "src/ZiGX_Advanced_MainnetFinal.sol";

contract DeployZiGX is Script {
    function run() public returns (ZiGX) {
        vm.startBroadcast();
        ZiGX zigx = new ZiGX();
        vm.stopBroadcast();

        return (zigx);
    }
}
