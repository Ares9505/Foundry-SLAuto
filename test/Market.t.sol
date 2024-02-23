//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployMarket} from "../script/DeployMarket.s.sol";
import {Market} from "../src/Market.sol";
import {SLA} from "../src/SLA.sol";
import {Auction} from "../src/Auction.sol";

contract testMarket is Test {
    Market market;
    /**Provider interaction variables */
    address public NOT_PROVIDER = makeAddr("notProvider");
    address public PROVIDER_1 = makeAddr("provider");
    address public PROVIDER_2 = makeAddr("provider2");
    address public ownerAddress;

    /**SLA Creation Parameters */
    string constant DOCHASH = "0x29303039";
    uint256 constant MAXLATENCY = 10;
    uint256 constant MINTHROUGHPUT = 10;
    uint256 constant MAXJITTER = 10;
    uint256 constant MINBANDWITH = 10;
    string constant ENDPOINT = "http://example.com";

    /**SLA Seconds KPI Params */
    uint256 constant BIT_RATE = 100; // Mbps
    uint256 constant MAX_PACKET_LOSS = 2;
    //uint256 constant PEAK_DATA_RATE_UL = 5;
    //uint256 constant PEAK_DATA_RATE_DL = 10;
    //uint256 constant MIN_MOBILITY = 20; // km/h
    uint256 constant MAX_MOBILITY = 50; // km/h
    uint256 constant SERVICE_RELIABILITY = 99; // Po

    /**SLA KQI Params */
    uint256 constant MAX_SURVIVAL_TIME = 1000;
    uint256 constant MIN_SURVIVAL_TIME = 500;
    //uint256 constant EXPERIENCE_DATA_RATE_DL = 50;
    //uint256 constant EXPERIENCE_DATA_RATE_UL = 20;
    uint256 constant MAX_INTERRUPTION_TIME = 200;
    uint256 constant MIN_INTERRUPTION_TIME = 100;

    uint256 constant DISPONIBILITY10 = 99;
    uint256 constant DISPONIBILITY30 = 90;
    uint256 constant MESUREPERIOD = 1 minutes;
    uint256 constant PAYMENTPERIOD = 4 weeks; //Auction Param

    uint256 constant BIDDINGTIME = 1 days;

    //**Client interaction variables */
    address public CLIENT_1 = makeAddr("client1");
    address public CLIENT_2 = makeAddr("client2");
    address public CLIENT_3 = makeAddr("client3");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        DeployMarket deployer = new DeployMarket();
        market = deployer.run();
        vm.deal(CLIENT_1, STARTING_BALANCE);
        vm.deal(CLIENT_2, STARTING_BALANCE);
        vm.deal(CLIENT_3, STARTING_BALANCE);
    }

    function testOnlynNotProviderCantCreateSLA() public {
        vm.prank(NOT_PROVIDER);
        vm.expectRevert();
        market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
    }

    function testOwnerCanCreateSLA() public {
        address owner = market.getOwner();
        vm.prank(owner);
        market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
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
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        bool activationState = SLA(slaAddress).getSlaActivationState();
        assert(activationState == false);
    }

    function testSLAOwnerCanSetKPIs() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
    }

    function testSLANotProviderCantSetKPIs() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(address(market));
        vm.expectRevert();
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
    }

    function testSetSLAKPIsCantByCalledTwoice() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
        vm.prank(owner);
        vm.expectRevert();
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
    }

    function testSLAOwnerCanSetKQIs() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
        vm.prank(owner);
        market.setSLAParamsKQIs(
            slaAddress,
            MAX_SURVIVAL_TIME,
            MIN_SURVIVAL_TIME,
            MAX_INTERRUPTION_TIME,
            MIN_INTERRUPTION_TIME,
            DISPONIBILITY10,
            DISPONIBILITY30,
            MESUREPERIOD,
            PAYMENTPERIOD,
            BIDDINGTIME
        );
    }

    function testSLAOwnerCanNOTBeSetKQIsTwoice() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
        vm.prank(owner);
        market.setSLAParamsKQIs(
            slaAddress,
            MAX_SURVIVAL_TIME,
            MIN_SURVIVAL_TIME,
            MAX_INTERRUPTION_TIME,
            MIN_INTERRUPTION_TIME,
            DISPONIBILITY10,
            DISPONIBILITY30,
            MESUREPERIOD,
            PAYMENTPERIOD,
            BIDDINGTIME
        );
        vm.prank(owner);
        vm.expectRevert();
        market.setSLAParamsKQIs(
            slaAddress,
            MAX_SURVIVAL_TIME,
            MIN_SURVIVAL_TIME,
            MAX_INTERRUPTION_TIME,
            MIN_INTERRUPTION_TIME,
            DISPONIBILITY10,
            DISPONIBILITY30,
            MESUREPERIOD,
            PAYMENTPERIOD,
            BIDDINGTIME
        );
    }

    function testCantSetKQIsBeforeKPIs() public {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        vm.expectRevert();
        market.setSLAParamsKQIs(
            slaAddress,
            MAX_SURVIVAL_TIME,
            MIN_SURVIVAL_TIME,
            MAX_INTERRUPTION_TIME,
            MIN_INTERRUPTION_TIME,
            DISPONIBILITY10,
            DISPONIBILITY30,
            MESUREPERIOD,
            PAYMENTPERIOD,
            BIDDINGTIME
        );
    }

    /** Auction - SLA Interactions for test
     * ********************************
     */
    /**For CreateCustomSLA
     *Simulate interaction of create SLA and fill it, when fill it an Auction most be created */
    function createSLAAndFillKPIandKQIs()
        public
        returns (address /**slaAddress */, address /**auctionAddress */)
    {
        address owner = market.getOwner();
        vm.prank(owner);
        address slaAddress = market.createCustomSLA(
            DOCHASH,
            MAXLATENCY,
            MINTHROUGHPUT,
            MAXJITTER,
            MINBANDWITH,
            ENDPOINT
        );
        vm.prank(owner);
        market.setSLAParamsKPIsSecondBatch(
            slaAddress,
            BIT_RATE,
            MAX_PACKET_LOSS,
            //PEAK_DATA_RATE_UL,
            //PEAK_DATA_RATE_DL,
            //MIN_MOBILITY,
            MAX_MOBILITY, // km/h
            SERVICE_RELIABILITY
        );
        vm.prank(owner);
        address auctionAddress = market.setSLAParamsKQIs(
            slaAddress,
            MAX_SURVIVAL_TIME,
            MIN_SURVIVAL_TIME,
            MAX_INTERRUPTION_TIME,
            MIN_INTERRUPTION_TIME,
            DISPONIBILITY10,
            DISPONIBILITY30,
            MESUREPERIOD,
            PAYMENTPERIOD,
            BIDDINGTIME
        );
        return (slaAddress, auctionAddress);
    }

    //Commons to Custom SLA and Fixed SLA
    function setBiddingTimeEnd() public {
        vm.warp(block.timestamp + BIDDINGTIME + 1);
        vm.roll(block.number + 1);
    }

    /**Test SLA - Auction Flow test */
    function testAuctionStartAfterCustomSLAset() public {
        (, address auctionAddress) = createSLAAndFillKPIandKQIs();
        console.log("LA direccion de la subasta es: ", auctionAddress);
    }

    // /**Test SLA - Auction Flows
    //  * *************************
    //  */

    function testAuctionEndNotAllowedBeforeBiddingTimeEnd() public {
        (, address auctionAddress) = createSLAAndFillKPIandKQIs();
        vm.expectRevert();
        Auction(auctionAddress).auctionEnd();
    }

    function testEndSLAFromAuctionWhenNoBidsInBiddingTime() public {
        //Create Contract
        (
            address slaAddress,
            address auctionAddress
        ) = createSLAAndFillKPIandKQIs();

        //Set auction time ended
        testMarket.setBiddingTimeEnd();

        //Call auctionEnd
        Auction(auctionAddress).auctionEnd();

        //assert SLA ended correctly
        bool contractEnded = SLA(slaAddress).getContractEnded();
        assert(contractEnded);
    }

    function testRevertEndSLAWhenIsAlreadyEnded() public {
        //Create Contract
        (, address auctionAddress) = createSLAAndFillKPIandKQIs();

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
    function testTransferMoneyToBeneficiaryAndSLAActivationWhenAuctionEndWithHighestBidder()
        public
    {
        ownerAddress = market.getOwner();
        //Arrenge
        (
            address slaAddress,
            address auctionAddress
        ) = createSLAAndFillKPIandKQIs();

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
        uint256 ownerBalanceBeforeAuctionEnd = ownerAddress.balance;
        Auction(auctionAddress).auctionEnd();

        //Get auction end states
        uint256 ownerBalance = ownerAddress.balance;
        uint256 highestBid = Auction(auctionAddress).getHighestbid();

        //Assert Money transfer to Owner and SLA Activation
        assert(highestBid == ownerBalance - ownerBalanceBeforeAuctionEnd);
        bool activeContract = SLA(slaAddress).getSlaActivationState();
        assert(activeContract);
        console.log("Monthly payment: ", SLA(slaAddress).getMontlyPayment());
    }
}
