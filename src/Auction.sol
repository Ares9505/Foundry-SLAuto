//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Auction {
    error Auction_AuctionTimeEnded();
    error Auction_WithdrawFailed();
    error Auction_AuctionAlredyEnded();
    error Auction_SetActiveContractUnsucessful();
    error Auction_HighestBidderCantWithdrawFunds();
    error Auction_BiddingTimeNotEnd();

    address payable beneficiary; // Proveedor dueño de la subasta
    uint256 public auctionEndTime;
    address public slaAddress;

    address private highestBidder;
    uint256 private highestBid;
    bool ended;

    mapping(address => uint256) private pendingReturns;

    event highestBidIncresed(address bidder, uint256 amount);
    event auctionEnded(address winner, uint256 amount);

    constructor(
        uint256 _biddingTime,
        address payable _beneficiary,
        address _slaAddress
    ) {
        beneficiary = _beneficiary; // the provider is the beneficiary
        auctionEndTime = block.timestamp + _biddingTime;
        slaAddress = _slaAddress;
        ended = false;
    }

    modifier auctionEndedMod() {
        if (block.timestamp > auctionEndTime) revert Auction_AuctionTimeEnded();
        _;
    }

    function bid() public payable auctionEndedMod {
        if (msg.value <= highestBid)
            revert("sorry, the bid is not high enough");

        highestBidder = msg.sender;
        highestBid = msg.value;

        pendingReturns[highestBidder] += highestBid;
        emit highestBidIncresed(msg.sender, msg.value);
    }

    function withdraw() public payable returns (bool) {
        //Only can withdraw if the caller is not the current highestbidder
        if (highestBidder == msg.sender)
            revert Auction_HighestBidderCantWithdrawFunds();

        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
        }

        if (!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
            revert Auction_WithdrawFailed();
        }
        return true;
    }

    function auctionEnd() public {
        if (block.timestamp < auctionEndTime)
            revert Auction_BiddingTimeNotEnd();
        if (ended) revert Auction_AuctionAlredyEnded();
        ended = true;
        //End without bidders interest
        if (highestBid == 0) {
            //call SLA End
            (bool success, ) = slaAddress.call(
                abi.encodeWithSignature("setContractEnd()")
            );
            require(success, "Contract end Successfully");
        } else {
            beneficiary.transfer(highestBid);
            //Establish client and SLA active
            (bool successSetActive, ) = slaAddress.call(
                abi.encodeWithSignature(
                    "setClient(address,uint256)",
                    highestBidder,
                    highestBid
                )
            );
            require(successSetActive, "SLA Activation Error");
        }
        emit auctionEnded(highestBidder, highestBid);
    }

    /**Getters Functions */
    function getHighestBidder() external view returns (address) {
        return highestBidder;
    }

    function getHighestbid() external view returns (uint256) {
        return highestBid;
    }

    function getPendingReturnFormAddress(
        address _bidder
    ) external view returns (uint256) {
        return pendingReturns[_bidder];
    }
}

/**Actividades para SC Auction:   Para un SLA inactivo asigna un cliente. Para ello
 * 1. Funcion recibir oferta.
 * 2. Funcion para determinar oferta ganadora:
 *      Declarar SLA activo asignandole cliente a partir de llamar la funcion del SLA correspondiente para añadir el cliente
 *      Pasar valor de pago mensual a SC SLA
 * 3. Al acabar el tiempo de subasta inhabilitar el contrato y notificar de termiancion sin interesados de no haberlos
 * (chainlink automation)
 *
 * 4. El proveedor puede escoger ganador previamente antes de terminar (si da tiempo)
 *
 * ¿Que pasa si no hubo ganador?
 * poner un piso (valor minimo) a la subasta
 *
 *
 * Pendent
 * Add getters
 * Cambiar a private todas la variables
 * Restringir Auction end a el chainlink keepers para ser llamada
 * Fix events auctionEnded, create other events
 */
