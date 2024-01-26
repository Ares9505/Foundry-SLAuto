//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployMarket} from "../script/DeployMarket.s.sol";
import {Market} from "../src/Market.sol";
import {SLA} from "../src/SLA.sol";

contract testMarket is Test {
    Market market;
    address public NOT_PROVIDER = makeAddr("notProvider");
    address public PROVIDER = makeAddr("provider");
    address public PROVIDER2 = makeAddr("provider2");
    address public ownerAddress;

    function setUp() external {
        DeployMarket deployer = new DeployMarket();
        market = deployer.run();
    }

    function testOnlynNotProviderCantCreateSLA() public {
        vm.prank(NOT_PROVIDER);
        vm.expectRevert();
        market.createSLA("0x29303039", 10, 10, 10, 10, "http://example.com");
    }

    function testOwnerCanCreateSLA() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.createSLA("0x29303039", 10, 10, 10, 10, "http://example.com");
    }

    function testNotProviderCanAddProvider() public {
        vm.prank(NOT_PROVIDER);
        vm.expectRevert();
        market.addProvider("etecsa", PROVIDER);
    }

    function testOnlyOwnerCanAddProviders() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER);
    }

    function testProviderCanAddOtherProvider() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER);
        vm.prank(PROVIDER);
        market.addProvider("movistart", PROVIDER2);
    }

    function testSLAinactiveBeforeCreation() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createSLA(
            "0x29303039",
            10,
            10,
            10,
            10,
            "http://example.com"
        );
        bool activationState = SLA(slaAddress).getSlaActivationState();
        assert(activationState == false);
    }
}
