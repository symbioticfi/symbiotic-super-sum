// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OzAccessControl} from "@symbioticfi/relay-contracts/src/modules/common/permissions/OzAccessControl.sol";
import {Settlement as SymbioticSettlement} from "@symbioticfi/relay-contracts/src/modules/settlement/Settlement.sol";

contract Settlement is SymbioticSettlement, OzAccessControl {
    function initialize(SettlementInitParams memory settlementInitParams, address defaultAdmin)
        public
        virtual
        initializer
    {
        __Settlement_init(settlementInitParams);
        __OzAccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }
}
