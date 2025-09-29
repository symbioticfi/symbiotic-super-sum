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

import {BN254G2} from "./utils/BN254G2.sol";
import {MockERC20} from "./mock/MockERC20.sol";

import {Network} from "@symbioticfi/relay-contracts/modules/network/Network.sol";
import {KeyRegistry} from "../src/symbiotic/KeyRegistry.sol";
import {Driver} from "../src/symbiotic/Driver.sol";
import {VotingPowers} from "../src/symbiotic/VotingPowers.sol";
import {Settlement} from "../src/symbiotic/Settlement.sol";
import {SumTask} from "../src/SumTask.sol";

contract LocalDeploy is SymbioticCoreInit {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using KeyEcdsaSecp256k1 for address;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using KeyEcdsaSecp256k1 for bytes;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct CrossChainAddress {
        address addr;
        uint64 chainId;
    }

    struct RelayContracts {
        CrossChainAddress driver;
        CrossChainAddress keyRegistry;
        address network;
        CrossChainAddress[] settlements;
        CrossChainAddress[] stakingTokens;
        CrossChainAddress[] votingPowerProviders;
    }

    struct SumTaskContracts {
        CrossChainAddress[] sumTasks;
    }

    bytes32 internal constant KEY_OWNERSHIP_TYPEHASH = keccak256("KeyOwnership(address operator,bytes key)");

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

    address internal deployer;

    Network internal network;
    IValSetDriver.CrossChainAddress internal keyRegistry;
    IValSetDriver.CrossChainAddress internal driver;
    EnumerableMap.UintToAddressMap internal stakingTokens;
    EnumerableMap.UintToAddressMap internal votingPowerProviders;
    EnumerableMap.UintToAddressMap internal settlements;

    EnumerableMap.UintToAddressMap internal sumTasks;

    uint256 internal operatorsCount;

    function getDeployerAddress() internal view returns (address) {
        // if DEPLOYER_ADDRESS is not set, use the default deployer address
        return vm.envOr("DEPLOYER_ADDRESS", 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function run() public virtual {
        deployer = getDeployerAddress();

        SYMBIOTIC_CORE_PROJECT_ROOT = "node_modules/@symbioticfi/core/";

        setupCore();

        setupStakingToken();
        setupNetwork();
        setupKeyRegistry();
        setupVotingPowers();
        setupSettlement();
        logAndDumpRelayContracts();

        setupSumTask();
        logAndDumpSumTaskContracts();

        for (uint256 i; i < OPERATOR_COUNT; ++i) {
            addOperator(OPERATOR_STAKE_AMOUNT);
        }
        printOperatorsInfo();
    }

    function setupCore() public {
        vm.startBroadcast(deployer);
        _initCore_SymbioticCore(false);
        vm.stopBroadcast();

        console.log("Symbiotic Core contracts:");
        console.log("   VaultFactory:", address(symbioticCore.vaultFactory));
        console.log("   DelegatorFactory:", address(symbioticCore.delegatorFactory));
        console.log("   SlasherFactory:", address(symbioticCore.slasherFactory));
        console.log("   NetworkRegistry:", address(symbioticCore.networkRegistry));
        console.log("   NetworkMetadataService:", address(symbioticCore.networkMetadataService));
        console.log("   NetworkMiddlewareService:", address(symbioticCore.networkMiddlewareService));
        console.log("   OperatorRegistry:", address(symbioticCore.operatorRegistry));
        console.log("   OperatorMetadataService:", address(symbioticCore.operatorMetadataService));
        console.log("   OperatorVaultOptInService:", address(symbioticCore.operatorVaultOptInService));
        console.log("   OperatorNetworkOptInService:", address(symbioticCore.operatorNetworkOptInService));
        console.log("   VaultConfigurator:", address(symbioticCore.vaultConfigurator));
    }

    function setupStakingToken() public returns (IValSetDriver.CrossChainAddress memory) {
        vm.startBroadcast(deployer);
        MockERC20 stakingToken = new MockERC20("StakingToken", "STK");
        stakingTokens.set(block.chainid, address(stakingToken));
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(stakingToken)});
    }

    function setupNetwork() public returns (address) {
        vm.startBroadcast(deployer);
        network = new Network(address(symbioticCore.networkRegistry), address(symbioticCore.networkMiddlewareService));
        address[] memory proposersAndExecutors = new address[](1);
        proposersAndExecutors[0] = deployer;

        network.initialize(
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
        );
        vm.stopBroadcast();

        return address(network);
    }

    function setupKeyRegistry() public returns (IValSetDriver.CrossChainAddress memory) {
        vm.startBroadcast(deployer);
        KeyRegistry keyRegistry_ = new KeyRegistry{salt: "KeyRegistry"}();
        keyRegistry_.initialize(
            IKeyRegistry.KeyRegistryInitParams({
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "KeyRegistry", version: "1"})
            })
        );
        keyRegistry = IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(keyRegistry_)});
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(keyRegistry_)});
    }

    function setupVotingPowers() public returns (IValSetDriver.CrossChainAddress memory) {
        IERC20 stakingToken = IERC20(stakingTokens.get(block.chainid));

        vm.startBroadcast(deployer);
        VotingPowers votingPowers_ = new VotingPowers{salt: "VotingPowers"}(
            address(symbioticCore.operatorRegistry),
            address(symbioticCore.vaultFactory),
            address(symbioticCore.vaultConfigurator)
        );
        votingPowers_.initialize(
            IVotingPowerProvider.VotingPowerProviderInitParams({
                networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                    network: address(network),
                    subnetworkId: 0
                }),
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "VotingPowers", version: "1"}),
                requireSlasher: false,
                minVaultEpochDuration: SLASHING_WINDOW,
                token: address(stakingToken)
            }),
            IOpNetVaultAutoDeploy.OpNetVaultAutoDeployInitParams({
                isAutoDeployEnabled: true,
                config: IOpNetVaultAutoDeploy.AutoDeployConfig({
                    epochDuration: SLASHING_WINDOW,
                    collateral: address(stakingToken),
                    burner: address(0),
                    withSlasher: true,
                    isBurnerHook: false
                }),
                isSetMaxNetworkLimitHookEnabled: true
            }),
            IOzOwnable.OzOwnableInitParams({owner: deployer})
        );

        network.schedule(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, address(votingPowers_)),
            bytes32(0),
            bytes32(0),
            0
        );

        network.execute(
            address(symbioticCore.networkMiddlewareService),
            0,
            abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, address(votingPowers_)),
            bytes32(0),
            bytes32(0)
        );
        votingPowerProviders.set(block.chainid, address(votingPowers_));
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(votingPowers_)});
    }

    function setupSettlement() public returns (IValSetDriver.CrossChainAddress memory) {
        vm.startBroadcast(deployer);
        Settlement settlement_ = new Settlement{salt: "Settlement"}();

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

        settlement_.initialize(
            ISettlement.SettlementInitParams({
                networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                    network: address(network),
                    subnetworkId: 0
                }),
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Settlement", version: "1"}),
                sigVerifier: verifier
            }),
            deployer
        );
        settlements.set(block.chainid, address(settlement_));
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(settlement_)});
    }

    function setupDriver() public returns (IValSetDriver.CrossChainAddress memory) {
        vm.startBroadcast(deployer);
        Driver driver_ = new Driver{salt: "Driver"}();

        IValSetDriver.CrossChainAddress[] memory votingPowerProviders_ =
            new IValSetDriver.CrossChainAddress[](votingPowerProviders.length());
        for (uint256 i; i < votingPowerProviders.length(); ++i) {
            (uint256 chainId, address votingPowerProvider) = votingPowerProviders.at(i);
            votingPowerProviders_[i] =
                IValSetDriver.CrossChainAddress({chainId: uint64(chainId), addr: votingPowerProvider});
        }
        IValSetDriver.CrossChainAddress[] memory settlementsLocal =
            new IValSetDriver.CrossChainAddress[](settlements.length());
        for (uint256 i; i < settlements.length(); ++i) {
            (uint256 chainId, address settlement) = settlements.at(i);
            settlementsLocal[i] = IValSetDriver.CrossChainAddress({chainId: uint64(chainId), addr: settlement});
        }
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

        driver_.initialize(
            IValSetDriver.ValSetDriverInitParams({
                networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                    network: address(network),
                    subnetworkId: 0
                }),
                epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                    epochDuration: EPOCH_DURATION,
                    epochDurationTimestamp: 0
                }),
                numAggregators: NUM_AGGREGATORS,
                numCommitters: NUM_COMMITTERS,
                votingPowerProviders: votingPowerProviders_,
                keysProvider: keyRegistry,
                settlements: settlementsLocal,
                maxVotingPower: MAX_VOTING_POWER,
                minInclusionVotingPower: MIN_INCLUSION_VOTING_POWER,
                maxValidatorsCount: MAX_VALIDATORS_COUNT,
                requiredKeyTags: requiredKeyTags,
                quorumThresholds: quorumThresholds,
                requiredHeaderKeyTag: REQUIRED_KEY_TAG,
                verificationType: VERIFICATION_TYPE
            }),
            deployer
        );
        driver = IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(driver_)});
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(driver_)});
    }

    function setupSumTask() public returns (IValSetDriver.CrossChainAddress memory) {
        vm.startBroadcast(deployer);
        SumTask sumTask = new SumTask(address(settlements.get(block.chainid)));
        sumTasks.set(block.chainid, address(sumTask));
        vm.stopBroadcast();

        return IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(sumTask)});
    }

    function logAndDumpRelayContracts() public {
        console.log("Symbiotic Relay contracts:");
        console.log("   Network:", address(network));
        console.log("   KeyRegistry (chainId:", keyRegistry.chainId, "):", keyRegistry.addr);
        console.log("   Driver (chainId:", driver.chainId, "):", driver.addr);
        for (uint256 i; i < stakingTokens.length(); ++i) {
            (uint256 chainId, address stakingToken) = stakingTokens.at(i);
            console.log("   StakingToken (chainId:", chainId, "):", stakingToken);
        }
        for (uint256 i; i < votingPowerProviders.length(); ++i) {
            (uint256 chainId, address votingPowerProvider) = votingPowerProviders.at(i);
            console.log("   VotingPowers (chainId:", chainId, "):", votingPowerProvider);
        }
        for (uint256 i; i < settlements.length(); ++i) {
            (uint256 chainId, address settlement) = settlements.at(i);
            console.log("   Settlement (chainId:", chainId, "):", settlement);
        }

        string memory obj = "relayContracts";

        vm.serializeAddress(obj, "network", address(network));

        vm.serializeUint("keyRegistry", "chainId", keyRegistry.chainId);
        string memory keyRegistryData = vm.serializeAddress("keyRegistry", "addr", keyRegistry.addr);
        vm.serializeString(obj, "keyRegistry", keyRegistryData);

        vm.serializeUint("driver", "chainId", driver.chainId);
        string memory driverData = vm.serializeAddress("driver", "addr", driver.addr);
        vm.serializeString(obj, "driver", driverData);

        string[] memory stakingTokensData = new string[](stakingTokens.length());
        for (uint256 i; i < stakingTokens.length(); ++i) {
            (uint256 chainId, address stakingToken) = stakingTokens.at(i);
            vm.serializeUint("stakingToken", "chainId", chainId);
            string memory stakingTokenData = vm.serializeAddress("stakingToken", "addr", stakingToken);
            stakingTokensData[i] = stakingTokenData;
        }
        vm.serializeString(obj, "stakingTokens", stakingTokensData);

        string[] memory votingPowerProvidersData = new string[](votingPowerProviders.length());
        for (uint256 i; i < votingPowerProviders.length(); ++i) {
            (uint256 chainId, address votingPowerProvider) = votingPowerProviders.at(i);
            vm.serializeUint("votingPowerProvider", "chainId", chainId);
            string memory votingPowerProviderData =
                vm.serializeAddress("votingPowerProvider", "addr", votingPowerProvider);
            votingPowerProvidersData[i] = votingPowerProviderData;
        }
        vm.serializeString(obj, "votingPowerProviders", votingPowerProvidersData);

        string[] memory settlementsData = new string[](settlements.length());
        for (uint256 i; i < settlements.length(); ++i) {
            (uint256 chainId, address settlement) = settlements.at(i);
            vm.serializeUint("settlement", "chainId", chainId);
            string memory settlementData = vm.serializeAddress("settlement", "addr", settlement);
            settlementsData[i] = settlementData;
        }
        string memory finalJson = vm.serializeString(obj, "settlements", settlementsData);

        vm.writeJson(finalJson, "temp-network/deploy-data/relay_contracts.json");
    }

    function logAndDumpSumTaskContracts() public {
        console.log("SumTask contracts:");
        for (uint256 i; i < sumTasks.length(); ++i) {
            (uint256 chainId, address sumTask) = sumTasks.at(i);
            console.log("   SumTask (chainId:", chainId, "):", sumTask);
        }

        string memory obj = "sumTaskContracts";

        string[] memory sumTasksData = new string[](sumTasks.length());
        for (uint256 i; i < sumTasks.length(); ++i) {
            (uint256 chainId, address sumTask) = sumTasks.at(i);
            vm.serializeUint("sumTask", "chainId", chainId);
            string memory sumTaskData = vm.serializeAddress("sumTask", "addr", sumTask);
            sumTasksData[i] = sumTaskData;
        }
        string memory finalJson = vm.serializeString(obj, "sumTasks", sumTasksData);

        vm.writeJson(finalJson, "temp-network/deploy-data/sum_task_contracts.json");
    }

    function loadRelayContracts() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/temp-network/deploy-data/relay_contracts.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        RelayContracts memory relayContracts = abi.decode(data, (RelayContracts));

        network = Network(payable(relayContracts.network));
        keyRegistry = IValSetDriver.CrossChainAddress({
            chainId: relayContracts.keyRegistry.chainId,
            addr: relayContracts.keyRegistry.addr
        });
        driver =
            IValSetDriver.CrossChainAddress({chainId: relayContracts.driver.chainId, addr: relayContracts.driver.addr});
        stakingTokens.clear();
        for (uint256 i; i < relayContracts.stakingTokens.length; ++i) {
            stakingTokens.set(relayContracts.stakingTokens[i].chainId, relayContracts.stakingTokens[i].addr);
        }
        votingPowerProviders.clear();
        for (uint256 i; i < relayContracts.votingPowerProviders.length; ++i) {
            votingPowerProviders.set(
                relayContracts.votingPowerProviders[i].chainId, relayContracts.votingPowerProviders[i].addr
            );
        }
        settlements.clear();
        for (uint256 i; i < relayContracts.settlements.length; ++i) {
            settlements.set(relayContracts.settlements[i].chainId, relayContracts.settlements[i].addr);
        }
    }

    function loadSumTaskContracts() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/temp-network/deploy-data/sum_task_contracts.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        SumTaskContracts memory sumTaskContracts = abi.decode(data, (SumTaskContracts));

        sumTasks.clear();
        for (uint256 i; i < sumTaskContracts.sumTasks.length; ++i) {
            sumTasks.set(sumTaskContracts.sumTasks[i].chainId, sumTaskContracts.sumTasks[i].addr);
        }
    }

    function addOperator(
        uint256 stakeAmount
    ) public {
        Vm.Wallet memory operator = getOperator(operatorsCount);
        (BN254.G1Point memory g1Key, BN254.G2Point memory g2Key) = getBLSKeys(operator.privateKey);
        KeyRegistry keyRegistry_ = KeyRegistry(keyRegistry.addr);
        IERC20 stakingToken = IERC20(stakingTokens.get(block.chainid));
        VotingPowers votingPowers = VotingPowers(votingPowerProviders.get(block.chainid));

        vm.startBroadcast(deployer);
        payable(operator.addr).transfer(1 ether);
        stakingToken.transfer(operator.addr, stakeAmount);
        vm.stopBroadcast();

        vm.startBroadcast(operator.privateKey);

        symbioticCore.operatorRegistry.registerOperator();
        symbioticCore.operatorNetworkOptInService.optIn(address(network));
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
        uint256 secondaryBLSKey = operator.privateKey + 10000;
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
        console.log("Operator added:");
        console.log("   Address:", operator.addr);
        console.log("   PrivateKey:", operator.privateKey);
        console.log("   Vault:", address(vault));
        console.log("   Stake:", stakeAmount);
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

    function printOperatorsInfo() public view {
        VotingPowers votingPowers = VotingPowers(votingPowerProviders.get(block.chainid));
        address[] memory operators = votingPowers.getOperators();
        console.log("Operators total:", operators.length);
        console.log("Operators:");
        VotingPowers.OperatorVotingPower[] memory operatorVPs = votingPowers.getVotingPowers(new bytes[](0));

        for (uint256 i; i < operatorVPs.length; ++i) {
            uint256 totalVotingPower;
            console.log("   Address:", operatorVPs[i].operator);
            console.log("   Vaults:");
            for (uint256 j; j < operatorVPs[i].vaults.length; ++j) {
                console.log("       Address:", operatorVPs[i].vaults[j].vault);
                console.log("       Voting power:", operatorVPs[i].vaults[j].value);
                totalVotingPower += operatorVPs[i].vaults[j].value;
            }
            console.log("   Total voting power:", totalVotingPower);
        }
    }
}
