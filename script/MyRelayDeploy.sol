// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Vm, VmSafe} from "forge-std/Vm.sol";

import {VotingPowers} from "../src/symbiotic/VotingPowers.sol";
import {KeyRegistry} from "../src/symbiotic/KeyRegistry.sol";
import {Driver} from "../src/symbiotic/Driver.sol";
import {Settlement} from "../src/symbiotic/Settlement.sol";
import {SumTask} from "../src/SumTask.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {BN254G2} from "./utils/BN254G2.sol";

import {RelayDeploy} from "@symbioticfi/relay-contracts/script/RelayDeploy.sol";

import {BN254} from "@symbioticfi/relay-contracts/src/libraries/utils/BN254.sol";
import {KeyTags} from "@symbioticfi/relay-contracts/src/libraries/utils/KeyTags.sol";
import {KeyEcdsaSecp256k1} from "@symbioticfi/relay-contracts/src/libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyBlsBn254} from "@symbioticfi/relay-contracts/src/libraries/keys/KeyBlsBn254.sol";
import {
    SigVerifierBlsBn254Simple
} from "@symbioticfi/relay-contracts/src/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {
    SigVerifierBlsBn254ZK
} from "@symbioticfi/relay-contracts/src/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";
import {
    IVotingPowerProvider
} from "@symbioticfi/relay-contracts/src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {
    IOpNetVaultAutoDeploy
} from "@symbioticfi/relay-contracts/src/interfaces/modules/voting-power/extensions/IOpNetVaultAutoDeploy.sol";
import {INetworkManager} from "@symbioticfi/relay-contracts/src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "@symbioticfi/relay-contracts/src/interfaces/modules/base/IOzEIP712.sol";
import {IOzOwnable} from "@symbioticfi/relay-contracts/src/interfaces/modules/common/permissions/IOzOwnable.sol";
import {
    IKeyRegistry,
    KEY_TYPE_BLS_BN254,
    KEY_TYPE_ECDSA_SECP256K1
} from "@symbioticfi/relay-contracts/src/interfaces/modules/key-registry/IKeyRegistry.sol";
import {IValSetDriver} from "@symbioticfi/relay-contracts/src/interfaces/modules/valset-driver/IValSetDriver.sol";
import {IEpochManager} from "@symbioticfi/relay-contracts/src/interfaces/modules/valset-driver/IEpochManager.sol";
import {ISettlement} from "@symbioticfi/relay-contracts/src/interfaces/modules/settlement/ISettlement.sol";

import {Network, INetwork} from "@symbioticfi/network/src/Network.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {INetworkMiddlewareService} from "@symbioticfi/core/src/interfaces/service/INetworkMiddlewareService.sol";
import {Logs} from "@symbioticfi/core/script/utils/Logs.sol";
import {SymbioticCoreConstants} from "@symbioticfi/core/test/integration/SymbioticCoreConstants.sol";

contract MyRelayDeploy is RelayDeploy {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using KeyEcdsaSecp256k1 for address;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using KeyEcdsaSecp256k1 for bytes;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;

    bytes32 internal constant KEY_OWNERSHIP_TYPEHASH = keccak256("KeyOwnership(address operator,bytes key)");

    // Configurable constants
    uint48 internal immutable EPOCH_DURATION = uint48(vm.envOr("EPOCH_TIME", uint256(60)));
    uint48 internal constant SLASHING_WINDOW = 1 days; // 1 day
    uint208 internal constant MAX_VALIDATORS_COUNT = 1000; // 1000 validators
    uint256 internal constant MAX_VOTING_POWER = 2 ** 247; // no max limit
    uint256 internal constant MIN_INCLUSION_VOTING_POWER = 0; // include anyone
    uint248 internal constant QUORUM_THRESHOLD = (uint248(1e18) * 2) / 3 + 1; // 2/3 + 1
    uint8 internal constant REQUIRED_KEY_TAG = 15; // 15 is the default key tag (BLS-BN254/15)
    uint256 internal constant OPERATOR_STAKE_AMOUNT = 100_000;
    uint8 internal constant REQUIRED_KEY_TAG_ECDSA = 16; // 16 is the default key tag for ecdsa keys (ECDSA-SECP256K1/0)
    uint8 internal constant REQUIRED_KEY_TAG_SECONDARY_BLS = 11;
    uint256 internal immutable OPERATOR_COUNT = vm.envOr("OPERATOR_COUNT", uint256(4));
    uint8 internal immutable VERIFICATION_TYPE = uint8(vm.envOr("VERIFICATION_TYPE", uint256(1)));
    uint208 internal immutable NUM_AGGREGATORS = uint208(vm.envOr("NUM_AGGREGATORS", uint256(1)));
    uint208 internal immutable NUM_COMMITTERS = uint208(vm.envOr("NUM_COMMITTERS", uint256(1)));

    // CREATE3 salts
    bytes11 public constant NETWORK_SALT = bytes11("Network");
    bytes11 public constant SUM_TASK_SALT = bytes11("SumTask");
    bytes11 public constant KEY_REGISTRY_SALT = bytes11("KeyRegistry");
    bytes11 public constant VOTING_POWER_PROVIDER_SALT = bytes11("VPProvider");
    bytes11 public constant SETTLEMENT_SALT = bytes11("Settlement");
    bytes11 public constant VALSET_DRIVER_SALT = bytes11("VSDriver");

    constructor() RelayDeploy("./temp-network/my-relay-deploy.toml") {}

    function getDeployerAddress() internal returns (address deployer) {
        (,, deployer) = vm.readCallers();
    }

    function getStakingToken() internal returns (address) {
        if (config.get("staking_token").data.length == 0) {
            vm.broadcast();
            config.set("staking_token", address(new MockERC20("StakingToken", "STK")));
        }
        return config.get("staking_token").toAddress();
    }

    function getNetwork() internal returns (address) {
        if (config.get("network").data.length == 0) {
            address[] memory proposersAndExecutors = new address[](1);
            proposersAndExecutors[0] = getDeployerAddress();
            SymbioticCoreConstants.Core memory core = getCore();
            vm.broadcast();
            address networkImpl =
                address(new Network(address(core.networkRegistry), address(core.networkMiddlewareService)));
            config.set(
                "network",
                _deployContract(
                    NETWORK_SALT,
                    networkImpl,
                    abi.encodeCall(
                        INetwork.initialize,
                        (INetwork.NetworkInitParams({
                                globalMinDelay: 0,
                                delayParams: new INetwork.DelayParams[](0),
                                proposers: proposersAndExecutors,
                                executors: proposersAndExecutors,
                                name: "Example Network",
                                metadataURI: "https://example.network",
                                defaultAdminRoleHolder: getDeployerAddress(),
                                nameUpdateRoleHolder: getDeployerAddress(),
                                metadataURIUpdateRoleHolder: getDeployerAddress()
                            }))
                    ),
                    getDeployerAddress(),
                    false
                )
            );
        }
        return config.get("network").toAddress();
    }

    function _keyRegistryParams() internal override returns (address implementation, bytes memory initData) {
        vm.broadcast();
        implementation = address(new KeyRegistry());

        initData = abi.encodeCall(
            KeyRegistry.initialize,
            (IKeyRegistry.KeyRegistryInitParams({
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "KeyRegistry", version: "1"})
                }))
        );
    }

    function _votingPowerProviderParams() internal override returns (address implementation, bytes memory initData) {
        vm.startBroadcast();
        implementation = address(
            new VotingPowers(
                address(getCore().operatorRegistry),
                address(getCore().vaultFactory),
                address(getCore().vaultConfigurator)
            )
        );
        vm.stopBroadcast();

        initData = abi.encodeCall(
            VotingPowers.initialize,
            (
                IVotingPowerProvider.VotingPowerProviderInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: getNetwork(), subnetworkId: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "VotingPowers", version: "1"}),
                    requireSlasher: false,
                    minVaultEpochDuration: SLASHING_WINDOW,
                    token: getStakingToken()
                }),
                IOpNetVaultAutoDeploy.OpNetVaultAutoDeployInitParams({
                    isAutoDeployEnabled: true,
                    config: IOpNetVaultAutoDeploy.AutoDeployConfig({
                        epochDuration: SLASHING_WINDOW,
                        collateral: getStakingToken(),
                        burner: address(0),
                        withSlasher: true,
                        isBurnerHook: false
                    }),
                    isSetMaxNetworkLimitHookEnabled: true
                }),
                IOzOwnable.OzOwnableInitParams({owner: getDeployerAddress()})
            )
        );
    }

    function _settlementParams() internal override returns (address implementation, bytes memory initData) {
        vm.startBroadcast();
        implementation = address(new Settlement());

        address verifier;
        if (VERIFICATION_TYPE == 0) {
            address[] memory verifiers = new address[](3);
            verifiers[0] = deployCode("out/Verifier_10.sol/Verifier.json");
            verifiers[1] = deployCode("out/Verifier_100.sol/Verifier.json");
            verifiers[2] = deployCode("out/Verifier_1000.sol/Verifier.json");
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            verifier = address(new SigVerifierBlsBn254ZK(verifiers, maxValidators));
        } else if (VERIFICATION_TYPE == 1) {
            verifier = address(new SigVerifierBlsBn254Simple());
        } else {
            revert("Invalid verification type");
        }
        vm.stopBroadcast();
        initData = abi.encodeCall(
            Settlement.initialize,
            (
                ISettlement.SettlementInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: getNetwork(), subnetworkId: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Settlement", version: "1"}),
                    sigVerifier: verifier
                }),
                getDeployerAddress()
            )
        );
    }

    function _valSetDriverParams() internal override returns (address implementation, bytes memory initData) {
        vm.broadcast();
        implementation = address(new Driver());

        IValSetDriver.QuorumThreshold[] memory quorumThresholds = new IValSetDriver.QuorumThreshold[](3);
        quorumThresholds[0] =
            IValSetDriver.QuorumThreshold({keyTag: REQUIRED_KEY_TAG, quorumThreshold: QUORUM_THRESHOLD});
        quorumThresholds[1] =
            IValSetDriver.QuorumThreshold({keyTag: REQUIRED_KEY_TAG_ECDSA, quorumThreshold: QUORUM_THRESHOLD});
        quorumThresholds[2] =
            IValSetDriver.QuorumThreshold({keyTag: REQUIRED_KEY_TAG_SECONDARY_BLS, quorumThreshold: QUORUM_THRESHOLD});
        uint8[] memory requiredKeyTags = new uint8[](3);
        requiredKeyTags[0] = REQUIRED_KEY_TAG;
        requiredKeyTags[1] = REQUIRED_KEY_TAG_ECDSA;
        requiredKeyTags[2] = REQUIRED_KEY_TAG_SECONDARY_BLS;
        initData = abi.encodeCall(
            Driver.initialize,
            (
                IValSetDriver.ValSetDriverInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: getNetwork(), subnetworkId: 0
                    }),
                    epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                        epochDuration: EPOCH_DURATION, epochDurationTimestamp: 0
                    }),
                    numAggregators: NUM_AGGREGATORS,
                    numCommitters: NUM_COMMITTERS,
                    votingPowerProviders: getVotingPowerProviders(),
                    keysProvider: getKeyRegistry(),
                    settlements: getSettlements(),
                    maxVotingPower: MAX_VOTING_POWER,
                    minInclusionVotingPower: MIN_INCLUSION_VOTING_POWER,
                    maxValidatorsCount: MAX_VALIDATORS_COUNT,
                    requiredKeyTags: requiredKeyTags,
                    quorumThresholds: quorumThresholds,
                    requiredHeaderKeyTag: REQUIRED_KEY_TAG,
                    verificationType: VERIFICATION_TYPE
                }),
                getDeployerAddress()
            )
        );
    }

    function runDeployKeyRegistry() public override {
        deployKeyRegistry({proxyOwner: getDeployerAddress(), isDeployerGuarded: false, salt: KEY_REGISTRY_SALT});

        fundOperators();
        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            configureOperatorKeys(i);
        }
    }

    function runDeployVotingPowerProvider() public override {
        address votingPowerProvider = deployVotingPowerProvider({
            proxyOwner: getDeployerAddress(), isDeployerGuarded: false, salt: VOTING_POWER_PROVIDER_SALT
        });
        address network = getNetwork();
        SymbioticCoreConstants.Core memory core = getCore();
        vm.startBroadcast(getDeployerAddress());
        Network(payable(network))
            .schedule(
                address(core.networkMiddlewareService),
                0,
                abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, votingPowerProvider),
                bytes32(0),
                bytes32(0),
                0
            );
        Network(payable(network))
            .execute(
                address(core.networkMiddlewareService),
                0,
                abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, votingPowerProvider),
                bytes32(0),
                bytes32(0)
            );
        vm.stopBroadcast();

        fundOperators();
        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            registerOperator(i, OPERATOR_STAKE_AMOUNT);
        }
        printOperatorsInfo();
    }

    function runDeploySettlement() public override {
        address settlement =
            deploySettlement({proxyOwner: getDeployerAddress(), isDeployerGuarded: false, salt: SETTLEMENT_SALT});
        vm.broadcast();
        address sumTask =
            deployCreate3(bytes32(SUM_TASK_SALT), abi.encodePacked(type(SumTask).creationCode, abi.encode(settlement)));
        config.set("sum_task", sumTask);

        fundOperators();
    }

    function runDeployValSetDriver() public override {
        deployValSetDriver({proxyOwner: getDeployerAddress(), isDeployerGuarded: false, salt: VALSET_DRIVER_SALT});
        vm.writeJson("", "temp-network/deploy-data/deployment-completed.json");
    }

    function configureOperatorKeys(uint256 index) public {
        Vm.Wallet memory operator = getOperator(index);
        (BN254.G1Point memory g1Key, BN254.G2Point memory g2Key) = getBLSKeys(operator.privateKey);
        KeyRegistry keyRegistry = KeyRegistry(getKeyRegistry().addr);

        vm.startBroadcast(operator.privateKey);
        bytes memory keyBytes = KeyBlsBn254.wrap(g1Key).toBytes();
        bytes32 messageHash = keyRegistry.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
        BN254.G1Point memory sigG1 = messageG1.scalar_mul(operator.privateKey);
        keyRegistry.setKey(KEY_TYPE_BLS_BN254.getKeyTag(15), keyBytes, abi.encode(sigG1), abi.encode(g2Key));

        // Register BLS-BN254 key with tag 11, not related to header key tag
        uint256 secondaryBLSKey = operator.privateKey + 10_000;
        (g1Key, g2Key) = getBLSKeys(secondaryBLSKey);
        keyBytes = KeyBlsBn254.wrap(g1Key).toBytes();
        messageHash = keyRegistry.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        messageG1 = BN254.hashToG1(messageHash);
        sigG1 = messageG1.scalar_mul(secondaryBLSKey);

        keyRegistry.setKey(KEY_TYPE_BLS_BN254.getKeyTag(11), keyBytes, abi.encode(sigG1), abi.encode(g2Key));

        keyBytes = KeyEcdsaSecp256k1.wrap(operator.addr).toBytes();
        messageHash = keyRegistry.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator.privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Register ECDSA key
        keyRegistry.setKey(KEY_TYPE_ECDSA_SECP256K1.getKeyTag(0), keyBytes, signature, new bytes(0));
        vm.stopBroadcast();
    }

    function registerOperator(uint256 index, uint256 stakeAmount) public {
        Vm.Wallet memory operator = getOperator(index);
        IERC20 stakingToken = IERC20(getStakingToken());
        VotingPowers votingPowers = VotingPowers(getVotingPowerProvider());

        vm.broadcast();
        stakingToken.transfer(operator.addr, stakeAmount);

        vm.startBroadcast(operator.privateKey);
        getCore().operatorRegistry.registerOperator();
        getCore().operatorNetworkOptInService.optIn(address(getNetwork()));
        votingPowers.registerOperator();
        IVault vault = IVault(votingPowers.getAutoDeployedVault(operator.addr));
        getCore().operatorVaultOptInService.optIn(address(vault));

        stakingToken.approve(address(vault), stakeAmount);
        vault.deposit(address(stakingToken), stakeAmount);
        vm.stopBroadcast();
    }

    function fundOperators() public {
        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            vm.broadcast();
            payable(operator.addr).transfer(1 ether);
        }
    }

    function getOperator(uint256 index) public returns (VmSafe.Wallet memory operator) {
        // deterministic operator private key
        operator = vm.createWallet(1e18 + index);
        vm.rememberKey(operator.privateKey);
        return operator;
    }

    function getBLSKeys(uint256 privateKey) public returns (BN254.G1Point memory, BN254.G2Point memory) {
        BN254.G1Point memory G1Key = BN254.generatorG1().scalar_mul(privateKey);
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return (G1Key, BN254.G2Point([x2, x1], [y2, y1]));
    }

    function printOperatorsInfo() public {
        VotingPowers votingPowers = VotingPowers(getVotingPowerProvider());
        address[] memory operators = votingPowers.getOperators();
        VotingPowers.OperatorVotingPower[] memory operatorVPs = votingPowers.getVotingPowers(new bytes[](0));

        string memory logMessage =
            string.concat("Operators total: ", vm.toString(operators.length), "\n", "Operators:\n");

        for (uint256 i; i < operatorVPs.length; ++i) {
            uint256 totalVotingPower;
            logMessage =
                string.concat(logMessage, "   Address: ", vm.toString(operatorVPs[i].operator), "\n", "   Vaults:\n");
            for (uint256 j; j < operatorVPs[i].vaults.length; ++j) {
                logMessage = string.concat(
                    logMessage,
                    "       Address: ",
                    vm.toString(operatorVPs[i].vaults[j].vault),
                    "\n",
                    "       Voting power: ",
                    vm.toString(operatorVPs[i].vaults[j].value),
                    "\n"
                );
                totalVotingPower += operatorVPs[i].vaults[j].value;
            }
            logMessage = string.concat(logMessage, "   Total voting power: ", vm.toString(totalVotingPower), "\n");
        }

        Logs.log(logMessage);
    }
}
