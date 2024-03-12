//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Example} from "../src/ContractTest.sol";

contract DeployContractTest is Script {
    Example example;

    function run() public returns (Example) {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployer);
        example = new Example("TheRock");
        vm.stopBroadcast();
        return example;
    }
}

//forge script script/DeployContractTest.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
