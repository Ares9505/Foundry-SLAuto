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

    event RequestVolume(bytes32 indexed requestId, string volume);

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
    ) ConfirmedOwner(msg.sender) {
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

        //API Consumer Params
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;
        myAPIurl = "https://httpbin.org/get?metrics=19%2C11%2C12";
        myPath = "args,metrics";
    }

    /** API Consumer Functions */
    /************************* */
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
        extractParams(volume);

        //Check Violations
    }

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

    /**Conditions Checks */

    /** Setters */
    //This function can be called by auction when the auction end without bids
    function setContractEnd() external {
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

    function getContractEnded() external view returns (bool) {
        return contractEnded;
    }

    function getMontlyPayment() external view returns (uint256) {
        return montlyPayment;
    }
}

/*Actividades para SC SLA:
1. Add SLA Parameters X
2. Funcion que añada un cliente al contrato. Esta función solo se puede llamar por el contrato Auction X
3. Función para obtener metricas de la api
    Ajustar herencia de SLA para que se comporte como API Consumer


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
