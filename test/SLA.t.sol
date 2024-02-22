// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeploySLA} from "../script/DeploySLA.s.sol";
import {SLA} from "../src/SLA.sol";

contract SLATest is Test {
    SLA sla;

    //Test SLA variables
    string private providerName;
    address private providerAddress;
    string private docHash;
    uint256 private maxlatency;
    uint256 private minthroughput;
    uint256 private maxJitter;
    uint256 private minBandWith;

    //Test API Consumer variables
    address public CHAINLINK_AUTOMATION_ADDRESS =
        makeAddr("Chainlink Automation");
    address public CHAINLINK_ORACLE_ADDRESS =
        0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD; //Extracted from APIConsumerContract

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

    /**API Consumer test */
    /******************* */
    //test extract params auxiliar function
    function testSuccessfullParamsExtraction() public view {
        string memory data = "12,11,13,14";
        sla.extractParams(data);
    }

    function testNoFitNumberOfParametersForExtraction() public {
        string memory data = "12,11,13,14,15";
        vm.expectRevert(SLA.SLA_NoFitNumberOfParamsForExtraction.selector);
        sla.extractParams(data);
        data = "12";
        vm.expectRevert(SLA.SLA_NoFitNumberOfParamsForExtraction.selector);
        sla.extractParams(data);
    }

    function testRevertForInvalidDigits() public {
        string memory data = "A,19,B,13";
        vm.expectRevert(SLA.SLA_Str2UintInvalidDigit.selector);
        sla.extractParams(data);
    }

    //test SLA-APIConsumer
    function testSLARequestVolumeWithCorrectInput() public {
        vm.prank(CHAINLINK_AUTOMATION_ADDRESS);
        //Request Volume Data to Chainlink Oracle
        //Comented line 145 to evit transferAndCall Revert, Link transfer is not needed in test
        bytes32 request_id = sla.requestVolumeData();
        string memory dummyVolume = "12452,1902,19002,1900";
        vm.prank(CHAINLINK_ORACLE_ADDRESS); //The caller most by the oracle address set in APIConsumerContract
        sla.fulfill(request_id, dummyVolume);
        console.log(dummyVolume);
    }

    //check Violations
    //Calculate penalties
    //Envío de fondos
    //Terminacion
}
