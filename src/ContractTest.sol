// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

pragma solidity ^0.8.0;

contract Example {
    uint256 test;
    string myname;

    constructor(string memory _myname) {
        myname = _myname;
    }

    function settest(uint256 _test) public {
        test = _test;
    }

    function getname() public view returns (string memory) {
        return myname;
    }

    function gettest() public view returns (uint256) {
        return test;
    }
}
