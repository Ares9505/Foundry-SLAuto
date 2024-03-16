// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Auction} from "../../src/Auction.sol";

contract DeployAuctionSepolia is Script {
    Auction auction;
    string marketCreator;

    //Auction constructor parameters
    uint256 constant biddingTime = 365 days;
    uint256 constant startValue = 0.00001 ether;
    address payable beneficiary;
    address slaAddress = makeAddr("SLA");

    function run() public returns (Auction) {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployer);
        beneficiary = payable(msg.sender);
        console.log("The beneficiary is: ", beneficiary);
        console.log("Sla Address is: ", slaAddress);
        auction = new Auction(biddingTime, beneficiary, slaAddress, startValue);
        console.log("Auction constructor caller: ", msg.sender); //quiero ver quien es el que llama al constructor
        vm.stopBroadcast();
        console.log(startValue);
        return auction;
    }
}

// forge script script/SepoliaDeploy/DeployAuctionSepolia.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
