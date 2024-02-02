// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract DeployAuction is Script {
    Auction auction;
    string marketCreator;

    //Auction constructor parameters
    uint256 constant biddingTime = 1 days;
    address payable beneficiary;
    address slaAddress = makeAddr("SLA");

    function run() public returns (Auction) {
        vm.startBroadcast();
        beneficiary = payable(msg.sender);
        console.log("The beneficiary is: ", beneficiary);
        console.log("Sla Address is: ", slaAddress);
        auction = new Auction(biddingTime, beneficiary, slaAddress);
        console.log("Auction constructor caller: ", msg.sender); //quiero ver quien es el que llama al constructor
        vm.stopBroadcast();
        return auction;
    }
}

//Probar correr el script con anvil
//Hacer makefile para correr con anvil
//Hacer un test de integracion donde se corran dos deplous de SLA y auction
//Hacer un test para market con todo el proceso
