//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./mylib/ConfirmedOwner.sol"; //"@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "./mylib/strings.sol";
import "./mylib/Str2Uint.sol";

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

    //API Consumer variables
    using Chainlink for Chainlink.Request;
    string public volume;
    bytes32 public jobId;
    uint256 private fee;

    string public myAPIurl;
    string public myPath;

    //To use string utilities
    using strings for *;
    using stringToUintConverter for string;

    //SLA Info
    string private providerName;
    address private providerAddress;
    string private docHash;
    uint private constant contractDuration = 365 days; //usualmente un año

    //SLA parameters thresholds
    uint256 private minlatency;
    uint256 private maxlatency;
    uint256 private minthroughput;
    uint256 private maxJitter;
    uint256 private minBandWith;

    //SLA 2nd batch KPIs thresholds
    uint256 private bitRate;
    uint256 private maxPacketLoos;
    uint256 private peakDataRateUL;
    uint256 private peakDataRateDL;
    uint256 private minMobility;
    uint256 private maxMobility;
    uint256 private serviceReliability;

    //SLA KQI thresholds
    uint256 private maxSurvivalTime;
    uint256 private minSurvivalTime;
    uint256 private experienceDataRateDL;
    uint256 private experienceDataRateUL;
    uint256 private maxInterruptionTime;
    uint256 private minInterrumptionTime;

    //MonitingParams
    uint256 private disponibility10;
    uint256 private disponibility30;
    uint256 private mesurePeriod;
    uint256 private paymentPeriod; //monthly

    //Not needed to retrive
    string private endpoint;
    bool private activeContract;
    bool private contractEnded;

    //Setup by auction
    address private client;
    address private auctionAddress;
    uint256 private monthlyPayment;
    uint256 private startDate;
    uint256 private lastPaymentCut;
    uint256 private endDate;

    //Used in Monitoring after API Consumer
    uint256 private violationsPaymentPeriodCount; // reseterar en cada periodo
    uint256 private totalViolations; //for future think in send violations to SC recomendation system

    uint256 private totalMesurements;
    uint256 private disponibilityCalculated; //Calculeted monthly
    uint256 private currentDebt;

    //termination variables
    bool private endPaid; //Tell if the entire contract was paid
    //Contract End , alredy declared

    event RequestVolume(bytes32 indexed requestId, string volume);

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
        paymentPeriod = _params[21];

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
        violationsPaymentPeriodCount = 0;
        totalViolations = 0;
        currentDebt = 0;
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
        //Funcionality added different from API Consumer
        (
            uint latency,
            uint througput,
            uint jitter,
            uint bandwith
        ) = extractParams(volume);
        checkViolations(latency, througput, jitter, bandwith);
        //calculate penalty if paymentPeriod (set to a month) is reached due to only one automation is used
        //Esta funcion se ejecuta si han pasado payment period
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
    function extractParams(
        string memory rawData
    )
        public
        pure
        returns (
            uint256 /**latency */,
            uint256 /**througput */,
            uint256 /**jitter */,
            uint256 /**Bandwith */
        )
    {
        strings.slice memory stringSlice = rawData.toSlice();
        strings.slice memory delim = ",".toSlice();
        if (stringSlice.count(delim) != 3)
            revert SLA_NoFitNumberOfParamsForExtraction();
        uint256[] memory params = new uint[](stringSlice.count(delim) + 1);
        bool success;
        for (uint i = 0; i < params.length; i++) {
            string memory param = stringSlice.split(delim).toString();
            (params[i], success) = param.str2uint();
            if (!success) revert SLA_Str2UintInvalidDigit();
        }
        return (params[0], params[1], params[2], params[3]);
    }

    /**Checks Violations
     * Return bool when find violation
     */
    function checkViolations(
        uint256 latency,
        uint256 througput,
        uint256 jitter,
        uint256 bandwith
    ) public returns (bool) {
        bool latencyExceeded = (latency > maxlatency);
        bool througputInsuficient = (througput < minthroughput);
        bool jitterExceeded = (jitter > maxJitter);
        bool bandwithInsuficient = (bandwith < minBandWith);
        bool setViolation = latencyExceeded ||
            througputInsuficient ||
            jitterExceeded ||
            bandwithInsuficient;
        if (setViolation) {
            violationsPaymentPeriodCount += 1;
        }
        return setViolation;
    }

    /** Calculate penalties every measure period */
    function calculatePenalties() public returns (uint256) {
        uint penalty = 0;
        disponibilityCalculated =
            ((totalMesurements - violationsPaymentPeriodCount) * 100) /
            totalMesurements; //percent of compliance
        //Compare with established compliance to set compensation
        if (
            disponibilityCalculated < disponibility10 &&
            disponibilityCalculated >= disponibility30
        ) {
            penalty = (10 * monthlyPayment) / 100; //10 percent compensation
        }
        if (disponibilityCalculated < disponibility30) {
            penalty = (30 * monthlyPayment) / 100; //30 percent compensation
        }
        return penalty;
    }

    function checkContractEnd(uint _penalty) public {
        if (block.timestamp > endDate) {
            currentDebt -= _penalty;
            setContractEnd();
            //still not paid, i meant payment pendent
        }
    }

    /** This function most by called every paymentPeriod
     * at leats untill the contract end
     */
    function setClientDebth(uint256 _penalty) internal {
        currentDebt += monthlyPayment - _penalty;
        totalViolations += violationsPaymentPeriodCount;
        violationsPaymentPeriodCount = 0;
    }

    function payDebth() public payable {
        //(P) condicion de que si paga toda la deuda es que se establece el contrato como pagado
    }

    /** Setters */

    // function setSLAParamsKPIsSecondBatch(
    //     address _providerAddress,
    //     uint256 _bitRate,
    //     uint256 _maxPacketLoos,
    //     //uint256 _peakDataRateUL,
    //     //uint256 _peakDataRateDL,
    //     //uint256 _minMobility,
    //     uint256 _maxMobility,
    //     uint256 _serviceReliability
    // ) public {
    //     if (_providerAddress != providerAddress) revert SLA_InvalidProvider();
    //     if (!setKPIsSuccess) {
    //         bitRate = _bitRate;
    //         maxPacketLoos = _maxPacketLoos;
    //         //peakDataRateUL =  _peakDataRateUL,
    //         //peakDataRateDL =  _peakDataRateDL,
    //         //minMobility    =  _minMobility,
    //         maxMobility = _maxMobility;
    //         serviceReliability = _serviceReliability;
    //         setKPIsSuccess = true;
    //     } else revert SLA_KPIsAlreadyset();
    // }

    // function setSLAParamsKQIsParamsMonitoring(
    //     address _providerAddress,
    //     uint256 _maxSurvivalTime,
    //     uint256 _minSurvivalTime,
    //     //uint256 _experienceDataRateDL,
    //     //uint256 _experienceDataRateUL,
    //     uint256 _maxInterruptionTime,
    //     uint256 _minInterrumptionTime,
    //     //monitoring params
    //     uint256 _disponibility10,
    //     uint256 _disponibility30,
    //     uint256 _mesurePeriod,
    //     uint256 _paymentPeriod
    // ) public {
    //     if (_providerAddress != providerAddress) revert SLA_InvalidProvider();
    //     //set   KQIs
    //     if (!setKPIsSuccess) revert SLA_KPIsMostBeSetFirst();
    //     if (!setKQIsSuccess) {
    //         setKQIsSuccess = true;
    //     } else revert SLA_KQIsAlreadySet();
    // }

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
    function setClient(address _client, uint _montlyPayment) external {
        if (activeContract) revert SLA_SLAAlredyActive();
        client = _client;
        activeContract = true;
        monthlyPayment = _montlyPayment;
        startDate = block.timestamp;
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

    function getMontlyPayment() external view returns (uint256) {
        return monthlyPayment;
    }

    function getProviderAddress() external view returns (address) {
        return providerAddress;
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
