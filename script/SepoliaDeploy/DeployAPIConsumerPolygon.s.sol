// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {APIConsumerPolygon} from "../../src/APIConsumerPolygon.sol";

contract DeployAPIConsumerPolygon is Script {
    APIConsumerPolygon apiConsumerPolygon;

    function run() public returns (APIConsumerPolygon) {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployer);
        apiConsumerPolygon = new APIConsumerPolygon();
        vm.stopBroadcast();
        return apiConsumerPolygon;
    }
}

//forge script script/SepoliaDeploy/DeployAPIConsumerPolygon.s.sol --rpc-url $POLYGON_RPC_URL --broadcast -vvvv
