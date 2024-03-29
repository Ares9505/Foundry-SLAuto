// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Market} from "../src/Market.sol";

contract DeployMarket is Script {
    Market market;
    string marketCreator;

    function run() public returns (Market) {
        marketCreator = "totalPlay";
        vm.startBroadcast();
        uint256 start = vm.unixTime();
        market = new Market(marketCreator);
        vm.stopBroadcast();
        uint256 end = vm.unixTime();
        uint256 deploymentTime = end - start;
        console.log("deploymentTime: ", deploymentTime);
        return market;
    }
}
