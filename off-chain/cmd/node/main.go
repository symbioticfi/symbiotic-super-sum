package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"log/slog"
	"math/big"
	"os"
	"os/signal"
	"syscall"
	"time"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/go-errors/errors"
	"github.com/spf13/cobra"
	v1 "github.com/symbioticfi/relay/api/client/v1"

	"sum/internal/contracts"
	"sum/internal/utils"
)

const (
	TaskCreated uint8 = iota
	TaskResponded
	TaskExpired
	TaskNotFound
)

type config struct {
	relayApiURL       string
	evmRpcURLs        []string
	contractAddresses []string
	privateKey        string
	logLevel          string
}

var relayClient *v1.SymbioticClient
var evmClients map[int64]*ethclient.Client
var sumContracts map[int64]*contracts.SumTask
var sumContractAddresses map[int64]common.Address
var lastBlocks map[int64]uint64
var slashRequests map[string]*SlashRequest
var nodePrivateKey *ecdsa.PrivateKey
var mainChainID int64

func main() {
	slog.Info("Running sum task off-chain client", "args", os.Args)

	if err := run(); err != nil && !errors.Is(err, context.Canceled) {
		slog.Error("Error executing command", "error", err)
		os.Exit(1)
	}
	slog.Info("Sum task off-chain client completed successfully")
}

func run() error {
	rootCmd.PersistentFlags().StringVarP(&cfg.relayApiURL, "relay-api-url", "r", "", "Relay API URL")
	rootCmd.PersistentFlags().StringSliceVarP(&cfg.evmRpcURLs, "evm-rpc-urls", "e", []string{}, "EVM RPC URLs separated by comma (e.g., 'https://mainnet.infura.io/v3/,...')")
	rootCmd.PersistentFlags().StringSliceVarP(&cfg.contractAddresses, "contract-addresses", "a", []string{}, "SumTask contracts' addresses corresponding to the RPC URLs separated by comma (e.g., '0x4826533B4897376654Bb4d4AD88B7faFD0C98528,...')")
	rootCmd.PersistentFlags().StringVarP(&cfg.privateKey, "private-key", "p", "", "Task response private key")
	rootCmd.PersistentFlags().StringVarP(&cfg.logLevel, "log-level", "l", "info", "Log level")

	if err := rootCmd.MarkPersistentFlagRequired("relay-api-url"); err != nil {
		return errors.Errorf("failed to mark relay-api-url as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("evm-rpc-urls"); err != nil {
		return errors.Errorf("failed to mark evm-rpc-urls as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("contract-addresses"); err != nil {
		return errors.Errorf("failed to mark contract-addresses as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("private-key"); err != nil {
		return errors.Errorf("failed to mark private-key as required: %w", err)
	}

	return rootCmd.Execute()
}

var cfg config

type TaskState struct {
	ChainID      int64
	Task         contracts.SumTaskTask
	Result       *big.Int
	SigEpoch     int64
	SigRequestID string
	AggProof     []byte
	Statuses     map[int64]uint8
}

type SlashRequest struct {
	ID               string
	ChainID          int64
	Operator         common.Address
	Amount           *big.Int
	CaptureTimestamp *big.Int
	SigEpoch         int64
	SigRequestID     string
	AggProof         []byte
	TxHash           *common.Hash
}

var tasks map[common.Hash]TaskState
var (
	slashEventSignature = crypto.Keccak256Hash([]byte("Slash(address,uint256,uint48)"))
	slashEventArguments = abi.Arguments{
		{Type: mustABIType("uint256")},
		{Type: mustABIType("uint48")},
	}
	slashMessageArguments = abi.Arguments{
		{Type: mustABIType("address")},
		{Type: mustABIType("uint256")},
		{Type: mustABIType("uint48")},
	}
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:           "sum-node",
	SilenceUsage:  true,
	SilenceErrors: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		switch cfg.logLevel {
		case "debug":
			slog.SetLogLoggerLevel(slog.LevelDebug)
		case "info":
			slog.SetLogLoggerLevel(slog.LevelInfo)
		case "warn":
			slog.SetLogLoggerLevel(slog.LevelWarn)
		case "error":
			slog.SetLogLoggerLevel(slog.LevelError)
		}

		ctx := signalContext(context.Background())

		var err error

		conn, err := utils.GetGRPCConnection(cfg.relayApiURL)
		if err != nil {
			return errors.Errorf("failed to create relay client: %w", err)
		}

		relayClient = v1.NewSymbioticClient(conn)

		if len(cfg.evmRpcURLs) == 0 {
			return errors.Errorf("no RPC URLs provided")
		}
		if len(cfg.contractAddresses) != len(cfg.evmRpcURLs) {
			return errors.Errorf("mismatched lengths: evm-rpc-urls=%d, contract-addresses=%d", len(cfg.evmRpcURLs), len(cfg.contractAddresses))
		}
		nodePrivateKey, err = crypto.HexToECDSA(cfg.privateKey)
		if err != nil {
			return errors.Errorf("failed to parse private key: %w", err)
		}
		evmClients = make(map[int64]*ethclient.Client)
		sumContracts = make(map[int64]*contracts.SumTask)
		sumContractAddresses = make(map[int64]common.Address)
		tasks = make(map[common.Hash]TaskState)
		slashRequests = make(map[string]*SlashRequest)
		lastBlocks = make(map[int64]uint64)

		for i, evmRpcURL := range cfg.evmRpcURLs {
			evmClient, err := ethclient.DialContext(ctx, evmRpcURL)
			if err != nil {
				return errors.Errorf("failed to connect to RPC URL '%s': %w", evmRpcURL, err)
			}

			chainID, err := evmClient.ChainID(ctx)
			if err != nil {
				return errors.Errorf("failed to get chain ID from RPC URL '%s': %w", evmRpcURL, err)
			}

			if i == 0 {
				mainChainID = chainID.Int64()
			}

			addr := common.HexToAddress(cfg.contractAddresses[i])
			sumContract, err := contracts.NewSumTask(addr, evmClient)
			if err != nil {
				return errors.Errorf("failed to create sum contract for %s on chain %d: %w", addr.Hex(), chainID, err)
			}

			evmClients[chainID.Int64()] = evmClient
			sumContracts[chainID.Int64()] = sumContract
			sumContractAddresses[chainID.Int64()] = addr

			finalizedBlockNumber, err := getFinalizedBlockNumber(ctx, evmClient)
			if err != nil {
				return errors.Errorf("failed to get finalized block number for chain %d: %w", chainID, err)
			}
			lastBlocks[chainID.Int64()] = finalizedBlockNumber

			slog.InfoContext(ctx, "Initialized chain", "chainID", chainID, "finalizedBlock", finalizedBlockNumber, "startBlock", lastBlocks[chainID.Int64()])
		}

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				for chainID, evmClient := range evmClients {
					endBlockNumber, err := getFinalizedBlockNumber(ctx, evmClient)
					if err != nil {
						return errors.Errorf("failed to get finalized block number for chain %d: %w", chainID, err)
					}

					startBlock := lastBlocks[chainID]

					if endBlockNumber < startBlock {
						slog.DebugContext(ctx, "Finalized block number is behind last processed block, skipping", "chainID", chainID, "finalizedBlock", endBlockNumber, "lastProcessedBlock", startBlock)
						continue
					}

					slog.DebugContext(ctx, "Fetching events", "chainID", chainID, "fromBlock", startBlock, "toBlock", endBlockNumber)

					events, err := sumContracts[chainID].FilterCreateTask(&bind.FilterOpts{
						Context: ctx,
						Start:   startBlock,
						End:     &endBlockNumber,
					}, [][32]byte{})
					if err != nil {
						return errors.Errorf("failed to filter new task created events: %w", err)
					}

					err = processNewTasks(ctx, chainID, events)
					if err != nil {
						fmt.Printf("Error processing new task event: %v\n", err)
					}

					slashLogs, err := fetchSlashLogs(ctx, chainID, startBlock, endBlockNumber)
					if err != nil {
						return errors.Errorf("failed to filter slash events for chain %d: %w", chainID, err)
					}

					err = processSlashEvents(ctx, chainID, slashLogs)
					if err != nil {
						fmt.Printf("Error processing slash events: %v\n", err)
					}

					lastBlocks[chainID] = endBlockNumber + 1
				}
				err = fetchResults(ctx)
				if err != nil {
					fmt.Printf("Error fetching results: %v\n", err)
				}
				err = processSlashSubmissions(ctx)
				if err != nil {
					fmt.Printf("Error submitting slash transaction: %v\n", err)
				}
			case <-ctx.Done():
				return nil
			}
		}
	},
}

func getFinalizedBlockNumber(ctx context.Context, evmClient *ethclient.Client) (uint64, error) {
	// Get finalized block and set starting point to 24 hours ago
	var raw json.RawMessage
	err := evmClient.Client().CallContext(ctx, &raw, "eth_getBlockByNumber", "finalized", true)
	if err != nil {
		return 0, errors.Errorf("failed to get finalized block number: %w", err)
	}
	var head *types.Header
	if err := json.Unmarshal(raw, &head); err != nil {
		return 0, errors.Errorf("failed to unmarshal finalized block: %w", err)
	}

	return head.Number.Uint64(), nil
}

func fetchResults(ctx context.Context) error {
	for taskID, state := range tasks {
		for chainID := range sumContracts {
			if state.Statuses[chainID] == TaskResponded {
				continue
			}
			status, err := sumContracts[chainID].GetTaskStatus(&bind.CallOpts{
				Context: ctx,
			}, taskID)
			if err != nil {
				return err
			}
			state.Statuses[chainID] = status
		}
		slog.InfoContext(ctx, "Task statuses", "taskID", taskID.Hex(), "statuses", state.Statuses)
		allNotFoundOrExpired := true
		allResponded := true
		for _, status := range state.Statuses {
			if status != TaskNotFound && status != TaskExpired {
				allNotFoundOrExpired = false
			}
			if status != TaskResponded {
				allResponded = false
			}
		}
		if allNotFoundOrExpired || allResponded {
			delete(tasks, taskID)
			continue
		}
		if state.AggProof == nil {
			resp, err := relayClient.GetAggregationProof(ctx, &v1.GetAggregationProofRequest{
				RequestId: state.SigRequestID,
			})
			if err != nil {
				//		slog.InfoContext(ctx, "Failed to fetch aggregation proof", "err", err)
				continue
			}
			state.AggProof = resp.AggregationProof.Proof
			slog.InfoContext(ctx, "Got aggregation proof", "taskID", taskID.Hex(), "proof", hexutil.Encode(resp.AggregationProof.Proof))
		}

		tasks[taskID] = state

		err := processProof(ctx, taskID)
		if err != nil {
			fmt.Printf("Error processing proof: %v\n", err)
		}
	}
	return nil
}

func processProof(ctx context.Context, taskID common.Hash) error {
	if nodePrivateKey == nil {
		return errors.Errorf("node private key is not initialized")
	}
	task := tasks[taskID]
	for chainID, status := range task.Statuses {
		if status == TaskResponded {
			continue
		}
		txOpts, err := bind.NewKeyedTransactorWithChainID(nodePrivateKey, big.NewInt(chainID))
		if err != nil {
			return errors.Errorf("failed to create transactor: %w", err)
		}
		txOpts.Context = ctx

		tx, err := sumContracts[chainID].RespondTask(txOpts, taskID, task.Result, big.NewInt(task.SigEpoch), task.AggProof)
		if err != nil {
			return errors.Errorf("failed to respond task: %w", err)
		}

		slog.InfoContext(ctx, "Submitted response tx", "taskID", taskID.Hex(), "tx", tx.Hash().String(), "gas", tx.Gas())
	}
	return nil
}

func processNewTasks(ctx context.Context, chainID int64, iter *contracts.SumTaskCreateTaskIterator) error {
	for iter.Next() {
		evt := iter.Event
		status, err := sumContracts[chainID].GetTaskStatus(&bind.CallOpts{
			Context: ctx,
		}, evt.TaskId)
		if err != nil {
			return err
		}

		if status != TaskCreated {
			// skip if task is not in created state
			continue
		}

		slog.InfoContext(ctx, "Received new task", "taskID", common.Hash(evt.TaskId).Hex(), "task", evt.Task)

		bytes32T, _ := abi.NewType("bytes32", "", nil)
		uint256T, _ := abi.NewType("uint256", "", nil)

		args := abi.Arguments{
			{Type: bytes32T},
			{Type: uint256T},
		}

		taskResult := new(big.Int).Add(evt.Task.NumberA, evt.Task.NumberB)

		slog.InfoContext(ctx, "New task result", "result", taskResult.String())

		msg, err := args.Pack(evt.TaskId, taskResult)
		if err != nil {
			return err
		}

		slog.InfoContext(ctx, "New task result to sign", "message", hexutil.Encode(msg))

		suggestedEpoch := uint64(0)
		epochInfos, err := relayClient.GetLastAllCommitted(ctx, &v1.GetLastAllCommittedRequest{})
		if err != nil {
			return err
		} else {
			for _, info := range epochInfos.EpochInfos {
				if suggestedEpoch == 0 || info.GetLastCommittedEpoch() < suggestedEpoch {
					suggestedEpoch = info.GetLastCommittedEpoch()
				}
			}
		}

		resp, err := relayClient.SignMessage(ctx, &v1.SignMessageRequest{
			KeyTag:        15,
			Message:       msg,
			RequiredEpoch: &suggestedEpoch,
		})
		if err != nil {
			return err
		}

		tasks[evt.TaskId] = TaskState{
			ChainID:      chainID,
			Task:         evt.Task,
			Result:       taskResult,
			SigEpoch:     int64(resp.Epoch),
			SigRequestID: resp.RequestId,
			AggProof:     nil,
			Statuses:     map[int64]uint8{},
		}

		slog.InfoContext(ctx, "New task result signed", "resp", resp)
	}
	return nil
}

func fetchSlashLogs(ctx context.Context, chainID int64, startBlock, endBlock uint64) ([]types.Log, error) {
	if startBlock > endBlock {
		return nil, nil
	}

	address, ok := sumContractAddresses[chainID]
	if !ok {
		return nil, errors.Errorf("sum contract address not found for chain %d", chainID)
	}

	fromBlock := new(big.Int).SetUint64(startBlock)
	toBlock := new(big.Int).SetUint64(endBlock)

	query := ethereum.FilterQuery{
		FromBlock: fromBlock,
		ToBlock:   toBlock,
		Addresses: []common.Address{address},
		Topics:    [][]common.Hash{{slashEventSignature}},
	}

	return evmClients[chainID].FilterLogs(ctx, query)
}

func processSlashEvents(ctx context.Context, chainID int64, logs []types.Log) error {
	for _, log := range logs {
		req, err := parseSlashLog(chainID, log)
		if err != nil {
			return err
		}
		if _, exists := slashRequests[req.ID]; exists {
			continue
		}
		slashRequests[req.ID] = req
		slog.InfoContext(ctx, "Received slash request", "id", req.ID, "chainID", chainID, "operator", req.Operator.Hex(), "amount", req.Amount.String(), "captureTimestamp", req.CaptureTimestamp.String())
	}
	return nil
}

func parseSlashLog(chainID int64, log types.Log) (*SlashRequest, error) {
	if len(log.Topics) < 2 {
		return nil, errors.Errorf("slash log missing topics on chain %d", chainID)
	}

	values, err := slashEventArguments.Unpack(log.Data)
	if err != nil {
		return nil, errors.Errorf("failed to unpack slash event: %w", err)
	}

	amount, ok := values[0].(*big.Int)
	if !ok {
		return nil, errors.Errorf("invalid slash amount type %T", values[0])
	}
	captureTimestamp, ok := values[1].(*big.Int)
	if !ok {
		return nil, errors.Errorf("invalid slash capture timestamp type %T", values[1])
	}

	req := &SlashRequest{
		ID:               slashRequestKey(chainID, log),
		ChainID:          chainID,
		Operator:         common.HexToAddress(log.Topics[1].Hex()),
		Amount:           new(big.Int).Set(amount),
		CaptureTimestamp: new(big.Int).Set(captureTimestamp),
	}

	return req, nil
}

func processSlashSubmissions(ctx context.Context) error {
	if len(slashRequests) == 0 {
		return nil
	}
	if nodePrivateKey == nil {
		return errors.Errorf("node private key is not initialized")
	}
	if mainChainID == 0 {
		return errors.Errorf("main chain ID is not initialized")
	}

	var firstErr error

	for id, req := range slashRequests {
		if req.AggProof == nil {
			err := requestSlashSignature(ctx, req)
			if err != nil {
				slog.ErrorContext(ctx, "Failed to request slash signature", "id", id, "chainID", req.ChainID, "error", err)
				if firstErr == nil {
					firstErr = err
				}
				continue
			}
			err = fetchSlashAggregationProof(ctx, req)
			if err != nil {
				slog.DebugContext(ctx, "Aggregation proof not ready yet", "id", id, "chainID", req.ChainID, "error", err)
			}
			if req.AggProof == nil {
				continue
			}
		}

		if req.TxHash == nil {
			txOpts, err := bind.NewKeyedTransactorWithChainID(nodePrivateKey, big.NewInt(mainChainID))
			if err != nil {
				if firstErr == nil {
					firstErr = errors.Errorf("failed to create slash transactor: %w", err)
				}
				continue
			}
			txOpts.Context = ctx

			contract, ok := sumContracts[mainChainID]
			if !ok {
				err = errors.Errorf("sum contract missing for chain %d", mainChainID)
				if firstErr == nil {
					firstErr = err
				}
				continue
			}

			raw := &contracts.SumTaskRaw{Contract: contract}

			tx, err := raw.Transact(txOpts, "processSlash", req.Operator, req.Amount, req.CaptureTimestamp, big.NewInt(req.SigEpoch), req.AggProof)
			if err != nil {
				slog.ErrorContext(ctx, "Failed to submit slash transaction", "id", id, "sourceChainID", req.ChainID, "targetChainID", mainChainID, "error", err)
				if firstErr == nil {
					firstErr = err
				}
				continue
			}

			hash := tx.Hash()
			req.TxHash = &hash
			slog.InfoContext(ctx, "Submitted slash transaction", "id", id, "sourceChainID", req.ChainID, "targetChainID", mainChainID, "tx", hash.Hex(), "operator", req.Operator.Hex())
			continue
		}

		receipt, err := evmClients[mainChainID].TransactionReceipt(ctx, *req.TxHash)
		if err != nil {
			if errors.Is(err, ethereum.NotFound) {
				continue
			}
			slog.ErrorContext(ctx, "Failed to fetch slash transaction receipt", "id", id, "sourceChainID", req.ChainID, "targetChainID", mainChainID, "tx", req.TxHash.Hex(), "error", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}

		if receipt.Status == types.ReceiptStatusSuccessful {
			slog.InfoContext(ctx, "Slash transaction confirmed", "id", id, "sourceChainID", req.ChainID, "targetChainID", mainChainID, "tx", req.TxHash.Hex())
			delete(slashRequests, id)
			continue
		}

		slog.WarnContext(ctx, "Slash transaction reverted, will retry", "id", id, "sourceChainID", req.ChainID, "targetChainID", mainChainID, "tx", req.TxHash.Hex())
		req.TxHash = nil
	}

	return firstErr
}

func slashRequestKey(chainID int64, log types.Log) string {
	return fmt.Sprintf("%d-%s-%d", chainID, log.TxHash.Hex(), log.Index)
}

func getSuggestedEpoch(ctx context.Context) (uint64, error) {
	suggestedEpoch := uint64(0)
	epochInfos, err := relayClient.GetLastAllCommitted(ctx, &v1.GetLastAllCommittedRequest{})
	if err != nil {
		return 0, err
	}

	for _, info := range epochInfos.EpochInfos {
		if suggestedEpoch == 0 || info.GetLastCommittedEpoch() < suggestedEpoch {
			suggestedEpoch = info.GetLastCommittedEpoch()
		}
	}

	return suggestedEpoch, nil
}

func buildSlashMessage(operator common.Address, amount *big.Int, captureTimestamp *big.Int) ([]byte, error) {
	return slashMessageArguments.Pack(operator, amount, captureTimestamp)
}

func requestSlashSignature(ctx context.Context, req *SlashRequest) error {
	if req.SigRequestID != "" {
		return nil
	}

	msg, err := buildSlashMessage(req.Operator, req.Amount, req.CaptureTimestamp)
	if err != nil {
		return err
	}

	suggestedEpoch, err := getSuggestedEpoch(ctx)
	if err != nil {
		return err
	}

	resp, err := relayClient.SignMessage(ctx, &v1.SignMessageRequest{
		KeyTag:        15,
		Message:       msg,
		RequiredEpoch: &suggestedEpoch,
	})
	if err != nil {
		return err
	}

	req.SigRequestID = resp.RequestId
	req.SigEpoch = int64(resp.Epoch)

	slog.InfoContext(ctx, "Slash request signed", "id", req.ID, "chainID", req.ChainID, "epoch", req.SigEpoch, "requestID", req.SigRequestID)

	return nil
}

func fetchSlashAggregationProof(ctx context.Context, req *SlashRequest) error {
	if req.SigRequestID == "" || req.AggProof != nil {
		return nil
	}

	resp, err := relayClient.GetAggregationProof(ctx, &v1.GetAggregationProofRequest{
		RequestId: req.SigRequestID,
	})
	if err != nil {
		return err
	}

	req.AggProof = resp.AggregationProof.Proof

	slog.InfoContext(ctx, "Got aggregation proof for slash", "id", req.ID, "chainID", req.ChainID, "proof", hexutil.Encode(req.AggProof))

	return nil
}

func signalContext(ctx context.Context) context.Context {
	cnCtx, cancel := context.WithCancel(ctx)

	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGTERM, syscall.SIGINT)

	go func() {
		sig := <-c
		slog.WarnContext(ctx, "Received signal", "signal", sig)
		cancel()
	}()

	return cnCtx
}

func mustABIType(t string) abi.Type {
	typ, err := abi.NewType(t, "", nil)
	if err != nil {
		panic(fmt.Sprintf("invalid ABI type %s: %v", t, err))
	}
	return typ
}
