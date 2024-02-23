//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SLA} from "../src/SLA.sol";

contract DeploySLA is Script {
    SLA sla;

    function run() public returns (SLA) {
        vm.startBroadcast();
        uint256[22] memory params = [
            uint256(3),
            uint256(7),
            uint256(12),
            uint256(18),
            uint256(22),
            uint256(35),
            uint256(41),
            uint256(56),
            uint256(63),
            uint256(77),
            uint256(82),
            uint256(94),
            uint256(105),
            uint256(112),
            uint256(126),
            uint256(133),
            uint256(147),
            uint256(150),
            uint256(126),
            uint256(133),
            uint256(147),
            uint256(150)
        ];
        sla = new SLA(
            "Telnor",
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Dirección Ethereum de ejemplo
            "0xabcdef1234567890", // Hash de documento de ejemplo
            params,
            "https://api.example.com" // Endpoint de ejemplo
        );
        vm.stopBroadcast();
        return sla;
    }
}
