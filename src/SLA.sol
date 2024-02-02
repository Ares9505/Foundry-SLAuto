//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract SLA {
    error SLA_SLAAlredyActive();
    error SLA_SLANoActive();
    error SLA_AuctionAddressAlreadySet();

    //SLA Info
    string private providerName;
    address private providerAddress;
    string private docHash;

    //SLA parameters thresholds
    uint256 private maxlatency;
    uint256 private minthroughput;
    uint256 private maxJitter;
    uint256 private minBandWith;

    //Not needed to retrive
    string private endpoint;
    bool private activeContract;
    bool private contractEnded;

    //Setup by auction
    address private client;
    address private auctionAddress;
    uint private montlyPayment;

    //string aPIKey;

    // Constructor para inicializar los parámetros del contrato
    constructor(
        string memory _providerName,
        address _providerAddress,
        string memory _docHash,
        uint256 _maxlatency,
        uint256 _minthroughput,
        uint256 _maxJitter,
        uint256 _minBandWith,
        string memory _endpoint
    ) {
        providerName = _providerName;
        providerAddress = _providerAddress;
        docHash = _docHash;
        maxlatency = _maxlatency;
        minthroughput = _minthroughput;
        maxJitter = _maxJitter;
        minBandWith = _minBandWith;
        endpoint = _endpoint;
        activeContract = false;
        contractEnded = false;
    }

    //This function can be called by auction when the auction end without bids
    function setContractEnd() external {
        //hacer pagos finales
        contractEnded = true;
    }

    /**This function will by used to set auction address before SLA and auction creation */
    function setAuctionAddres() external {
        if (activeContract) revert SLA_AuctionAddressAlreadySet();
        auctionAddress = msg.sender;
    }

    /*This function is called by auction whe the client es defined
     *and active de SLA operation before asing client
     */
    function setClient(address _client, uint _montlyPayment) external {
        if (activeContract) revert SLA_SLAAlredyActive();
        client = _client;
        activeContract = true;
        montlyPayment = _montlyPayment;
    }

    /**getters */
    function getSlaActivationState() public view returns (bool) {
        return activeContract;
    }

    function retrieveInfo()
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
        return (
            providerName,
            providerAddress,
            docHash,
            maxlatency,
            minthroughput,
            maxJitter,
            minBandWith
        );
    }
}

/*Actividades para SC SLA:
1. Add SLA Parameters X
2. Funcion que añada un cliente al contrato. Esta función solo se puede llamar por el contrato Auction
3. Al terminarse el contrato se deben descontar las penalizaciones y sumar recompensas.
    Para no tener gastos por hacer mas de una transaccion si se paga de violacion en violacion.
    El pago se hace después del servicio y se descuentan las penalizaciones
    Se registra cuanto debe el cliente, suponiedo cobro mensual.
4. Función para el cálculo de penalizades
5. Función para obtener metricas de la api
6. Funcion de retencion por parte del contrato en caso de disputa.
    Esta funcion puede ser llamada por el cliente, y evita q el proveedor pueda retirar fondos
7. Le informa al SC sistema de recomendacion de las violaciones al terminar el mes
8. Modificador q compruebe si el contrato esta terminado o no. Se debe aplicar a todas las funciones
*/
