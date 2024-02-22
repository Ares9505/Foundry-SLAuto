// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployAPIConsumer} from "../script/DeployAPIConsumer.s.sol";
import {APIConsumer} from "../src/APIConsumer.sol";

contract APIConsumerTest is Test {
    APIConsumer public apiConsumer;

    address public CHAINLINK_AUTOMATION_ADDRESS =
        makeAddr("Chainlink Automation");
    address public CHAINLINK_ORACLE_ADDRESS =
        0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD; //Extracted from APIConsumerContract

    function setUp() external {
        DeployAPIConsumer deployer = new DeployAPIConsumer();
        apiConsumer = deployer.run();
    }

    function testRequestVolume() public {
        vm.prank(CHAINLINK_AUTOMATION_ADDRESS);
        //Request Volume Data to Chainlink Oracle
        //Comented line 145 to evit transferAndCall Revert, Link transfer is not needed in test
        bytes32 request_id = apiConsumer.requestVolumeData();
        string memory dummyVolume = "dummyString";
        vm.prank(CHAINLINK_ORACLE_ADDRESS); //The caller most by the oracle address set in APIConsumerContract
        apiConsumer.fulfill(request_id, dummyVolume);
        console.log(dummyVolume);
    }
}

/**Importante descomentar la linea 145 de ChainlinkClient.sol antes de desplegar el contrato en sepolia */
