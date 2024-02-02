// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SLA} from "./SLA.sol";
import {Auction} from "./Auction.sol";

contract Market {
    error Market_InvalidProvider();
    //List to Restrict SLA creation to providers
    mapping(address => string) public provider;
    mapping(address => bool) private providerExist;

    SLA[] public listOfSLA; //List of SLA
    address private i_owner; //Saving contract owner

    constructor(string memory _providerName) {
        i_owner = msg.sender;
        //inicialization of provider mappings
        provider[i_owner] = _providerName;
        providerExist[i_owner] = true;
    }

    ////Restrict SLA creation to providers
    modifier onlyProvider() {
        if (!providerExist[msg.sender]) {
            revert Market_InvalidProvider();
        }
        _;
    }

    function addProvider(
        string memory _providerName,
        address _providerAddress
    ) public onlyProvider {
        provider[_providerAddress] = _providerName;
        providerExist[_providerAddress] = true;
    }

    function createSLA(
        string memory _docHash,
        uint256 _maxlatency,
        uint256 _minthroughput,
        uint256 _maxJitter,
        uint256 _minBandWith,
        string memory _endpoint,
        //auction data
        uint256 _biddingTime
    )
        public
        onlyProvider
        returns (address /**sla address */, address /**auction add */)
    {
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
        Auction newAuction = new Auction(
            _biddingTime,
            payable(msg.sender),
            payable(address(newSLA))
        );
        //Pendent: Set AuctionAddress in SLA

        return (address(newSLA), address(newAuction));
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

    /**Getters */

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

/*
Add parameters
Entry example
"HashDocumentoEjemplo", "APIKeyEjemplo", "EndpointLatencyEjemplo", 86400, 1672531199
*/

/**Actividades para SC Market:
 *X 1. Recibe parámetros para la creación de SLA 
 *     X 1.1. Para la creacion de un SLA se debe acompañar con la creacion de una subasta que
 *           requiere la direccion del SLA y el tiempo de subasta como parametros 
 * X 2. Hacer modificador de requerido para crear SC SLA inactivos. (Solo proveedores registrados 
 *      pueden crear nuevos SLA) 
 * 3. Hacer registro de clientes con los parametros (address, nombre)
 * 4. Hacer función de descubrimiento de SLA “inactivos”.
 *      Una idea es q devuelva todos los SLA y q se filtren los inactivos se muestren en la dAPP para no consumir gas de mas
 * 5. Canalizar como un cliente hace una oferta desde market y llega a la subasta de determinado SLA(Solo un cliente puede participar en la subasta)
 
 * 
 * 4. Asegurarse de que solo los clientes pueden ver los SLAs
 * 5. Añadir cliente inactivo y evento a SLA subasta
 * 6. Añadir eventos de creacion de contrato
 * 
 * Revisar
 
 */
