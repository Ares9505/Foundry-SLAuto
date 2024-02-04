// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {APIConsumer} from "../src/APIConsumer.sol";

contract DeployAPIConsumer is Script {
    APIConsumer apiConsumer;

    function run() public returns (APIConsumer) {
        vm.startBroadcast();
        apiConsumer = new APIConsumer();
        vm.stopBroadcast();
        return apiConsumer;
    }
}
