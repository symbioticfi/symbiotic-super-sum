// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/console.sol";
import {console2} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {SymbioticCoreInit} from "@symbioticfi/core-contracts/script/integration/SymbioticCoreInit.sol";
import {IVault} from "@symbioticfi/core-contracts/src/interfaces/vault/IVault.sol";
import {INetworkMiddlewareService} from
    "@symbioticfi/core-contracts/src/interfaces/service/INetworkMiddlewareService.sol";

import {INetwork} from "@symbioticfi/relay-contracts/interfaces/modules/network/INetwork.sol";
import {INetworkManager} from "@symbioticfi/relay-contracts/interfaces/modules/base/INetworkManager.sol";
import {IKeyRegistry} from "@symbioticfi/relay-contracts/interfaces/modules/key-registry/IKeyRegistry.sol";
import {IEpochManager} from "@symbioticfi/relay-contracts/interfaces/modules/valset-driver/IEpochManager.sol";
import {IValSetDriver} from "@symbioticfi/relay-contracts/interfaces/modules/valset-driver/IValSetDriver.sol";
import {IVotingPowerProvider} from
    "@symbioticfi/relay-contracts/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOpNetVaultAutoDeploy} from
    "@symbioticfi/relay-contracts/interfaces/modules/voting-power/extensions/IOpNetVaultAutoDeploy.sol";
import {SigVerifierBlsBn254Simple} from
    "@symbioticfi/relay-contracts/contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {ISettlement} from "@symbioticfi/relay-contracts/interfaces/modules/settlement/ISettlement.sol";
import {IOzOwnable} from "@symbioticfi/relay-contracts/interfaces/modules/common/permissions/IOzOwnable.sol";
import {IOzEIP712} from "@symbioticfi/relay-contracts/interfaces/modules/base/IOzEIP712.sol";
import {KeyTags} from "@symbioticfi/relay-contracts/contracts/libraries/utils/KeyTags.sol";
import {KeyBlsBn254, BN254} from "@symbioticfi/relay-contracts/contracts/libraries/keys/KeyBlsBn254.sol";
import {
    KEY_TYPE_BLS_BN254,
    KEY_TYPE_ECDSA_SECP256K1
} from "@symbioticfi/relay-contracts/interfaces/modules/key-registry/IKeyRegistry.sol";

import {BN254G2} from "./utils/BN254G2.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {LocalDeploy} from "./LocalDeploy.s.sol";

import {Network} from "../src/symbiotic/Network.sol";
import {KeyRegistry} from "../src/symbiotic/KeyRegistry.sol";
import {Driver} from "../src/symbiotic/Driver.sol";
import {VotingPowers} from "../src/symbiotic/VotingPowers.sol";
import {Settlement} from "../src/symbiotic/Settlement.sol";
import {SumTask} from "../src/SumTask.sol";

contract SettlementChainDeploy is LocalDeploy {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    function run() public override {
        deployer = getDeployerAddress();

        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core-contracts/";

        loadRelayContracts();
        loadSumTaskContracts();

        setupSettlement();
        logAndDumpRelayContracts();

        setupSumTask();
        logAndDumpSumTaskContracts();

        vm.startBroadcast();
        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            payable(getOperator(i).addr).transfer(1 ether);
        }
        vm.stopBroadcast();
    }
}
