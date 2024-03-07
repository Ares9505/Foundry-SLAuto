//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployMarket} from "../script/DeployMarket.s.sol";
import {Market} from "../src/Market.sol";
import {SLA} from "../src/SLA.sol";
import {Auction} from "../src/Auction.sol";

contract testMarket is Test {
    error SLA_FailTransferToProvider();

    Market market;
    /**Provider interaction variables */
    address public NOT_PROVIDER = makeAddr("notProvider");
    address public PROVIDER_1 = makeAddr("provider");
    address public PROVIDER_2 = makeAddr("provider2");
    address public ownerAddress;

    /**SLA Creation Parameters */
    string constant DOCHASH = "0x29303039";

    /**SLA PARAMETER LIST */
    //==============================
    //Ejemplo UHD streaming video
    uint256 constant MINLATENCY = 4;
    uint256 constant MAXLATENCY = 20;
    uint256 constant MINTHROUGHPUT = 10;
    uint256 constant MAXJITTER = 10;
    uint256 constant MINBANDWITH = 10;
    /**SLA Seconds KPI Params */
    uint256 constant BIT_RATE = 100; // Mbps
    uint256 constant MAX_PACKET_LOSS = 1; //%
    uint256 constant PEAK_DATA_RATE_UL = 20;
    uint256 constant PEAK_DATA_RATE_DL = 10;
    uint256 constant MIN_MOBILITY = 0; // km/h
    uint256 constant MAX_MOBILITY = 10; // km/h
    uint256 constant SERVICE_RELIABILITY = 95; // Po
    /**SLA KQI Params */
    uint256 constant MAX_SURVIVAL_TIME = 1000;
    uint256 constant MIN_SURVIVAL_TIME = 500;
    uint256 constant EXPERIENCE_DATA_RATE_DL = 50;
    uint256 constant EXPERIENCE_DATA_RATE_UL = 20;
    uint256 constant MAX_INTERRUPTION_TIME = 200;
    uint256 constant MIN_INTERRUPTION_TIME = 100;
    /**SLA Monitoring PArams */
    uint256 constant DISPONIBILITY10 = 99;
    uint256 constant DISPONIBILITY30 = 90;
    uint256 constant MESUREPERIOD = 1 minutes;
    uint256 constant CONTRACT_DURATION = 4 weeks;
    //Auction Param
    uint256 constant BIDDINGTIME = 1 days;
    uint256 constant STARTVALUE = 0.02 ether;

    uint256 constant TOTAL_MESUREMENTS = 40320;
    uint256 constant PAYMENT = 0.3 ether;

    string constant ENDPOINT = "http://example.com";

    //**Client interaction variables */
    address public CLIENT_1 = makeAddr("client1");
    address public CLIENT_2 = makeAddr("client2");
    address public CLIENT_3 = makeAddr("client3");
    uint256 public constant STARTING_BALANCE = 100 ether;

    address public CHAINLINK_ORACLE_ADDRESS =
        0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD;
    address public CHAINLINK_AUTOMATION_ADDRESS =
        makeAddr("Chainlink Automation");

    function setUp() external {
        DeployMarket deployer = new DeployMarket();
        market = deployer.run();
        vm.deal(CLIENT_1, STARTING_BALANCE);
        vm.deal(CLIENT_2, STARTING_BALANCE);
        vm.deal(CLIENT_3, STARTING_BALANCE);
    }

    /** Auxiliar createSLA function */
    function createSLA()
        public
        returns (address /**sla address */, address /*auction address* */)
    {
        (address slaAddress, address auctionAddress) = market.createCustomSLA(
            DOCHASH,
            [
                uint256(MINLATENCY),
                uint256(MAXLATENCY),
                uint256(MINTHROUGHPUT),
                uint256(MAXJITTER),
                uint256(MINBANDWITH),
                uint256(BIT_RATE),
                uint256(MAX_PACKET_LOSS),
                uint256(PEAK_DATA_RATE_UL),
                uint256(PEAK_DATA_RATE_DL),
                uint256(MIN_MOBILITY),
                uint256(MAX_MOBILITY),
                uint256(SERVICE_RELIABILITY),
                uint256(MAX_SURVIVAL_TIME),
                uint256(MIN_SURVIVAL_TIME),
                uint256(EXPERIENCE_DATA_RATE_DL),
                uint256(EXPERIENCE_DATA_RATE_UL),
                uint256(MAX_INTERRUPTION_TIME),
                uint256(MIN_INTERRUPTION_TIME),
                uint256(DISPONIBILITY10),
                uint256(DISPONIBILITY30),
                uint256(MESUREPERIOD),
                uint256(CONTRACT_DURATION)
            ],
            ENDPOINT,
            BIDDINGTIME,
            STARTVALUE
        );

        return (slaAddress, auctionAddress);
    }

    function ownerCreateSLA()
        public
        returns (address /**sla address */, address /** auction address*/)
    {
        address owner = market.getOwner();
        vm.prank(owner);
        (address slaAddress, address auctionAddress) = createSLA();
        return (slaAddress, auctionAddress);
    }

    /**Test */
    //==================================
    function testOnlynNotProviderCantCreateSLA() public {
        vm.prank(NOT_PROVIDER);
        vm.expectRevert();
        createSLA();
    }

    function testOwnerCanCreateSLA() public {
        ownerCreateSLA();
    }

    function testNotProviderCanAddProvider() public {
        vm.prank(NOT_PROVIDER);
        vm.expectRevert();
        market.addProvider("etecsa", PROVIDER_1);
    }

    function testOnlyOwnerCanAddProviders() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER_1);
    }

    function testProviderCanAddOtherProvider() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER_1);
        vm.prank(PROVIDER_1);
        market.addProvider("movistart", PROVIDER_2);
    }

    function testSLAinactiveBeforeCreation() public {
        address owner = market.getOwner();
        vm.prank(owner);
        (address slaAddress, ) = createSLA();

        bool activationState = SLA(payable(slaAddress)).getSlaActivationState();
        assert(activationState == false);
    }

    /**Auxiliar function */
    //Commons to Custom SLA and Fixed SLA
    function setBiddingTimeEnd() public {
        vm.warp(block.timestamp + BIDDINGTIME + 1);
        vm.roll(block.number + 1);
    }

    //     /**Test SLA - Auction Flow test */
    function testAuctionStartAfterCustomSLAset() public {
        (, address auctionAddress) = ownerCreateSLA();
        console.log("LA direccion de la subasta es: ", auctionAddress);
    }

    //     // /**Test SLA - Auction Flows
    //     //  * *************************
    //     //  */

    function testAuctionEndNotAllowedBeforeBiddingTimeEnd() public {
        (, address auctionAddress) = ownerCreateSLA();
        vm.expectRevert();
        Auction(auctionAddress).auctionEnd();
    }

    function testEndSLAFromAuctionWhenNoBidsInBiddingTime() public {
        //Create Contract
        (address slaAddress, address auctionAddress) = ownerCreateSLA();

        //Set auction time ended
        testMarket.setBiddingTimeEnd();

        //Call auctionEnd
        Auction(auctionAddress).auctionEnd();

        //assert SLA ended correctly
        bool contractEnded = SLA(payable(slaAddress)).getContractEnded();
        assert(contractEnded);
    }

    function testRevertEndSLAWhenIsAlreadyEnded() public {
        //Create Contract
        (, address auctionAddress) = ownerCreateSLA();

        //Set auction time ended
        testMarket.setBiddingTimeEnd();

        //Call auctionEnd
        Auction(auctionAddress).auctionEnd();
        vm.expectRevert();
        Auction(auctionAddress).auctionEnd();
        //
    }

    /**  After SLA Creation, Clients bids, and Auction End the highestbid most
     * by transfer to the beneficiary and the SLA most be set to active
     */
    function testTransferMoneyToSLAAndSLAActivationWhenAuctionEndWithHighestBidder()
        public
    {
        ownerAddress = market.getOwner();
        //Arrenge
        (address slaAddress, address auctionAddress) = ownerCreateSLA();

        /** Act */
        //Cient1 and 2 make bids
        vm.prank(CLIENT_1);
        uint256 bidAmount1 = 0.1 ether;
        Auction(auctionAddress).bid{value: bidAmount1}();

        vm.prank(CLIENT_1);
        uint256 bidAmount2 = 0.3 ether;
        Auction(auctionAddress).bid{value: bidAmount2}();
        testMarket.setBiddingTimeEnd();

        //Set auctionEnd
        Auction(auctionAddress).auctionEnd();

        //Get auction end states
        uint256 highestBid = Auction(auctionAddress).getHighestbid();

        //Assert Money transfer to Owner and SLA Activation
        console.log(slaAddress.balance);
        assert(highestBid == slaAddress.balance);
        bool activeContract = SLA(payable(slaAddress)).getSlaActivationState();
        assert(activeContract);
        console.log("Monthly payment: ", SLA(payable(slaAddress)).getPayment());
    }

    function setupActiveContract() public returns (address, address) {
        ownerAddress = market.getOwner();
        //Arrenge
        (address slaAddress, address auctionAddress) = ownerCreateSLA();

        /** Act */
        //Cient1 and 2 make bids
        vm.prank(CLIENT_1);
        uint256 bidAmount1 = 0.1 ether;
        Auction(auctionAddress).bid{value: bidAmount1}();

        vm.prank(CLIENT_1);
        uint256 bidAmount2 = 0.3 ether;
        Auction(auctionAddress).bid{value: bidAmount2}();
        testMarket.setBiddingTimeEnd();

        //Set auctionEnd
        Auction(auctionAddress).auctionEnd();
        return (slaAddress, auctionAddress);
    }

    /** Test violations function
     * ---------------------------
     * this test have 3 asserts
     * 1- Test no violation when max mobility is exceeded
     * 2- Test violation when latency is exceded
     * 3- Test violation when jitter is exceded
     * 4- Test if violations has been counted
     */

    function testViolationsConditions() public {
        (address slaAddress, ) = setupActiveContract();
        uint16[18] memory slaPAramsExtractedBadType = [
            4, // 0: MINLATENCY 4
            20, // 1: MAXLATENCY 20
            10, // 2: MINTHROUGHPUT 10
            10, // 3: MAXJITTER 10
            10, // 4: MINBANDWITH 10
            100, // 5: BIT_RATE 100
            1, // 6: MAX_PACKET_LOSS 1
            20, // 7: PEAK_DATA_RATE_UL 20
            10, // 8: PEAK_DATA_RATE_DL 10
            0, // 9: MIN_MOBILITY 0
            10, // 10: MAX_MOBILITY 10
            95, // 11: SERVICE_RELIABILITY 95
            1000, // 12: MAX_SURVIVAL_TIME 1000
            500, // 13: MIN_SURVIVAL_TIME 500
            50, // 14: EXPERIENCE_DATA_RATE_DL 50
            20, // 15: EXPERIENCE_DATA_RATE_UL 20
            200, // 16: MAX_INTERRUPTION_TIME 200
            100 // 17: MIN_INTERRUPTION_TIME 100
        ];

        uint256[18] memory slaParamsExtracted;
        for (uint256 i = 0; i < 18; i++) {
            slaParamsExtracted[i] = uint256(slaPAramsExtractedBadType[i]);
        }

        //Setup 1
        //for these exmaple max interruption time is exceded param 16
        // and max mobility is exceded
        slaParamsExtracted[16] = 2000;
        slaParamsExtracted[10] = 100;
        bool setViolation = SLA(payable(slaAddress)).checkViolations(
            slaParamsExtracted
        );
        assert(!setViolation);
        slaParamsExtracted[16] = 200;
        slaParamsExtracted[10] = 10;

        //Setup2
        //Max latency exceded
        slaParamsExtracted[1] = 300;
        setViolation = SLA(payable(slaAddress)).checkViolations(
            slaParamsExtracted
        );
        assert(setViolation);
        slaParamsExtracted[1] = 20;

        //Setup 3
        //Max jitter Exceded
        slaParamsExtracted[3] = 25;
        setViolation = SLA(payable(slaAddress)).checkViolations(
            slaParamsExtracted
        );
        assert(setViolation);
        slaParamsExtracted[3] = 10;

        uint256 violations = SLA(payable(slaAddress)).getViolations();
        console.log(violations);
        assert(violations == 2); // untill know most be 2 violations
    }

    function simulateMonitoring() public returns (address) {
        (address slaAddress, ) = setupActiveContract();
        uint16[18] memory slaPAramsExtractedBadType = [
            4, // 0: MINLATENCY 4
            20, // 1: MAXLATENCY 20
            10, // 2: MINTHROUGHPUT 10
            10, // 3: MAXJITTER 10
            10, // 4: MINBANDWITH 10
            100, // 5: BIT_RATE 100
            1, // 6: MAX_PACKET_LOSS 1
            20, // 7: PEAK_DATA_RATE_UL 20
            10, // 8: PEAK_DATA_RATE_DL 10
            0, // 9: MIN_MOBILITY 0
            10, // 10: MAX_MOBILITY 10
            95, // 11: SERVICE_RELIABILITY 95
            1000, // 12: MAX_SURVIVAL_TIME 1000
            500, // 13: MIN_SURVIVAL_TIME 500
            50, // 14: EXPERIENCE_DATA_RATE_DL 50
            20, // 15: EXPERIENCE_DATA_RATE_UL 20
            200, // 16: MAX_INTERRUPTION_TIME 200
            100 // 17: MIN_INTERRUPTION_TIME 100
        ];

        uint256[18] memory slaParamsExtracted;
        for (uint256 i = 0; i < 18; i++) {
            slaParamsExtracted[i] = uint256(slaPAramsExtractedBadType[i]);
        }

        //Setup2
        //Max latency exceded
        slaParamsExtracted[1] = 300;
        bool setViolation = SLA(payable(slaAddress)).checkViolations(
            slaParamsExtracted
        );
        slaParamsExtracted[1] = 20;

        //Setup 3
        //Max jitter Exceded
        slaParamsExtracted[3] = 25;
        setViolation = SLA(payable(slaAddress)).checkViolations(
            slaParamsExtracted
        );
        slaParamsExtracted[3] = 10;
        return slaAddress;
    }

    function testPenaltiesCalculations() public {
        address slaAddress = simulateMonitoring();

        //violation for
        uint256 violations = 0;
        (, uint256 penalty) = SLA(payable(slaAddress)).calculatePenalties(
            TOTAL_MESUREMENTS,
            violations,
            PAYMENT
        );
        console.log("Penalty for 100% disponibility", penalty);
        assert(penalty == 0);

        //violations for 30%
        violations = 14112; //number of violatios for 35% diponibility
        (, penalty) = SLA(payable(slaAddress)).calculatePenalties(
            TOTAL_MESUREMENTS,
            violations,
            PAYMENT
        );
        console.log("Penalty for 30 percent disponibility", penalty); //30% x payment
        assert(penalty == (30 * PAYMENT) / 100);

        violations = 3500;
        (, penalty) = SLA(payable(slaAddress)).calculatePenalties(
            TOTAL_MESUREMENTS,
            violations,
            PAYMENT
        );
        console.log("Penalty for 10 percent disponibility", penalty); //30% x payment
        assert(penalty == (10 * PAYMENT) / 100);
    }

    function testTotalMesurements() public {
        (address slaAddress, ) = setupActiveContract();
        uint256 mesurements = SLA(payable(slaAddress)).getTotalMesurements();
        assert(mesurements == CONTRACT_DURATION / MESUREPERIOD);
    }

    /**Test for contract termination */
    function testSLACantByTerminateBeforeContractDuration() public {
        (address slaAddress, ) = setupActiveContract();
        uint256 fixedPenalty = (30 * PAYMENT) / 100;
        vm.expectRevert();
        SLA(payable(slaAddress)).terminateContract(PAYMENT, fixedPenalty);
    }

    function testRevertIfErrorInTransfer() public {
        (address slaAddress, ) = setupActiveContract();
        uint256 fixedPenalty = (30 * PAYMENT) / 100;
        //Set time to exceed endDate
        vm.warp(block.timestamp + CONTRACT_DURATION + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(SLA_FailTransferToProvider.selector); //payment fixed to be greater than the balance of the contract
        SLA(payable(slaAddress)).terminateContract(
            PAYMENT + 0.4 ether,
            fixedPenalty
        );
    }

    function testTransfersOcurrSuccessfully() public {
        //Market owner add provider
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER_1);

        //Provider create SLA
        vm.prank(PROVIDER_1);
        (address slaAddress, address auctionAddress) = market.createCustomSLA(
            DOCHASH,
            [
                uint256(MINLATENCY),
                uint256(MAXLATENCY),
                uint256(MINTHROUGHPUT),
                uint256(MAXJITTER),
                uint256(MINBANDWITH),
                uint256(BIT_RATE),
                uint256(MAX_PACKET_LOSS),
                uint256(PEAK_DATA_RATE_UL),
                uint256(PEAK_DATA_RATE_DL),
                uint256(MIN_MOBILITY),
                uint256(MAX_MOBILITY),
                uint256(SERVICE_RELIABILITY),
                uint256(MAX_SURVIVAL_TIME),
                uint256(MIN_SURVIVAL_TIME),
                uint256(EXPERIENCE_DATA_RATE_DL),
                uint256(EXPERIENCE_DATA_RATE_UL),
                uint256(MAX_INTERRUPTION_TIME),
                uint256(MIN_INTERRUPTION_TIME),
                uint256(DISPONIBILITY10),
                uint256(DISPONIBILITY30),
                uint256(MESUREPERIOD),
                uint256(CONTRACT_DURATION)
            ],
            ENDPOINT,
            BIDDINGTIME,
            STARTVALUE
        );

        //Client make a bid and the action is ended
        vm.prank(CLIENT_1);
        uint256 bidAmount2 = 0.3 ether;
        Auction(auctionAddress).bid{value: bidAmount2}();
        testMarket.setBiddingTimeEnd();
        Auction(auctionAddress).auctionEnd();

        //Contract have funds at this time

        uint256 fixedPenalty = (30 * PAYMENT) / 100;
        //Set time to exceed endDate
        vm.warp(block.timestamp + CONTRACT_DURATION + 1);
        vm.roll(block.number + 1);

        //Check balances before termination
        uint256 clientBalanceBeforeTermination = CLIENT_1.balance;
        uint256 providerBalanceBeforeTermination = PROVIDER_1.balance;
        console.log(
            "clientBalanceBeforeTermination: ",
            clientBalanceBeforeTermination
        );
        console.log(
            "providerBalanceBeforeTermination: ",
            providerBalanceBeforeTermination
        );

        (bool activeContract, bool contractEnded) = SLA(payable(slaAddress))
            .terminateContract(PAYMENT, fixedPenalty);

        //Check balances after termination
        uint256 clientBalance = CLIENT_1.balance;
        uint256 providerBalance = PROVIDER_1.balance;

        console.log("clientBalance after: ", clientBalance);
        console.log("providerBalance after: ", providerBalance);
        console.log("fixedPenalty: ", fixedPenalty);
        console.log("Payment: ", PAYMENT);
        assert(clientBalance - clientBalanceBeforeTermination == fixedPenalty);
        assert(
            providerBalance - providerBalanceBeforeTermination ==
                PAYMENT - fixedPenalty
        );
        assert(contractEnded);
        assert(!activeContract);
    }

    /**Auxiliar simulate monitoring
     * ------------------------------
     * A diferencia de simulate monitoring, no crea ni activa un sla
     * previamente
     */

    function simulateOnlyMonitoring(
        address slaAddress,
        bool withViolations
    ) public {
        vm.warp(block.timestamp + MESUREPERIOD);
        vm.roll(block.number + 1);

        vm.prank(CHAINLINK_AUTOMATION_ADDRESS);
        //Request Volume Data to Chainlink Oracle
        //Comented line 145 to evit transferAndCall Revert, Link transfer is not needed in test
        bytes32 request_id = SLA(payable(slaAddress)).requestVolumeData();
        string memory dummyVolume;
        if (withViolations) {
            dummyVolume = "4,20,10,10,10,100,1,20,10,0,10,95,1000,500,50,20,200,100";
        } else {
            //latencia exedida
            dummyVolume = "4,200,10,10,10,100,1,20,10,0,10,95,1000,500,50,20,200,100";
        }

        vm.prank(CHAINLINK_ORACLE_ADDRESS); //The caller most by the oracle address set in APIConsumerContract
        SLA(payable(slaAddress)).fulfill(request_id, dummyVolume);
    }

    function testIntegrationsOfFunctionsOnFullfill() public {
        /**Pasos del test:
         * Se crea SC Market
         * Se añade proveedor 1
         *
         */

        //Market owner add provider
        address owner = market.getOwner();
        vm.prank(owner);
        market.addProvider("etecsa", PROVIDER_1);

        //Provider create SLA
        uint256 contractDuration = 1 days; //para que la prueba no dure tanto
        vm.prank(PROVIDER_1);
        (address slaAddress, address auctionAddress) = market.createCustomSLA(
            DOCHASH,
            [
                uint256(MINLATENCY),
                uint256(MAXLATENCY),
                uint256(MINTHROUGHPUT),
                uint256(MAXJITTER),
                uint256(MINBANDWITH),
                uint256(BIT_RATE),
                uint256(MAX_PACKET_LOSS),
                uint256(PEAK_DATA_RATE_UL),
                uint256(PEAK_DATA_RATE_DL),
                uint256(MIN_MOBILITY),
                uint256(MAX_MOBILITY),
                uint256(SERVICE_RELIABILITY),
                uint256(MAX_SURVIVAL_TIME),
                uint256(MIN_SURVIVAL_TIME),
                uint256(EXPERIENCE_DATA_RATE_DL),
                uint256(EXPERIENCE_DATA_RATE_UL),
                uint256(MAX_INTERRUPTION_TIME),
                uint256(MIN_INTERRUPTION_TIME),
                uint256(DISPONIBILITY10),
                uint256(DISPONIBILITY30),
                uint256(MESUREPERIOD),
                contractDuration
            ],
            ENDPOINT,
            BIDDINGTIME,
            STARTVALUE
        );

        //Client make a bid and the action is ended
        vm.prank(CLIENT_1);
        uint256 bidAmount = 0.3 ether;
        Auction(auctionAddress).bid{value: bidAmount}();

        vm.prank(CLIENT_2);
        uint256 bidAmount2 = 0.5 ether;
        Auction(auctionAddress).bid{value: bidAmount2}();

        testMarket.setBiddingTimeEnd();
        Auction(auctionAddress).auctionEnd();

        //Simulate 30% de malas mediciones pero usando la funcion fullfill
        uint256 totalMesurements = SLA(payable(slaAddress))
            .getTotalMesurements();
        uint256 badMesurements = (totalMesurements * 30) / 100;

        for (uint256 i = 0; i < badMesurements; i++) {
            simulateOnlyMonitoring(slaAddress, true /**withViolations */);
        }
        for (uint256 i = badMesurements; i < totalMesurements; i++) {
            simulateOnlyMonitoring(slaAddress, false /**withViolations */);
        }

        bool activationState = SLA(payable(slaAddress)).getSlaActivationState();
        assert(activationState);
        console.log("payment", SLA(payable(slaAddress)).getPayment());
        console.log("penalty", SLA(payable(slaAddress)).getPenalty());
    }
    // //function
    // function testIntegration
    // function testTermination
    // funciton testMoneyTransferPenalties
}
