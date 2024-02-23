// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployContractTest} from "../script/DeployContractTest.s.sol";
import {Example} from "../src/ContractTest.sol";

contract ContractTestTest is Test {
    Example public example;

    function setUp() external {
        DeployContractTest deployer = new DeployContractTest();
        example = deployer.run();
    }

    function testContract() public pure {
        uint256[18] memory params;
        params[0] = 1;
        params[1] = 2;
        params[2] = 3;
        params[3] = 4;
        params[4] = 5;
        params[5] = 6;
        params[6] = 7;
        params[7] = 8;
        params[8] = 9;
        params[9] = 10;
        params[10] = 11;
        params[11] = 12;
        params[12] = 13;
        params[13] = 14;
        params[14] = 15;
        params[15] = 16;
        params[16] = 17;
        params[17] = 18;
    }
}
