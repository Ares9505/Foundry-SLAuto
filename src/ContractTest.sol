// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

pragma solidity ^0.8.0;

contract Example {
    uint256 var1;
    uint256 var2;
    uint256 var3;
    uint256 var4;
    uint256 var5;
    uint256 var6;
    uint256 var7;
    uint256 var8;
    uint256 var9;
    uint256 var10;
    uint256 var11;
    uint256 var12;
    uint256 var13;
    uint256 var14;
    uint256 var15;
    uint256 var16;
    uint256 var17;
    uint256 var18;

    function myfunc(uint256[18] memory parameters) public {
        require(parameters.length == 18, "Incorrect number of parameters");

        var1 = parameters[0];
        var2 = parameters[1];
        var3 = parameters[2];
        var4 = parameters[3];
        var5 = parameters[4];
        var6 = parameters[5];
        var7 = parameters[6];
        var8 = parameters[7];
        var9 = parameters[8];
        var10 = parameters[9];
        var11 = parameters[10];
        var12 = parameters[11];
        var13 = parameters[12];
        var14 = parameters[13];
        var15 = parameters[14];
        var16 = parameters[15];
        var17 = parameters[16];
        var18 = parameters[17];
    }

    function getParams() public view returns (uint256, uint256, uint256) {
        return (var1, var2, var3);
    }
}
