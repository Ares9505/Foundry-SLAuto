// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./mylib/ConfirmedOwner.sol"; //"@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * THIS EXAMPLE USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract APIConsumerPolygon is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    string public volume;
    bytes32 public jobId;
    uint256 private fee;

    string public myAPIurl;
    string public myPath;
    uint256 timeSend;
    uint256 timeReceive;

    event ChailinkRequestSendTime(uint256 sendTime);
    event RequestVolume(
        bytes32 indexed requestId,
        string volume,
        uint256 receiveTime
    );

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); //https://docs.chain.link/resources/link-token-contracts
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3); //https://docs.chain.link/any-api/testnet-oracles/
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;
        myAPIurl = "https://httpbin.org/get?metrics=19%2C11%2C12";
        myPath = "args,metrics";
    }

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
        timeSend = block.timestamp;
        emit ChailinkRequestSendTime(block.timestamp);
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(
        bytes32 _requestId,
        string memory _volume
    ) public recordChainlinkFulfillment(_requestId) {
        volume = _volume;
        emit RequestVolume(_requestId, _volume, block.timestamp);
        timeReceive = block.timestamp;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
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

    function getTimeMesuare() public view returns (uint256, uint256, uint256) {
        uint256 rtt_bc_ch = timeReceive - timeSend;
        return (timeReceive, timeSend, rtt_bc_ch);
    }
}
