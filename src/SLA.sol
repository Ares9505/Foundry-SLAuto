//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract SLA {
    //SLA Parameters`
    string providerName;
    address providerAddress;
    string docHash;
    string APIKey;
    //Put here all enpoints
    string endpointLatency;
    //Time parameters
    uint256 auctionWindow; //pending
    uint256 expirationDate;

    // Constructor para inicializar los parámetros del contrato
    constructor(
        string memory _providerName,
        address _providerAddress,
        string memory _docHash,
        string memory _APIKey,
        string memory _endpointLatency,
        uint256 _auctionWindow,
        uint256 _expirationDate
    ) {
        providerName = _providerName;
        providerAddress = _providerAddress;
        docHash = _docHash;
        APIKey = _APIKey;
        endpointLatency = _endpointLatency;
        auctionWindow = _auctionWindow;
        expirationDate = _expirationDate;
    }

    function retrieve() public view returns (string memory) {
        return providerName;
    }
}

/*Actividades para SC SLA:
1. Modificador q compruebe si el contrato esta terminado o no. Se debe aplicar a todas las funciones
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
*/
