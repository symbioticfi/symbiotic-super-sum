// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/console.sol";
import {console2} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

import {Network} from "../src/Network.sol";
import {KeyRegistry} from "../src/KeyRegistry.sol";
import {Driver} from "../src/Driver.sol";
import {VotingPowers} from "../src/VotingPowers.sol";
import {Settlement} from "../src/Settlement.sol";
import {SumTask} from "../src/SumTask.sol";

contract LocalDeploy is SymbioticCoreInit {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;

    bytes32 internal constant KEY_OWNERSHIP_TYPEHASH = keccak256("KeyOwnership(address operator,bytes key)");

    uint48 public constant EPOCH_DURATION = 1 minutes; // 1 minute
    uint48 public constant SLASHING_WINDOW = 1 days; // 1 day
    uint208 public constant MAX_VALIDATORS_COUNT = 1000; // 1000 validators
    uint256 public constant MAX_VOTING_POWER = 2 ** 247; // no max limit
    uint256 public constant MIN_INCLUSION_VOTING_POWER = 0; // include anyone
    uint248 public constant QUORUM_THRESHOLD = uint248(1e18) * 2 / 3 + 1; // 2/3 + 1
    uint8 public constant REQUIRED_KEY_TAG = 15; // 15 is the default key tag (BLS-BN254/0)
    uint256 public constant OPERATOR_STAKE_AMOUNT = 100000;
    uint256 public constant OPERATOR_COUNT = 4;

    address deployer;

    IERC20 stakingToken;
    Settlement settlement;
    Network network;
    KeyRegistry keyRegistry;
    Driver driver;
    VotingPowers votingPowers;

    uint256 operatorsCount;

    function getDeployerAddress() internal view returns (address) {
        // if DEPLOYER_ADDRESS is not set, use the default deployer address
        return vm.envOr("DEPLOYER_ADDRESS", 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function run() public {
        deployer = getDeployerAddress();

        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core-contracts/";
        SYMBIOTIC_CORE_OWNER = deployer;

        setupCore();
        setupRelayContracts();
        setupSumTask();

        for (uint256 i = 0; i < OPERATOR_COUNT; i++) {
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

    function setupRelayContracts() public {
        vm.startBroadcast(deployer);
        stakingToken = IERC20(address(new MockERC20("StakingToken", "STK")));

        {
            network =
                new Network(address(symbioticCore.networkRegistry), address(symbioticCore.networkMiddlewareService));
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
        }

        {
            votingPowers = new VotingPowers(
                address(symbioticCore.operatorRegistry),
                address(symbioticCore.vaultFactory),
                address(symbioticCore.vaultConfigurator)
            );
            votingPowers.initialize(
                IVotingPowerProvider.VotingPowerProviderInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: address(network),
                        subnetworkID: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "VotingPowers", version: "1"}),
                    slashingWindow: SLASHING_WINDOW,
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
                abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, address(votingPowers)),
                bytes32(0),
                bytes32(0),
                0
            );

            network.execute(
                address(symbioticCore.networkMiddlewareService),
                0,
                abi.encodeWithSelector(INetworkMiddlewareService.setMiddleware.selector, address(votingPowers)),
                bytes32(0),
                bytes32(0)
            );
        }

        {
            keyRegistry = new KeyRegistry();
            keyRegistry.initialize(
                IKeyRegistry.KeyRegistryInitParams({
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "KeyRegistry", version: "1"})
                })
            );
        }

        {
            settlement = new Settlement();
            settlement.initialize(
                ISettlement.SettlementInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: address(network),
                        subnetworkID: 0
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Settlement", version: "1"}),
                    sigVerifier: address(new SigVerifierBlsBn254Simple())
                }),
                deployer
            );
        }

        {
            driver = new Driver();

            IValSetDriver.CrossChainAddress[] memory votingPowerProviders = new IValSetDriver.CrossChainAddress[](1);
            votingPowerProviders[0] =
                IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(votingPowers)});
            IValSetDriver.CrossChainAddress[] memory replicas = new IValSetDriver.CrossChainAddress[](1);
            replicas[0] = IValSetDriver.CrossChainAddress({chainId: uint64(block.chainid), addr: address(settlement)});
            IValSetDriver.QuorumThreshold[] memory quorumThresholds = new IValSetDriver.QuorumThreshold[](1);
            quorumThresholds[0] =
                IValSetDriver.QuorumThreshold({keyTag: REQUIRED_KEY_TAG, quorumThreshold: QUORUM_THRESHOLD});
            uint8[] memory requiredKeyTags = new uint8[](1);
            requiredKeyTags[0] = REQUIRED_KEY_TAG;

            driver.initialize(
                IValSetDriver.ValSetDriverInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: address(network),
                        subnetworkID: 0
                    }),
                    epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                        epochDuration: EPOCH_DURATION,
                        epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 30)
                    }),
                    votingPowerProviders: votingPowerProviders,
                    keysProvider: IValSetDriver.CrossChainAddress({
                        chainId: uint64(block.chainid),
                        addr: address(keyRegistry)
                    }),
                    replicas: replicas,
                    verificationType: 1,
                    maxVotingPower: MAX_VOTING_POWER,
                    minInclusionVotingPower: MIN_INCLUSION_VOTING_POWER,
                    maxValidatorsCount: MAX_VALIDATORS_COUNT,
                    requiredKeyTags: requiredKeyTags,
                    requiredHeaderKeyTag: REQUIRED_KEY_TAG,
                    quorumThresholds: quorumThresholds
                }),
                deployer
            );
        }
        vm.stopBroadcast();

        console.log("Symbiotic Relay contracts:");
        console.log("   StakingToken:", address(stakingToken));
        console.log("   Network:", address(network));
        console.log("   VotingPowers:", address(votingPowers));
        console.log("   KeyRegistry:", address(keyRegistry));
        console.log("   Settlement:", address(settlement));
        console.log("   Driver:", address(driver));
    }

    function setupSumTask() public {
        vm.startBroadcast(deployer);
        SumTask sumTask = new SumTask(address(settlement));
        console.log("SumTask contract:", address(sumTask));
        vm.stopBroadcast();
    }

    function addOperator(uint256 stakeAmount) public {
        Vm.Wallet memory operator = getOperator(operatorsCount);
        (BN254.G1Point memory g1Key, BN254.G2Point memory g2Key) = getBLSKeys(operator.privateKey);

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
        bytes32 messageHash = keyRegistry.hashTypedDataV4(
            keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator.addr, keccak256(keyBytes)))
        );
        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
        BN254.G1Point memory sigG1 = messageG1.scalar_mul(operator.privateKey);
        keyRegistry.setKey(KEY_TYPE_BLS_BN254.getKeyTag(15), keyBytes, abi.encode(sigG1), abi.encode(g2Key));

        vm.stopBroadcast();

        operatorsCount++;
        console.log("Operator added:");
        console.log("   Address:", operator.addr);
        console.log("   PrivateKey:", operator.privateKey);
        console.log("   Vault:", address(vault));
        console.log("   Stake:", stakeAmount);
    }

    function getOperator(uint256 index) public returns (Vm.Wallet memory operator) {
        // deterministic operator private key
        operator = vm.createWallet(1e18 + index);
        vm.rememberKey(operator.privateKey);
        return operator;
    }

    function getBLSKeys(uint256 privateKey) public view returns (BN254.G1Point memory, BN254.G2Point memory) {
        BN254.G1Point memory G1Key = BN254.generatorG1().scalar_mul(privateKey);
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return (G1Key, BN254.G2Point([x2, x1], [y2, y1]));
    }

    function printOperatorsInfo() public view {
        console.log("Operators total:", votingPowers.getOperatorsLength());
        console.log("Operators:");
        VotingPowers.OperatorVotingPower[] memory operatorVPs = votingPowers.getVotingPowers(new bytes[](0));

        for (uint256 i = 0; i < operatorVPs.length; i++) {
            uint256 totalVotingPower = 0;
            console.log("   Address:", operatorVPs[i].operator);
            console.log("   Vaults:");
            for (uint256 j = 0; j < operatorVPs[i].vaults.length; j++) {
                console.log("       Address:", operatorVPs[i].vaults[j].vault);
                console.log("       Voting power:", operatorVPs[i].vaults[j].votingPower);
                totalVotingPower += operatorVPs[i].vaults[j].votingPower;
            }
            console.log("   Total voting power:", totalVotingPower);
        }
    }
}
