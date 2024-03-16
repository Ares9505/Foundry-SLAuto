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
    mapping(address => string) private addressToclients;

    SLA[] public listOfSLA; //List of SLA
    address private i_owner; //Saving contract owner

    event e_createSLA(
        string docHash,
        address newSLAAddress,
        address newAuctionAddress,
        uint256 endDate,
        uint256[22] params
    );

    event e_providerAdded(string providerName, address providerAddress);

    event e_clientAdded(string clientName, address clientAddress);

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
        emit e_providerAdded(_providerName, _providerAddress);
    }

    function addClient(
        string memory _clientName,
        address _clientAddress
    ) public {
        addressToclients[_clientAddress] = _clientName;
        emit e_clientAdded(_clientName, _clientAddress);
    }

    function createCustomSLA(
        string memory _docHash,
        uint256[22] memory _params,
        string memory _endpoint,
        uint256 _biddingTime,
        uint256 _startValue
    )
        public
        onlyProvider
        returns (address /**sla address */, address /**auction address */)
    {
        SLA newSLA = new SLA(
            provider[msg.sender],
            msg.sender,
            _docHash,
            _params,
            _endpoint
        );
        listOfSLA.push(newSLA);

        Auction newAuction = new Auction(
            _biddingTime,
            payable(msg.sender),
            payable(address(newSLA)),
            _startValue
        );

        uint256 _endDate = block.timestamp + _biddingTime;
        emit e_createSLA(
            _docHash,
            address(newSLA),
            address(newAuction),
            _endDate,
            _params
        );
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

    function getOwner() public view returns (address) {
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
 *
 * 3. Hacer registro de clientes con los parametros (address, nombre) X
 * 4. Hacer función de descubrimiento de SLA “inactivos”. X
 *      Una idea es q devuelva todos los SLA y q se filtren los inactivos se muestren en la dAPP para no consumir gas de mas
 *      Se usaron los eventos para ello X
 *
 * Revisar
 */

/**Problemas a pensar
 * Auction end puede ser llamado por cualquiera
 * La subasta debe ser terminada por chainlink keeper
 *
 */
