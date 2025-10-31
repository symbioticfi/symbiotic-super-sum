// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {
    KeyRegistry as SymbioticKeyRegistry
} from "@symbioticfi/relay-contracts/src/modules/key-registry/KeyRegistry.sol";

contract KeyRegistry is SymbioticKeyRegistry {
    function initialize(KeyRegistryInitParams memory keyRegistryInitParams) public virtual initializer {
        __KeyRegistry_init(keyRegistryInitParams);
    }
}
