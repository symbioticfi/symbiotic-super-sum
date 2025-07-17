package main

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"
	"log/slog"
	"math/big"
	"os"
	"os/signal"
	"sum/internal/contracts"
	"syscall"
	"time"

	"sum/internal/relay-api"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/go-errors/errors"
	"github.com/spf13/cobra"
)

const (
	TaskCreated uint8 = iota
	TaskResponded
	TaskExpired
	TaskNotFound
)

type config struct {
	evmRpcURL       string
	relayApiURL     string
	contractAddress string
	privateKey      string
	logLevel        string
}

var relayClient *relay_api.Client
var evmClient *ethclient.Client
var sumContract *contracts.SumTask

func main() {
	slog.Info("Running sum task off-chain client", "args", os.Args)

	if err := run(); err != nil && !errors.Is(err, context.Canceled) {
		slog.Error("Error executing command", "error", err)
		os.Exit(1)
	}
	slog.Info("Sum task off-chain client completed successfully")
}

func run() error {
	rootCmd.PersistentFlags().StringVarP(&cfg.evmRpcURL, "evm-rpc-url", "e", "", "EVM RPC URL")
	rootCmd.PersistentFlags().StringVarP(&cfg.relayApiURL, "relay-api-url", "r", "", "Relay API URL")
	rootCmd.PersistentFlags().StringVarP(&cfg.contractAddress, "contract-address", "a", "", "Contract address")
	rootCmd.PersistentFlags().StringVarP(&cfg.privateKey, "private-key", "p", "", "Task response private key")
	rootCmd.PersistentFlags().StringVarP(&cfg.logLevel, "log-level", "l", "info", "Log level")

	if err := rootCmd.MarkPersistentFlagRequired("evm-rpc-url"); err != nil {
		return errors.Errorf("failed to mark evm-rpc-url as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("relay-api-url"); err != nil {
		return errors.Errorf("failed to mark relay-api-url as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("contract-address"); err != nil {
		return errors.Errorf("failed to mark contract-address as required: %w", err)
	}
	if err := rootCmd.MarkPersistentFlagRequired("private-key"); err != nil {
		return errors.Errorf("failed to mark private-key as required: %w", err)
	}

	return rootCmd.Execute()
}

var cfg config

type TaskState struct {
	Task           contracts.SumTaskTask
	Result         *big.Int
	SigRequestHash string
	AggProof       []byte
}

var allTasks map[uint32]TaskState

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

		allTasks = make(map[uint32]TaskState)

		ctx := signalContext(context.Background())

		var err error
		evmClient, err = ethclient.DialContext(ctx, cfg.evmRpcURL)
		if err != nil {
			return errors.Errorf("failed to create evm client: %w", err)
		}

		relayClient, err = relay_api.NewClient(cfg.relayApiURL)
		if err != nil {
			return errors.Errorf("failed to create relay client: %w", err)
		}

		sumContract, err = contracts.NewSumTask(common.HexToAddress(cfg.contractAddress), evmClient)
		if err != nil {
			return errors.Errorf("failed to create sum contract: %w", err)
		}

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		lastBlock := uint64(0)

		for {
			select {
			case <-ticker.C:
				endBlock, err := evmClient.BlockByNumber(ctx, new(big.Int).SetInt64(rpc.FinalizedBlockNumber.Int64()))
				if err != nil {
					return errors.Errorf("failed to get finalized block number: %w", err)
				}
				endBlockNumber := endBlock.NumberU64()

				slog.DebugContext(ctx, "Fetching events", "fromBlock", lastBlock, "toBlock", endBlockNumber)

				events, err := sumContract.FilterNewTaskCreated(&bind.FilterOpts{
					Context: ctx,
					Start:   lastBlock,
					End:     &endBlockNumber,
				}, []uint32{})
				if err != nil {
					return errors.Errorf("failed to filter new task created events: %w", err)
				}
				lastBlock = endBlockNumber + 1

				err = processNewTasks(ctx, events)
				if err != nil {
					fmt.Printf("Error processing new task event: %v\n", err)
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

func fetchResults(ctx context.Context) error {
	for taskID, state := range allTasks {
		if state.AggProof == nil {
			status, err := sumContract.GetTaskStatus(&bind.CallOpts{
				Context: ctx,
			}, taskID)
			if err != nil {
				return err
			}

			if status != TaskCreated {
				// if task is not in created state just delete it
				delete(allTasks, taskID)
				continue
			}

			resp, err := relayClient.GetAggregationProofGet(ctx, relay_api.GetAggregationProofGetParams{
				RequestHash: state.SigRequestHash,
			})

			if err != nil {
				//		slog.InfoContext(ctx, "Failed to fetch aggregation proof", "err", err)
				continue
			}

			state.AggProof = resp.Proof
			allTasks[taskID] = state

			slog.InfoContext(ctx, "Got aggregation proof", "taskID", taskID, "proof", hexutil.Encode(resp.Proof))

			err = processProof(ctx, taskID)
			if err != nil {
				fmt.Printf("Error processing proof: %v\n", err)
			}
		}
	}
	return nil
}

func processProof(ctx context.Context, taskID uint32) error {
	pk, err := crypto.HexToECDSA(cfg.privateKey)
	if err != nil {
		return errors.Errorf("failed to parse private key: %w", err)
	}
	chainId, err := evmClient.ChainID(ctx)
	if err != nil {
		return errors.Errorf("failed to get chain ID: %w", err)
	}
	txOpts, err := bind.NewKeyedTransactorWithChainID(pk, chainId)
	if err != nil {
		return errors.Errorf("failed to create transactor: %w", err)
	}
	txOpts.Context = ctx

	taskState := allTasks[taskID]

	tx, err := sumContract.RespondTask(txOpts, taskID, taskState.Result, taskState.AggProof)
	if err != nil {
		return errors.Errorf("failed to respond task: %w", err)
	}

	slog.InfoContext(ctx, "Submitted response tx", "taskID", taskID, "tx", tx.Hash().String(), "gas", tx.Gas())
	return nil
}

func processNewTasks(ctx context.Context, iter *contracts.SumTaskNewTaskCreatedIterator) error {
	for iter.Next() {
		evt := iter.Event
		status, err := sumContract.GetTaskStatus(&bind.CallOpts{
			Context: ctx,
		}, evt.TaskIndex)
		if err != nil {
			return err
		}

		if status != TaskCreated {
			// skip if task is not in created state
			continue
		}

		slog.InfoContext(ctx, "Received new task", "taskID", evt.TaskIndex, "task", evt.Task)

		uint32T, _ := abi.NewType("uint32", "", nil)
		uint256T, _ := abi.NewType("uint256", "", nil)

		args := abi.Arguments{
			{Type: uint32T},
			{Type: uint256T},
		}

		taskResult := new(big.Int).Add(evt.Task.NumberA, evt.Task.NumberB)

		slog.InfoContext(ctx, "New task result", "result", taskResult.String())

		msg, err := args.Pack(evt.TaskIndex, taskResult)
		if err != nil {
			return err
		}

		slog.InfoContext(ctx, "New task result to sign", "message", hexutil.Encode(msg))

		resp, err := relayClient.SignMessagePost(ctx, &relay_api.SignMessagePostReq{
			KeyTag:        15,
			Message:       msg,
			RequiredEpoch: relay_api.NewOptUint64(evt.Task.RequiredEpoch.Uint64()),
		})
		if err != nil {
			return err
		}

		allTasks[evt.TaskIndex] = TaskState{
			Task:           evt.Task,
			SigRequestHash: resp.RequestHash,
			Result:         new(big.Int).Set(taskResult),
			AggProof:       nil,
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
