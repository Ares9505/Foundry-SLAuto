//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Auction {
    address payable beneficiary; // Proveedor dueño de la subasta
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;
    bool ended;

    mapping(address => uint) pendingReturns;

    event hihestBidIncresed(address bidder, uint amount);
    event auctionEnded(address winner, uint amount);

    constructor(uint256 _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        if (block.timestamp > auctionEndTime)
            revert("The auction time has ended");
        if (msg.value <= highestBid)
            revert("sorry, the bid is not high enough");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit hihestBidIncresed(msg.sender, msg.value);
    }

    function auctionEnd() public {}
}

/**Actividades para SC Auction:   Para un SLA inactivo asigna un cliente. Para ello
 * 1. Funcion recibir oferta.
 * 2. Funcion para determinar oferta ganadora:
 *      Declarar SLA activo asignandole cliente a partir de llamar la funcion del SLA correspondiente para añadir el cliente
 *      Pasar valor de pago mensual a SC SLA
 * 3. Al acabar el tiempo de subasta inhabilitar el contrato y notificar de termiancion sin interesados de no haberlos
 * (chainlink automation)
 *
 * 4. El proveedor puede escoger ganador previamente antes de terminar
 */
