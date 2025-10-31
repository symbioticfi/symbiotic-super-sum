// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {
    EqualStakeVPCalc
} from "@symbioticfi/relay-contracts/src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {
    OpNetVaultAutoDeploy
} from "@symbioticfi/relay-contracts/src/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol";
import {OzOwnable} from "@symbioticfi/relay-contracts/src/modules/common/permissions/OzOwnable.sol";
import {VotingPowerProvider} from "@symbioticfi/relay-contracts/src/modules/voting-power/VotingPowerProvider.sol";

contract VotingPowers is VotingPowerProvider, OzOwnable, EqualStakeVPCalc, OpNetVaultAutoDeploy {
    constructor(address operatorRegistry, address vaultFactory, address vaultConfigurator)
        VotingPowerProvider(operatorRegistry, vaultFactory)
        OpNetVaultAutoDeploy(vaultConfigurator)
    {}

    function initialize(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams,
        OpNetVaultAutoDeployInitParams memory opNetVaultAutoDeployInitParams,
        OzOwnableInitParams memory ozOwnableInitParams
    ) public virtual initializer {
        __VotingPowerProvider_init(votingPowerProviderInitParams);
        __OpNetVaultAutoDeploy_init(opNetVaultAutoDeployInitParams);
        __OzOwnable_init(ozOwnableInitParams);
        __EqualStakeVPCalc_init();
    }

    function _registerOperatorImpl(address operator) internal override(OpNetVaultAutoDeploy, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }

    function _unregisterOperatorVaultImpl(address operator, address vault)
        internal
        override(OpNetVaultAutoDeploy, VotingPowerProvider)
    {
        super._unregisterOperatorVaultImpl(operator, vault);
    }
}
