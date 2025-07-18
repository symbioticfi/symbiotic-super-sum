package main

import (
	"bytes"
	"context"
	"fmt"
	"log/slog"
	"math/big"
	"os"
	"os/exec"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/go-errors/errors"

	relay_api "sum/internal/relay-api"
)

type processes []process

type process struct {
	args        []string
	cmd         *exec.Cmd
	stdOut      *bytes.Buffer
	stdErr      *bytes.Buffer
	apiAddr     string
	relayClient *relay_api.Client
}

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)

	ctx := context.Background()

	if err := run(ctx); err != nil {
		panic(err)
	}
}

func run(ctx context.Context) error {
	prs, err := runProcesses()
	if err != nil {
		return errors.Errorf("failed to run processes: %w", err)
	}

	currentEpoch, err := prs[0].relayClient.GetSuggestedEpochGet(ctx)
	if err != nil {
		return errors.Errorf("failed to get current epoch: %w", err)
	}

	requestHash, err := prs.sendMessagesToAll(ctx, []byte("Hello, Symbiotic!"), currentEpoch.Epoch)
	if err != nil {
		return errors.Errorf("failed to send messages to all processes: %w", err)
	}
	sentTime := time.Now()

	tick := time.NewTicker(time.Second)
	defer tick.Stop()

cycle:
	for {
		select {
		case <-tick.C:
			resp, err := prs[0].relayClient.GetAggregationProofGet(ctx, relay_api.GetAggregationProofGetParams{
				RequestHash: requestHash,
			})
			if err != nil {
				slog.Debug("Failed to get aggregation proof", "error", err)
				continue
			}
			slog.Debug("Received aggregation proof", "requestHash", requestHash, "proof", common.Bytes2Hex(resp.MessageHash), "elapsed", time.Since(sentTime))
			break cycle
		case <-ctx.Done():
			slog.Info("Context done, stopping processes")
			break cycle
		}
	}

	prs.stopProcesses()

	return nil
}

func runProcesses() (processes, error) {
	pathToExec := "bin/symbiotic_relay"
	commonArgs := []string{"--config", "sidecar.common.yaml", "--log-mode", "text"}
	firstArgs := []string{
		"--aggregator", "true",
		"--committer", "true",
	}
	secretKeyTemplate := "symb/0/15/%s,evm/1/31337/0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
	firstKey := uint64(1e18)
	firstPort := 8080
	firstData := 0

	var prs []process

	for i := 0; i < 4; i++ {
		secretKey := fmt.Sprintf(secretKeyTemplate, common.Bytes2Hex(new(big.Int).SetUint64(firstKey+uint64(i)).Bytes()))
		apiAddr := fmt.Sprintf(":%d", firstPort+i)
		args := append(commonArgs, "--secret-keys", secretKey, "--http-listen", apiAddr, "--storage-dir", fmt.Sprintf(".data/%03d", firstData+i))
		if i == 0 {
			args = append(args, firstArgs...)
		}

		pr := process{
			args:    args,
			apiAddr: apiAddr,
			stdOut:  &bytes.Buffer{},
			stdErr:  &bytes.Buffer{},
		}

		pr.cmd = exec.Command(pathToExec, args...)
		pr.cmd.Stdout = pr.stdOut
		pr.cmd.Stderr = pr.stdErr
		err := pr.cmd.Start()
		if err != nil {
			return nil, errors.Errorf("failed to start process: %w", err)
		}

		pr.relayClient, err = relay_api.NewClient("http://localhost" + apiAddr + "/api/v1")
		if err != nil {
			return nil, errors.Errorf("failed to create relay client: %w", err)
		}

		slog.Debug("Started process", "pid", pr.cmd.Process.Pid, "args", pr.args)

		prs = append(prs, pr)
	}

	// todo ilya fix
	time.Sleep(time.Second * 5) // Give processes some time to start up

	return prs, nil
}

func (prs processes) stopProcesses() {
	for _, pr := range prs {
		// Send an interrupt signal for a graceful shutdown, that is equivalent to pressing Ctrl+C.
		slog.Debug("Stopping process...", "pid", pr.cmd.Process.Pid)
		if err := pr.cmd.Process.Signal(os.Interrupt); err != nil {
			slog.Warn("Failed to send interrupt signal to process. Trying to kill.", "pid", pr.cmd.Process.Pid, "error", err)
			// If signaling fails, you can resort to killing the process forcefully.
			if killErr := pr.cmd.Process.Kill(); killErr != nil {
				slog.Error("Failed to kill process.", "pid", pr.cmd.Process.Pid, "error", killErr)
			}
		}

		if err := pr.cmd.Wait(); err != nil {
			slog.Warn("Process exited with error.", "pid", pr.cmd.Process.Pid, "error", err, "stderr", pr.stdErr.String(), "stdout", pr.stdOut.String())
		} else {
			slog.Info("Process stopped successfully.", "pid", pr.cmd.Process.Pid)
		}
	}
}

func (prs processes) sendMessagesToAll(ctx context.Context, message []byte, epoch uint64) (string, error) {
	var requestHash string
	for _, pr := range prs {
		rh, err := sendSignMessageRequest(ctx, pr, message, epoch)
		if err != nil {
			return "", errors.Errorf("failed to send sign message request: %w", err)
		}
		requestHash = rh
	}
	return requestHash, nil
}

func sendSignMessageRequest(ctx context.Context, pr process, message []byte, epoch uint64) (string, error) {
	resp, err := pr.relayClient.SignMessagePost(ctx, &relay_api.SignMessagePostReq{
		KeyTag:        15,
		Message:       message,
		RequiredEpoch: relay_api.NewOptUint64(epoch),
	})
	if err != nil {
		return "", errors.Errorf("failed to send sign message request: %w", err)
	}
	slog.Debug("Sign message request sent", "message", common.Bytes2Hex(message))

	return resp.RequestHash, nil
}
