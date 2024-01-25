//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address apiConsumerAddress;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrcreateAnvilEhtConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                apiConsumerAddress: 0x972F78ad66FadFE9635474085728b99d712f7Df3
            });
    }

    function getOrcreateAnvilEhtConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.apiConsumerAddress != address(0)) {
            return activeNetworkConfig;
        }

        //Some mock contract deploy to simulate oracle request

        return
            NetworkConfig({
                apiConsumerAddress: 0x972F78ad66FadFE9635474085728b99d712f7Df3
            });
    }
}
