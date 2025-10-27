// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OzAccessControl} from "@symbioticfi/relay-contracts/src/modules/common/permissions/OzAccessControl.sol";
import {ValSetDriver} from "@symbioticfi/relay-contracts/src/modules/valset-driver/ValSetDriver.sol";

contract Driver is ValSetDriver, OzAccessControl {
    function initialize(ValSetDriverInitParams memory valSetDriverInitParams, address defaultAdmin)
        public
        virtual
        initializer
    {
        __ValSetDriver_init(valSetDriverInitParams);
        __OzAccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }
}
