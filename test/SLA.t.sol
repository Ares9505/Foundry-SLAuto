// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeploySLA} from "../script/DeploySLA.s.sol";
import {SLA} from "../src/SLA.sol";

contract SLATest is Test {
    SLA sla;

    //Test variables
    string private providerName;
    address private providerAddress;
    string private docHash;
    uint256 private maxlatency;
    uint256 private minthroughput;
    uint256 private maxJitter;
    uint256 private minBandWith;

    function setUp() external {
        DeploySLA deployer = new DeploySLA();
        sla = deployer.run();
    }

    function testRetrieveInfo() public {
        (
            providerName,
            providerAddress,
            docHash,
            maxlatency,
            minthroughput,
            maxJitter,
            minBandWith
        ) = sla.retrieveInfo();
        console.log("Provider name: ", providerName);
        console.log("Provider Address: ", providerAddress);
    }
}
