//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Example} from "../src/ContractTest.sol";

contract DeployContractTest is Script {
    Example example;

    function run() public returns (Example) {
        vm.startBroadcast();
        example = new Example();
        vm.stopBroadcast();
        return example;
    }
}
