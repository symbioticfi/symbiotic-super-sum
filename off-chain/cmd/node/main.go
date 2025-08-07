package main

import (
	"context"
	"fmt"
	"log/slog"
	"math/big"
	"os"
	"os/signal"
	"sum/internal/contracts"
	"syscall"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"

	relay_api "sum/internal/relay-api"

	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/go-errors/errors"
	"github.com/spf13/cobra"
)

const (
	TaskCreated uint8 = 0
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

var relayClient *relay_api.Client
var evmClients map[int64]*ethclient.Client
var sumContracts map[int64]*contracts.SumTask
var lastBlocks map[int64]uint64

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
	rootCmd.PersistentFlags().StringSliceVarP(&cfg.contractAddresses, "contract-addresses", "a", []string{}, "SumTask contracts' addresses corresponding to the RPC URLs separated by comma (e.g., '0x0E801D84Fa97b50751Dbf25036d067dCf18858bF,...')")
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
	ChainID        int64
	Task           contracts.SumTaskTask
	Result         *big.Int
	SigEpoch       int64
	SigRequestHash string
	AggProof       []byte
	Statuses       map[int64]uint8
}

var tasks map[common.Hash]TaskState

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

		relayClient, err = relay_api.NewClient(cfg.relayApiURL)
		if err != nil {
			return errors.Errorf("failed to create relay client: %w", err)
		}

		if len(cfg.evmRpcURLs) == 0 {
			return errors.Errorf("no RPC URLs provided")
		}
		evmClients = make(map[int64]*ethclient.Client)
		sumContracts = make(map[int64]*contracts.SumTask)
		tasks = make(map[common.Hash]TaskState)
		for i, evmRpcURL := range cfg.evmRpcURLs {
			evmClient, err := ethclient.DialContext(ctx, evmRpcURL)
			if err != nil {
				return errors.Errorf("failed to connect to RPC URL '%s': %w", evmRpcURL, err)
			}

			chainID, err := evmClient.ChainID(ctx)
			if err != nil {
				return errors.Errorf("failed to get chain ID from RPC URL '%s': %w", evmRpcURL, err)
			}

			sumContract, err := contracts.NewSumTask(common.HexToAddress(cfg.contractAddresses[i]), evmClient)
			if err != nil {
				return errors.Errorf("failed to create sum contract: %w", err)
			}

			evmClients[chainID.Int64()] = evmClient
			sumContracts[chainID.Int64()] = sumContract
		}

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		lastBlocks = make(map[int64]uint64)

		for {
			select {
			case <-ticker.C:
				for chainID, evmClient := range evmClients {
					endBlock, err := evmClient.BlockByNumber(ctx, new(big.Int).SetInt64(rpc.FinalizedBlockNumber.Int64()))
					if err != nil {
						return errors.Errorf("failed to get finalized block number: %w", err)
					}
					endBlockNumber := endBlock.NumberU64()

					lastBlock := lastBlocks[chainID]

					slog.DebugContext(ctx, "Fetching events", "chainID", chainID, "fromBlock", lastBlock, "toBlock", endBlockNumber)

					events, err := sumContracts[chainID].FilterCreateTask(&bind.FilterOpts{
						Context: ctx,
						Start:   lastBlock,
						End:     &endBlockNumber,
					}, [][32]byte{})
					if err != nil {
						return errors.Errorf("failed to filter new task created events: %w", err)
					}

					lastBlocks[chainID] = endBlockNumber + 1

					err = processNewTasks(ctx, chainID, events)
					if err != nil {
						fmt.Printf("Error processing new task event: %v\n", err)
					}
				}
				err = fetchResults(ctx)
				if err != nil {
					fmt.Printf("Error fetching results: %v\n", err)
				}
			case <-ctx.Done():
				return nil
			}
		}
	},
}

func getTaskID(task TaskState) common.Hash {
	u256Ty, _ := abi.NewType("uint256", "", nil)
	args := abi.Arguments{
		{Type: u256Ty},
		{Type: u256Ty},
		{Type: u256Ty},
		{Type: u256Ty},
	}
	encoded, err := args.Pack(
		big.NewInt(int64(task.ChainID)),
		task.Task.NumberA,
		task.Task.NumberB,
		task.Task.Nonce,
	)
	if err != nil {
		panic(fmt.Sprintf("failed to encode taskID: %v", err))
	}
	return crypto.Keccak256Hash(encoded)
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
		slog.InfoContext(ctx, "Task statuses", "taskID", taskID, "statuses", state.Statuses)
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
			resp, err := relayClient.GetAggregationProofGet(ctx, relay_api.GetAggregationProofGetParams{
				RequestHash: state.SigRequestHash,
			})
			if err != nil {
				//		slog.InfoContext(ctx, "Failed to fetch aggregation proof", "err", err)
				continue
			}
			state.AggProof = resp.Proof
			slog.InfoContext(ctx, "Got aggregation proof", "taskID", taskID, "proof", hexutil.Encode(resp.Proof))
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
	pk, err := crypto.HexToECDSA(cfg.privateKey)
	if err != nil {
		return errors.Errorf("failed to parse private key: %w", err)
	}
	task := tasks[taskID]
	for chainID, status := range task.Statuses {
		if status == TaskResponded {
			continue
		}
		txOpts, err := bind.NewKeyedTransactorWithChainID(pk, big.NewInt(chainID))
		if err != nil {
			return errors.Errorf("failed to create transactor: %w", err)
		}
		txOpts.Context = ctx

		tx, err := sumContracts[chainID].RespondTask(txOpts, taskID, task.Result, big.NewInt(task.SigEpoch), task.AggProof)
		if err != nil {
			return errors.Errorf("failed to respond task: %w", err)
		}

		slog.InfoContext(ctx, "Submitted response tx", "taskID", taskID, "tx", tx.Hash().String(), "gas", tx.Gas())
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

		slog.InfoContext(ctx, "Received new task", "taskID", evt.TaskId, "task", evt.Task)

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

		suggestedEpoch, err := relayClient.GetSuggestedEpochGet(ctx)
		if err != nil {
			return err
		}

		resp, err := relayClient.SignMessagePost(ctx, &relay_api.SignMessagePostReq{
			KeyTag:        15,
			Message:       msg,
			RequiredEpoch: relay_api.NewOptUint64(suggestedEpoch.Epoch),
		})
		if err != nil {
			return err
		}

		tasks[evt.TaskId] = TaskState{
			ChainID:        chainID,
			Task:           evt.Task,
			Result:         taskResult,
			SigEpoch:       int64(resp.Epoch),
			SigRequestHash: resp.RequestHash,
			AggProof:       nil,
			Statuses:       map[int64]uint8{},
		}

		slog.InfoContext(ctx, "New task result signed", "resp", resp)
	}
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
