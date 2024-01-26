//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SLA} from "../src/SLA.sol";

contract DeploySLA is Script {
    SLA sla;

    function run() public returns (SLA) {
        vm.startBroadcast();
        sla = new SLA(
            "Telnor",
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Dirección Ethereum de ejemplo
            "0xabcdef1234567890", // Hash de documento de ejemplo
            10, // Latencia máxima
            10, // Throughput mínimo
            10, // Jitter máximo
            10, // Ancho de banda mínimo
            "https://api.example.com" // Endpoint de ejemplo
        );
        vm.stopBroadcast();
        return sla;
    }
}
