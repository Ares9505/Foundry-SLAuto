// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Market} from "../../src/Market.sol";

contract DeployMarketSepolia is Script {
    Market market;
    string marketCreator;

    function run() public returns (Market) {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        marketCreator = "totalPlay";
        vm.startBroadcast(deployer);
        market = new Market(marketCreator);
        vm.stopBroadcast();
        return market;
    }

    /** forge script script/DeployMarketSepolia.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
     * Se deplego pero no se verifico el contrato
     */
}
