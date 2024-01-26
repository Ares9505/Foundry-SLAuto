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
        string memory _docHash,
        uint256 _maxlatency,
        uint256 _minthroughput,
        uint256 _maxJitter,
        uint256 _minBandWith,
        string memory _endpoint
    ) public onlyProvider {
        SLA newSLA = new SLA(
            provider[msg.sender],
            msg.sender,
            _docHash,
            _maxlatency,
            _minthroughput,
            _maxJitter,
            _minBandWith,
            _endpoint
        );
        listOfSLA.push(newSLA);
    }

    function discoverSLA(
        uint _index
    )
        public
        view
        returns (
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return listOfSLA[_index].retrieveInfo();
    }
}

/*
Add parameters
Entry example
"HashDocumentoEjemplo", "APIKeyEjemplo", "EndpointLatencyEjemplo", 86400, 1672531199
*/

/**Actividades para SC Market:
 * 1. Recibe parámetros para la creación de SLA
 * 2. Hacer modificador de requerido para crear SC SLA inactivos (Solo proveedores registrados pueden crear nuevos SLA)
 * 3. Hacer función de descubrimiento de SLA “inactivos” (que se devuelva quienes son los proveedores)
 * 4. Asegurarse de que solo los clientes pueden ver los SLAs
 * 5. Añadir cliente inactivo y evento a SLA subasta
 */
