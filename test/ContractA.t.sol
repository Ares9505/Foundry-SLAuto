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

    function testContract() public {
        uint256[18] memory params;
        params[0] = 1;
    }
}
