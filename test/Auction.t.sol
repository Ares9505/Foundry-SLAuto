// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployAuction} from "../script/DeployAuction.s.sol";
import {Auction} from "../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;
    address public CLIENT_1 = makeAddr("client1");
    address public CLIENT_2 = makeAddr("client2");
    address public CLIENT_3 = makeAddr("client3");
    uint256 public biddingTime = 1 days;
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        DeployAuction deployer = new DeployAuction();
        auction = deployer.run();
        vm.deal(CLIENT_1, STARTING_BALANCE);
        vm.deal(CLIENT_2, STARTING_BALANCE);
        vm.deal(CLIENT_3, STARTING_BALANCE);
    }

    function testDeployment() public view {
        console.log("Auction deployment done");
    }

    function testBidLowerThanHighestBidGetReverted() public {
        vm.prank(CLIENT_1);
        uint256 bidAmount = 0;
        vm.expectRevert();
        auction.bid{value: bidAmount}();
    }

    function testUpdateCurrentHighestBidBeforeFirstClientBid() public {
        vm.prank(CLIENT_1);
        uint256 bidAmount = 0.1 ether;
        auction.bid{value: bidAmount}();
        address currentHighestBidder = auction.getHighestBidder();
        uint256 highestBid = auction.getHighestbid();
        assertEq(CLIENT_1, currentHighestBidder);
        assertEq(highestBid, bidAmount);
    }

    modifier twoConsecutiveBids() {
        vm.prank(CLIENT_1);
        uint256 bidAmountClient1 = 0.1 ether;
        auction.bid{value: bidAmountClient1}();

        vm.prank(CLIENT_2);
        uint256 bidAmountClient2 = 0.2 ether;
        auction.bid{value: bidAmountClient2}();
        _;
    }

    function testUpdateCurrentHighestBidBefore3Bids()
        public
        twoConsecutiveBids
    {
        vm.prank(CLIENT_3);
        uint256 bidAmountClient3 = 0.3 ether;
        auction.bid{value: bidAmountClient3}();

        address currentHighestBidder = auction.getHighestBidder();
        uint256 highestBid = auction.getHighestbid();
        assertEq(CLIENT_3, currentHighestBidder);
        assertEq(highestBid, bidAmountClient3);
    }

    function testUpdateCurrentHighestBidBeforeClient1BidForSecondTime()
        public
        twoConsecutiveBids
    {
        vm.prank(CLIENT_1);
        uint256 bidAmountClient3 = 0.3 ether;
        auction.bid{value: bidAmountClient3}();

        address currentHighestBidder = auction.getHighestBidder();
        uint256 highestBid = auction.getHighestbid();
        assertEq(CLIENT_1, currentHighestBidder);
        assertEq(highestBid, bidAmountClient3);
    }

    function testUpdatePendingsReturnBeforeClient1BidForSecondTime()
        public
        twoConsecutiveBids
    {
        vm.prank(CLIENT_1);
        uint256 bidAmountClient1_2 = 0.3 ether;
        auction.bid{value: bidAmountClient1_2}();
        uint256 bidAmountClient1 = 0.1 ether; //same as modifier

        uint256 client1TotalAmountBidded = bidAmountClient1 +
            bidAmountClient1_2;
        uint256 pendingReturnsAmount = auction.getPendingReturnFormAddress(
            CLIENT_1
        );
        assertEq(client1TotalAmountBidded, pendingReturnsAmount);
    }

    function testNotBidAcceptedAfterAuctionEnded() public {
        //Set the auction time passed
        vm.warp(block.timestamp + biddingTime + 1);
        vm.roll(block.number + 1);
        //Try bid
        vm.prank(CLIENT_1);
        uint256 bidAmountClient1 = 0.1 ether;
        //Assert
        vm.expectRevert();
        auction.bid{value: bidAmountClient1}();
    }

    //withdrawTestWithOutEndAuction
    function testOnlyNotHighestBidderCanWithdrawFunds()
        public
        twoConsecutiveBids
    {
        vm.prank(CLIENT_1);
        auction.withdraw();

        vm.prank(CLIENT_2);
        vm.expectRevert();
        auction.withdraw();
    }
}

/**Actividades para SC Auction:   Para un SLA inactivo asigna un cliente. Para ello
 * 1. Funcion recibir oferta.X
 * 2. Funcion para determinar oferta ganadora:
 *      * Declarar SLA activo asignandole cliente a partir de llamar la funcion del SLA
 *      correspondiente para añadir el cliente X
 *      * Pasar valor de pago mensual a SC SLA
 * 3. Al acabar el tiempo de subasta inhabilitar el contrato y notificar de termiancion sin interesados de no haberlos X
 * (chainlink automation)
 *
 * 4. El proveedor puede escoger ganador previamente antes de terminar (si da tiempo)
 *
 * 5. Cambiar a private todas la variables
 * ¿Que pasa si no hubo ganador?
 * poner un piso (valor minimo) a la subasta
 */
