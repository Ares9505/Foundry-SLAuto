//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./mylib/ConfirmedOwner.sol"; //"@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "./mylib/strings.sol";

contract SLA is ChainlinkClient, ConfirmedOwner {
    error SLA_SLAAlredyActive();
    error SLA_SLANoActive();
    error SLA_AuctionAddressAlreadySet();
    error SLA_SLACanEndByAuctionBecauseIsActive();
    error SLA_NoFitNumberOfParamsForExtraction();
    error SLA_Str2UintInvalidDigit();
    error SLA_KPIsAlreadyset();
    error SLA_InvalidProvider();
    error SLA_KQIsAlreadySet();
    error SLA_KPIsMostBeSetFirst();
    error SLA_FailTransferToProvider();
    error SLA_FailTransferToClient();
    error SLA_SLACantByEndBeforeContractDuration();

    //API Consumer variables
    using Chainlink for Chainlink.Request;
    string public volume;
    bytes32 public jobId;
    uint256 private fee;

    string public myAPIurl;
    string public myPath;

    //To use string utilities
    using strings for *;

    //SLA Info
    string private providerName;
    address private providerAddress;
    string private docHash;

    // SLA parameters thresholds
    uint256 private minlatency; // 0
    uint256 private maxlatency; // 1
    uint256 private minthroughput; // 2
    uint256 private maxJitter; // 3
    uint256 private minBandWith; // 4

    // SLA 2nd batch KPIs thresholds
    uint256 private bitRate; // 5
    uint256 private maxPacketLoos; // 6
    uint256 private peakDataRateUL; // 7
    uint256 private peakDataRateDL; // 8
    uint256 private minMobility; // 9
    uint256 private maxMobility; // 10
    uint256 private serviceReliability; // 11

    // SLA KQI thresholds
    uint256 private maxSurvivalTime; // 12
    uint256 private minSurvivalTime; // 13
    uint256 private experienceDataRateDL; // 14
    uint256 private experienceDataRateUL; // 15
    uint256 private maxInterruptionTime; // 16
    uint256 private minInterrumptionTime; // 17

    // MonitoringParams
    uint256 private disponibility10; // 18
    uint256 private disponibility30; // 19
    uint256 private mesurePeriod; // 20
    uint256 private contractDuration; // 21 //un año usualmente

    //Not needed to retrive
    string private endpoint;
    bool private activeContract;
    bool private contractEnded;

    //Setup by auction
    address private client;
    address private auctionAddress;
    uint256 private payment;
    uint256 private startDate;
    uint256 private lastPaymentCut;
    uint256 private endDate;

    //Used in Monitoring after API Consumer
    //uint256 private violationsPaymentPeriodCount; // reseterar en cada periodo
    uint256 private violations; //for future think in send violations to SC recomendation system

    uint256 private totalMesurements;
    uint256 private disponibilityCalculated; //Calculeted once
    uint256 private currentDebt;

    //termination variables
    uint256 private penalty;
    bool private endPaid; //Tell if the entire contract was paid
    //Contract End , alredy declared

    event RequestVolume(bytes32 indexed requestId, string volume);
    event Received(address sender, uint amount);

    //string aPIKey;

    // Constructor para inicializar los parámetros del contrato
    constructor(
        string memory _providerName,
        address _providerAddress,
        string memory _docHash,
        uint256[22] memory _params,
        string memory _endpoint
    )
        //Set disponibility
        ConfirmedOwner(msg.sender)
    {
        providerName = _providerName;
        providerAddress = _providerAddress;
        docHash = _docHash;

        //SLA Params
        minlatency = _params[0];
        maxlatency = _params[1];
        minthroughput = _params[2];
        maxJitter = _params[3];
        minBandWith = _params[4];
        bitRate = _params[5];
        maxPacketLoos = _params[6];
        peakDataRateUL = _params[7];
        peakDataRateDL = _params[8];
        minMobility = _params[9];
        maxMobility = _params[10];
        serviceReliability = _params[11];
        maxSurvivalTime = _params[12];
        minSurvivalTime = _params[13];
        experienceDataRateDL = _params[14];
        experienceDataRateUL = _params[15];
        maxInterruptionTime = _params[16];
        minInterrumptionTime = _params[17];
        //monitoring params
        disponibility10 = _params[18];
        disponibility30 = _params[19];
        mesurePeriod = _params[20];
        contractDuration = _params[21];

        endpoint = _endpoint;
        activeContract = false;
        contractEnded = false;
        //needed for penalties calculation and termination

        //API Consumer Params
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;
        myAPIurl = "https://httpbin.org/get?metrics=19%2C11%2C12";
        myPath = "args,metrics";

        //Violations and Penalties calculations params
        violations = 0;
        currentDebt = 0;
        totalMesurements = contractDuration / mesurePeriod;
    }

    /** API Consumer Functions */
    /************************* */
    //this function is used by chainlink automation every "mesurePeriod"
    function requestVolumeData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", myAPIurl);

        req.add("path", myPath);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(
        bytes32 _requestId,
        string memory _volume
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _volume);
        volume = _volume;
        uint256[18] memory extractedParams;
        extractedParams = extractParams(volume);
        checkViolations(extractedParams);
        if (block.timestamp >= endDate) {
            (disponibilityCalculated, penalty) = calculatePenalties(
                totalMesurements,
                violations,
                payment
            );
            terminateContract(payment, penalty);
        }
    }

    //Note taht only owner is a modifier from ConfirmedOwner.sol
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function setJobId(bytes32 _jobId) public {
        jobId = _jobId;
    }

    function setAPIurl(string memory _myAPIurl, string memory _myPAth) public {
        myAPIurl = _myAPIurl;
        myPath = _myPAth;
    }

    /** Auxiliar Functions For Fullfillment */
    function str2uint(
        string memory str
    ) public pure returns (uint /**value */, bool /**success */) {
        bytes memory strBytes = bytes(str);
        uint value = 0;
        bool success = true;

        for (uint i = 0; i < strBytes.length; i++) {
            if (!(strBytes[i] >= bytes1("0") && strBytes[i] <= bytes1("9"))) {
                success = false;
                return (0, success);
            }

            value = value * 10 + (uint8(strBytes[i]) - 48);
        }

        return (value, success);
    }

    function extractParams(
        string memory rawData
    ) public pure returns (uint256[18] memory) {
        strings.slice memory stringSlice = rawData.toSlice();
        strings.slice memory delim = ",".toSlice();
        if (stringSlice.count(delim) != 17)
            //17 = numero de parametros de SLA a extraer - 1
            revert SLA_NoFitNumberOfParamsForExtraction();
        uint256[18] memory params; //= new uint[](stringSlice.count(delim) + 1);
        bool success;
        for (uint i = 0; i < params.length; i++) {
            string memory param = stringSlice.split(delim).toString();
            (params[i], success) = str2uint(param);
            if (!success) revert SLA_Str2UintInvalidDigit();
        }
        return params;
    }

    /**Checks Violations
     * Return bool when find violation
     */
    function checkViolations(uint256[18] memory params) public returns (bool) {
        bool setViolation = false;
        if (maxMobility < params[10]) return setViolation;
        if (
            //minltency = parmams[0]
            (maxlatency < params[1]) ||
            (minthroughput > params[2]) ||
            (maxJitter < params[3]) ||
            (minBandWith > params[4]) ||
            //bitRate params[5]
            (maxPacketLoos < params[6]) ||
            // peakDataRateUL params[7]
            // peakDataRateDL params[8]
            // minMobility params[9];
            //maxMobility <params[10];
            (serviceReliability > params[11]) ||
            //(maxSurvivalTime <params[12]) ||
            (minSurvivalTime > params[13]) ||
            //experienceDataRateDL params[14];
            //experienceDataRateUL params[15];
            (maxInterruptionTime < params[16])
            //minInterrumptionTime = params[17];
        ) {
            violations += 1;
            setViolation = true;
        }
        return setViolation;
    }

    /** Calculate penalties every measure period */
    function calculatePenalties(
        uint256 _totalMesurements,
        uint256 _violations,
        uint256 _payment
    ) public view returns (uint256, uint256) {
        uint256 _penalty = 0;
        uint256 _disponibilityCalculated = ((_totalMesurements - _violations) *
            100) / totalMesurements; //percent of compliance
        //Compare with established compliance to set compensation
        if (
            _disponibilityCalculated < disponibility10 &&
            _disponibilityCalculated >= disponibility30
        ) {
            _penalty = (10 * _payment) / 100; //10 percent compensation
        }
        if (_disponibilityCalculated < disponibility30) {
            _penalty = (30 * _payment) / 100; //30 percent compensation
        }
        return (_disponibilityCalculated, _penalty);
    }

    //Cambiar a internal por temas de seguridad
    function terminateContract(
        uint _payment,
        uint256 _penalties
    ) public returns (bool /**active Contract */, bool /**contract ended */) {
        if (block.timestamp >= endDate) {
            uint256 providerPayment = _payment - _penalties;
            (bool success, ) = providerAddress.call{value: providerPayment}("");
            if (!success) revert SLA_FailTransferToProvider();
            uint256 clientReward = _penalties;
            (success, ) = client.call{value: clientReward}("");
            if (!success) revert SLA_FailTransferToClient();
            bool _activeContract = false;
            bool _contractEnded = true;
            return (_activeContract, _contractEnded);
        } else {
            revert SLA_SLACantByEndBeforeContractDuration();
        }
    }

    /** Setters */

    //This function can be called by auction when the auction end without bids
    function setContractEnd() public {
        //(P) poner condicion de que solo se puede llamar por auction y el propio contrato (internal y external modifier conflic)
        //Only can by called if the contract is inactive
        if (activeContract) revert SLA_SLACanEndByAuctionBecauseIsActive();
        //hacer pagos finales
        contractEnded = true;
    }

    /**This function will by used to set auction address before SLA and auction creation */
    function setAuctionAddres() external {
        if (activeContract) revert SLA_AuctionAddressAlreadySet();
        auctionAddress = msg.sender;
    }

    /*This function is called by auction when the client es defined
     *and activate the SLA operation before asigning client
     */
    function setClient(address _client, uint _payment) external {
        if (activeContract) revert SLA_SLAAlredyActive();
        client = _client;
        activeContract = true;
        payment = _payment;
        startDate = block.timestamp;
        endDate = startDate + contractDuration;
        lastPaymentCut = block.timestamp;
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

    function getContractEnded() external view returns (bool) {
        return contractEnded;
    }

    function getPayment() external view returns (uint256) {
        return payment;
    }

    function getProviderAddress() external view returns (address) {
        return providerAddress;
    }

    function getViolations() external view returns (uint256) {
        return violations;
    }

    function getTotalMesurements() external view returns (uint256) {
        return totalMesurements;
    }

    function getPenalty() external view returns (uint256) {
        return penalty;
    }

    receive() external payable {
        // Emitir evento para registrar la recepción de ether
        emit Received(msg.sender, msg.value);
    }
}

/*Actividades para SC SLA:
1. Add SLA Parameters X
    Modificar para añadir mas parámetros
        uint256 _bitRate,
        uint256 _maxPacketLoos,
        uint256 _peakDataRateUL,
        uint256 _peakDataRateDL,
        //uint256 _minMobility,
        uint256 _maxMobility,
        uint256 _serviceReliability,
        uint256 _maxSurvivalTime,
        uint256 _minSurvivalTime,
        //uint256 _experienceDataRateDL,
        //uint256 _experienceDataRateUL,
        uint256 _maxInterruptionTime,
        uint256 _minInterrumptionTime,


2. Funcion que añada un cliente al contrato. Esta función solo se puede llamar por el contrato Auction X
    Esta funcion activa el contrato X
    Fija el pago mensual X
    Añade al cliente X   
    Fija el inicio del contrato (testing pendent)
    Determina la primera fecha de pago (testing pendent)

3. Función para obtener metricas de la api
    Integrar api consumer a SLA X
    Funcion para extraer los parámetros 4 parametros latencia, througput ... de un string X

4. Funcion para Chequear violaciones X
        Pensar en añadir evento que diga que parámetro due violado

5. Funcion Para Calcular penalidades
6. Funcion para fijar actualizar deuda y deuda en terminacion de contrato



//check Violations
//Calculate penalties (Leer Enabling Dynamic SLA Compensation Using Blockchain-based Smart Contracts)
//Envío de fondos
//Terminacion




4. Al terminarse el contrato se deben descontar las penalizaciones y sumar recompensas.
    Para no tener gastos por hacer mas de una transaccion si se paga de violacion en violacion.
    El pago se hace después del servicio y se descuentan las penalizaciones
    Se registra cuanto debe el cliente, suponiedo cobro mensual.
5. Función para el cálculo de penalizades

6. Funcion de retencion por parte del contrato en caso de disputa.
    Esta funcion puede ser llamada por el cliente, y evita q el proveedor pueda retirar fondos
7. Le informa al SC sistema de recomendacion de las violaciones al terminar el mes
8. Modificador q compruebe si el contrato esta terminado o no. Se debe aplicar a todas las funciones
*/
