// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Network as SymbioticNetwork} from "@symbioticfi/relay-contracts/contracts/modules/network/Network.sol";

contract Network is SymbioticNetwork {
    constructor(address networkRegistry, address networkMiddlewareService)
        SymbioticNetwork(networkRegistry, networkMiddlewareService)
    {}

    function initialize(NetworkInitParams memory networkInitParams) public virtual initializer {
        __Network_init(networkInitParams);
    }
}
