// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {SymbioticCoreConstants} from "@symbioticfi/core-contracts/test/integration/SymbioticCoreConstants.sol";
import {SymbioticCoreInit} from "@symbioticfi/core-contracts/script/integration/SymbioticCoreInit.sol";
import {IVault} from "@symbioticfi/core-contracts/src/interfaces/vault/IVault.sol";
import {INetworkMiddlewareService} from
    "@symbioticfi/core-contracts/src/interfaces/service/INetworkMiddlewareService.sol";
import {Logs} from "@symbioticfi/core/script/utils/Logs.sol";
import "@symbioticfi/core-contracts/test/integration/SymbioticCoreImports.sol";

import {INetworkManager} from "@symbioticfi/relay-contracts/interfaces/modules/base/INetworkManager.sol";
import {IKeyRegistry} from "@symbioticfi/relay-contracts/interfaces/modules/key-registry/IKeyRegistry.sol";
import {IEpochManager} from "@symbioticfi/relay-contracts/interfaces/modules/valset-driver/IEpochManager.sol";
import {IValSetDriver} from "@symbioticfi/relay-contracts/interfaces/modules/valset-driver/IValSetDriver.sol";
import {IVotingPowerProvider} from
    "@symbioticfi/relay-contracts/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOpNetVaultAutoDeploy} from
    "@symbioticfi/relay-contracts/interfaces/modules/voting-power/extensions/IOpNetVaultAutoDeploy.sol";
import {SigVerifierBlsBn254ZK} from
    "@symbioticfi/relay-contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";
import {SigVerifierBlsBn254Simple} from
    "@symbioticfi/relay-contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {ISettlement} from "@symbioticfi/relay-contracts/interfaces/modules/settlement/ISettlement.sol";
import {IOzOwnable} from "@symbioticfi/relay-contracts/interfaces/modules/common/permissions/IOzOwnable.sol";
import {IOzEIP712} from "@symbioticfi/relay-contracts/interfaces/modules/base/IOzEIP712.sol";
import {KeyTags} from "@symbioticfi/relay-contracts/libraries/utils/KeyTags.sol";
import {KeyBlsBn254, BN254} from "@symbioticfi/relay-contracts/libraries/keys/KeyBlsBn254.sol";
import {KeyEcdsaSecp256k1} from "@symbioticfi/relay-contracts/libraries/keys/KeyEcdsaSecp256k1.sol";
import {
    KEY_TYPE_BLS_BN254,
    KEY_TYPE_ECDSA_SECP256K1
} from "@symbioticfi/relay-contracts/interfaces/modules/key-registry/IKeyRegistry.sol";

import {RelayDeploy} from "lib/relay-contracts-new/script/deploy/RelayDeploy.sol";

import {Network} from "@symbioticfi/network/src/Network.sol";
import {INetwork} from "@symbioticfi/network/src/interfaces/INetwork.sol";

import {BN254G2} from "./utils/BN254G2.sol";
import {MockERC20} from "./mock/MockERC20.sol";

import {KeyRegistry} from "../src/symbiotic/KeyRegistry.sol";
import {Driver} from "../src/symbiotic/Driver.sol";
import {VotingPowers} from "../src/symbiotic/VotingPowers.sol";
import {Settlement} from "../src/symbiotic/Settlement.sol";
import {SumTask} from "../src/SumTask.sol";

contract DeployAllScript is SymbioticCoreInit, RelayDeploy {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using KeyEcdsaSecp256k1 for address;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using KeyEcdsaSecp256k1 for bytes;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

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
    bytes11 public constant NETWORK_SALT = bytes11("Network1");
    bytes11 public constant SUM_TASK_SALT = bytes11("SumTask");
    bytes11 public constant STAKING_TOKEN_SALT = bytes11("StToken");

    address internal deployer;
    uint256 internal operatorsCount;

    function getDeployerAddress() internal view returns (address) {
        // if DEPLOYER_ADDRESS is not set, use the default deployer address
        return vm.envOr("DEPLOYER_ADDRESS", 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    modifier setUp() {
        deployer = getDeployerAddress();
        SYMBIOTIC_CORE_PROJECT_ROOT = "node_modules/@symbioticfi/core/";
        if (block.chainid == 31_337 || block.chainid == 31_338) {
            symbioticCore = getAnvilCoreAddresses();
        } else {
            _initCore_SymbioticCore();
        }
        _;
    }

    function deployStakingToken() public setUp {
        vm.startBroadcast(deployer);
        address implementation = address(new MockERC20("StakingToken", "STK"));
        _deployContract(STAKING_TOKEN_SALT, implementation, new bytes(0), deployer, false, "StakingToken");
        vm.stopBroadcast();
    }

    function deployNetwork() public setUp {
        vm.startBroadcast(deployer);
        (address implementation, bytes memory initData) = _networkParams();
        _deployContract(NETWORK_SALT, implementation, initData, deployer, false, "Network");
        vm.stopBroadcast();
    }

    function deployVotingPowerProvider(
        IValSetDriver.CrossChainAddress memory network,
        IValSetDriver.CrossChainAddress memory stakingToken
    ) public setUp {
        vm.startBroadcast(deployer);
        (address implementation, bytes memory initData) = _votingPowerProviderParams(network, stakingToken);
        vm.stopBroadcast();
        address votingPowerProvider = super.deployVotingPowerProvider(deployer, false, implementation, initData);

        vm.startBroadcast(deployer);
        Network(payable(network.addr)).schedule(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, votingPowerProvider),
            bytes32(0),
            bytes32(0),
            0
        );

        Network(payable(network.addr)).execute(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, votingPowerProvider),
            bytes32(0),
            bytes32(0)
        );
        vm.stopBroadcast();
    }

    function deployKeyRegistry() public setUp {
        vm.startBroadcast(deployer);
        (address implementation, bytes memory initData) = _keyRegistryParams();
        vm.stopBroadcast();
        super.deployKeyRegistry(deployer, false, implementation, initData);
    }

    function deploySettlement(
        IValSetDriver.CrossChainAddress[] memory networks
    ) public setUp {
        vm.startBroadcast(deployer);
        (address implementation, bytes memory initData) = _settlementParams(networks[0]);
        vm.stopBroadcast();
        super.deploySettlement(deployer, false, implementation, initData);
    }

    function deployValSetDriver(
        IValSetDriver.CrossChainAddress memory network,
        IValSetDriver.CrossChainAddress memory keyRegistry,
        IValSetDriver.CrossChainAddress[] memory settlements,
        IValSetDriver.CrossChainAddress[] memory votingPowerProviders
    ) public setUp {
        vm.startBroadcast(deployer);
        (address implementation, bytes memory initData) =
            _valSetDriverParams(network, keyRegistry, settlements, votingPowerProviders);
        vm.stopBroadcast();
        super.deployValSetDriver(deployer, false, implementation, initData);
    }

    function deploySumTask(
        IValSetDriver.CrossChainAddress memory settlement
    ) public setUp {
        vm.startBroadcast(deployer);
        address implementation = address(new SumTask(address(settlement.addr)));
        _deployContract(SUM_TASK_SALT, implementation, "", deployer, false, "SumTask");
        vm.stopBroadcast();
    }

    function addOperators(
        IValSetDriver.CrossChainAddress memory network,
        IValSetDriver.CrossChainAddress memory keyRegistry,
        IValSetDriver.CrossChainAddress memory stakingToken,
        IValSetDriver.CrossChainAddress memory votingPowerProvider
    ) public setUp {
        vm.startBroadcast(deployer);
        MockERC20(stakingToken.addr).mint(deployer, OPERATOR_STAKE_AMOUNT * OPERATOR_COUNT);
        vm.stopBroadcast();

        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            _addOperator(OPERATOR_STAKE_AMOUNT, network, keyRegistry, stakingToken, votingPowerProvider);
        }
    }

    function _networkParams() internal returns (address implementation, bytes memory initData) {
        implementation = address(
            new Network(address(symbioticCore.networkRegistry), address(symbioticCore.networkMiddlewareService))
        );

        address[] memory proposersAndExecutors = new address[](1);
        proposersAndExecutors[0] = deployer;
        initData = abi.encodeCall(
            INetwork.initialize,
            (
                INetwork.NetworkInitParams({
                    globalMinDelay: 0,
                    delayParams: new INetwork.DelayParams[](0),
                    proposers: proposersAndExecutors,
                    executors: proposersAndExecutors,
                    name: "Example Network",
                    metadataURI: "https://example.network",
                    defaultAdminRoleHolder: deployer,
                    nameUpdateRoleHolder: deployer,
                    metadataURIUpdateRoleHolder: deployer
                })
            )
        );
    }

    function _keyRegistryParams() internal returns (address implementation, bytes memory initData) {
        // Deploy implementation
        implementation = address(new KeyRegistry());

        // Create initialization data
        initData = abi.encodeCall(
            KeyRegistry.initialize,
            (
                IKeyRegistry.KeyRegistryInitParams({
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "KeyRegistry", version: "1"})
                })
            )
        );
    }

    function _votingPowerProviderParams(
        IValSetDriver.CrossChainAddress memory network,
        IValSetDriver.CrossChainAddress memory stakingToken
    ) internal returns (address implementation, bytes memory initData) {
        // Deploy implementation
        implementation = address(
            new VotingPowers(
                address(symbioticCore.operatorRegistry),
                address(symbioticCore.vaultFactory),
                address(symbioticCore.vaultConfigurator)
            )
        );

        // Create initialization data
        initData = abi.encodeCall(
            VotingPowers.initialize,
            (
                IVotingPowerProvider.VotingPowerProviderInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: network.addr,
                        subnetworkId: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "VotingPowers", version: "1"}),
                    requireSlasher: false,
                    minVaultEpochDuration: SLASHING_WINDOW,
                    token: stakingToken.addr
                }),
                IOpNetVaultAutoDeploy.OpNetVaultAutoDeployInitParams({
                    isAutoDeployEnabled: true,
                    config: IOpNetVaultAutoDeploy.AutoDeployConfig({
                        epochDuration: SLASHING_WINDOW,
                        collateral: stakingToken.addr,
                        burner: address(0),
                        withSlasher: true,
                        isBurnerHook: false
                    }),
                    isSetMaxNetworkLimitHookEnabled: true
                }),
                IOzOwnable.OzOwnableInitParams({owner: deployer})
            )
        );
    }

    function _settlementParams(
        IValSetDriver.CrossChainAddress memory network
    ) internal returns (address implementation, bytes memory initData) {
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

        // Deploy implementation
        implementation = address(new Settlement());

        // Create initialization data
        initData = abi.encodeCall(
            Settlement.initialize,
            (
                ISettlement.SettlementInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: network.addr,
                        subnetworkId: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Settlement", version: "1"}),
                    sigVerifier: verifier
                }),
                deployer
            )
        );
    }

    function _valSetDriverParams(
        IValSetDriver.CrossChainAddress memory network,
        IValSetDriver.CrossChainAddress memory keyRegistry,
        IValSetDriver.CrossChainAddress[] memory settlements,
        IValSetDriver.CrossChainAddress[] memory votingPowerProviders
    ) internal returns (address implementation, bytes memory initData) {
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

        // Deploy implementation
        implementation = address(new Driver());

        // Create initialization data
        initData = abi.encodeCall(
            Driver.initialize,
            (
                IValSetDriver.ValSetDriverInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: network.addr,
                        subnetworkId: 0
                    }),
                    epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                        epochDuration: EPOCH_DURATION,
                        epochDurationTimestamp: 0
                    }),
                    numAggregators: NUM_AGGREGATORS,
                    numCommitters: NUM_COMMITTERS,
                    votingPowerProviders: votingPowerProviders,
                    keysProvider: keyRegistry,
                    settlements: settlements,
                    maxVotingPower: MAX_VOTING_POWER,
                    minInclusionVotingPower: MIN_INCLUSION_VOTING_POWER,
                    maxValidatorsCount: MAX_VALIDATORS_COUNT,
                    requiredKeyTags: requiredKeyTags,
                    quorumThresholds: quorumThresholds,
                    requiredHeaderKeyTag: REQUIRED_KEY_TAG,
                    verificationType: VERIFICATION_TYPE
                }),
                deployer
            )
        );
    }

    function _addOperator(
        uint256 stakeAmount,
        IValSetDriver.CrossChainAddress memory network_,
        IValSetDriver.CrossChainAddress memory keyRegistry,
        IValSetDriver.CrossChainAddress memory stakingToken_,
        IValSetDriver.CrossChainAddress memory votingPowerProvider
    ) internal {
        Vm.Wallet memory operator = getOperator(operatorsCount);
        (BN254.G1Point memory g1Key, BN254.G2Point memory g2Key) = getBLSKeys(operator.privateKey);
        KeyRegistry keyRegistry_ = KeyRegistry(keyRegistry.addr);
        IERC20 stakingToken = IERC20(stakingToken_.addr);
        VotingPowers votingPowers = VotingPowers(votingPowerProvider.addr);

        vm.startBroadcast(deployer);
        payable(operator.addr).transfer(1 ether);
        stakingToken.transfer(operator.addr, stakeAmount);
        vm.stopBroadcast();

        vm.startBroadcast(operator.privateKey);

        symbioticCore.operatorRegistry.registerOperator();
        symbioticCore.operatorNetworkOptInService.optIn(network_.addr);
        votingPowers.registerOperator();
        IVault vault = IVault(votingPowers.getAutoDeployedVault(operator.addr));
        symbioticCore.operatorVaultOptInService.optIn(address(vault));

        stakingToken.approve(address(vault), stakeAmount);
        vault.deposit(address(stakingToken), stakeAmount);

        bytes memory keyBytes = KeyBlsBn254.wrap(g1Key).toBytes();
        bytes32 messageHash = keyRegistry_.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
        BN254.G1Point memory sigG1 = messageG1.scalar_mul(operator.privateKey);
        keyRegistry_.setKey(KEY_TYPE_BLS_BN254.getKeyTag(15), keyBytes, abi.encode(sigG1), abi.encode(g2Key));

        // Register BLS-BN254 key with tag 11, not related to header key tag
        uint256 secondaryBLSKey = operator.privateKey + 10_000;
        (g1Key, g2Key) = getBLSKeys(secondaryBLSKey);
        keyBytes = KeyBlsBn254.wrap(g1Key).toBytes();
        messageHash = keyRegistry_.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        messageG1 = BN254.hashToG1(messageHash);
        sigG1 = messageG1.scalar_mul(secondaryBLSKey);

        keyRegistry_.setKey(KEY_TYPE_BLS_BN254.getKeyTag(11), keyBytes, abi.encode(sigG1), abi.encode(g2Key));

        vm.stopBroadcast();

        // Generate ECDSA key
        keyBytes = KeyEcdsaSecp256k1.wrap(operator.addr).toBytes();

        vm.startBroadcast(operator.privateKey);
        // Create ECDSA signature for key ownership
        messageHash = keyRegistry_.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator.privateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Register ECDSA key
        keyRegistry_.setKey(KEY_TYPE_ECDSA_SECP256K1.getKeyTag(0), keyBytes, signature, new bytes(0));

        vm.stopBroadcast();

        operatorsCount++;
        Logs.log(
            string.concat(
                "Operator added:\n",
                "   Address: ",
                vm.toString(operator.addr),
                "\n",
                "   PrivateKey: ",
                vm.toString(operator.privateKey),
                "\n",
                "   Vault: ",
                vm.toString(address(vault)),
                "\n",
                "   Stake: ",
                vm.toString(stakeAmount)
            )
        );
    }

    function getOperator(
        uint256 index
    ) public returns (Vm.Wallet memory operator) {
        // deterministic operator private key
        operator = vm.createWallet(1e18 + index);
        vm.rememberKey(operator.privateKey);
        return operator;
    }

    function getBLSKeys(
        uint256 privateKey
    ) public view returns (BN254.G1Point memory, BN254.G2Point memory) {
        BN254.G1Point memory G1Key = BN254.generatorG1().scalar_mul(privateKey);
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return (G1Key, BN254.G2Point([x2, x1], [y2, y1]));
    }

    function getAnvilCoreAddresses() public pure returns (SymbioticCoreConstants.Core memory) {
        return SymbioticCoreConstants.Core({
            vaultFactory: ISymbioticVaultFactory(0xaE3C829999fA9388e1264E157404FAe5c1b880C8),
            delegatorFactory: ISymbioticDelegatorFactory(0xb1aA5541A34c4794C3dE52231FcE903a1E54A7dd),
            slasherFactory: ISymbioticSlasherFactory(0x7fEB506213009125074D9BBEea8be738C61de716),
            networkRegistry: ISymbioticNetworkRegistry(0x438148B0C8B40E7f30Db2bAD54661a86330f9a62),
            operatorRegistry: ISymbioticOperatorRegistry(0xDA7E0E78EB9A25Ecc67327544dD630A5462DB9d3),
            operatorMetadataService: ISymbioticMetadataService(0xA6B0676438b825dB6B4D5978a84a7953e4340D4C),
            networkMetadataService: ISymbioticMetadataService(0x15437f07dB4a8ad2518777882aE7Fa661498C0f5),
            networkMiddlewareService: ISymbioticNetworkMiddlewareService(0xb1B4d167d495Bc71Cd7470Aba423ab6ae01524eB),
            operatorVaultOptInService: ISymbioticOptInService(0x4CD855f783d0Ac63c047E062639a30A9a0bCE58f),
            operatorNetworkOptInService: ISymbioticOptInService(0x29c87b66a71469ffc309738B11a66DccEE0D32BF),
            vaultConfigurator: ISymbioticVaultConfigurator(0x9EA698343A31199b843fc77F9e2945c7D13FB734)
        });
    }
}
