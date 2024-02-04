//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library stringToUintConverter {
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
}
