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
        market = new Market(marketCreator);
        vm.stopBroadcast();
        return market;
    }
}
