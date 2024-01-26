//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {APIConsumer} from "../src/APIConsumer.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract FundAPIConsumer is Script {
    function fundAPIConsumer(address apiConsumerAddress) public view {
        //Send money to contract
        if (block.chainid == 31337) {
            console.log("Something");
            console.log("Consumer API Address:", apiConsumerAddress);
        } else {
            return;
            // vm.startBroadcast();
            // LinkToken(link).transferAndCall(
            //     /**address */,
            //     /**Amount to fund */,
            //     /*abi.encode(subId)*/
            // );
            // vm.stopBroadcast();
        }
    }

    function fundAPIConsumerUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address apiConsumerAddress = helperConfig.activeNetworkConfig();
        fundAPIConsumer(apiConsumerAddress);
    }

    function run() external {
        fundAPIConsumerUsingConfig();
    }
}

/**
 * Interactions:
 * FundAPIConsumer with links (Add link token mock, instalar solmate para poder importar ERC20)
 * Aañdir mi llave privada
 */
