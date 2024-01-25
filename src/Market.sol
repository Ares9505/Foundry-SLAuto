// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SLA} from "./SLA.sol";

contract Market {
    //List to Restrict SLA creation to providers
    mapping(address => string) public provider;
    mapping(address => bool) internal existProvider;

    SLA[] public listOfSLA; //List of SLA
    address i_owner; //Saving contract owner

    constructor(string memory _providerName) {
        i_owner = msg.sender;
        //inicialization of provider mappings
        provider[i_owner] = _providerName;
        existProvider[i_owner] = true;
    }

    ////Restrict SLA creation to providers
    modifier onlyProvider() {
        require(existProvider[msg.sender], "Provider not allowed");
        _;
    }

    function addProvider(
        string memory _providerName,
        address _providerAddress
    ) public onlyProvider {
        provider[_providerAddress] = _providerName;
        existProvider[_providerAddress] = true;
    }

    function createSLA(
        string memory docHash,
        string memory APIKey,
        //Poner todos los endpoint
        string memory endpointLatency,
        //Time parameters
        uint256 auctionWindow, //pending
        uint256 expirationDate
    ) public onlyProvider {
        string memory providerName = provider[msg.sender];
        address providerAddress = msg.sender;
        SLA newSLA = new SLA(
            providerName,
            providerAddress,
            docHash,
            APIKey,
            endpointLatency,
            auctionWindow,
            expirationDate
        );
        listOfSLA.push(newSLA);
    }

    function discoverSLA(uint _index) public view returns (string memory) {
        return listOfSLA[_index].retrieve();
    }
}

/*
Add parameters
Entry example
"HashDocumentoEjemplo", "APIKeyEjemplo", "EndpointLatencyEjemplo", 86400, 1672531199
*/
