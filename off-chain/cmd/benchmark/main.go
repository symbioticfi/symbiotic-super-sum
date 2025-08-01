package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"fmt"
	"log/slog"
	"math/big"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/go-errors/errors"
	"golang.org/x/sync/errgroup"

	relay_api "sum/internal/relay-api"
)

type processes []process

type process struct {
	args          []string
	cmd           *exec.Cmd
	stdOut        *bytes.Buffer
	stdErr        *bytes.Buffer
	apiAddr       string
	relayClient   *relay_api.Client
	runSeparately bool
}

const (
	operatorsCount       = 3
	numberOfSignRequests = 1000
	sizeOfMessageBytes   = 320
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)

	ctx := context.Background()

	if err := run(ctx); err != nil {
		panic(err)
	}
}

func run(ctx context.Context) error {
	prs, err := runProcesses(ctx, false)
	if err != nil {
		return errors.Errorf("failed to run processes: %w", err)
	}
	defer prs.stopProcesses()

	if err := sendRequestAndWait(ctx, prs, numberOfSignRequests); err != nil {
		return errors.Errorf("failed to send request and wait: %w", err)
	}
	if errors.Is(err, context.Canceled) {
		slog.Info("Context was canceled, stopping processes")
	}

	select {
	case <-ctx.Done():
		slog.Info("Context done, stopping processes")
		break
	}

	return nil
}

func sendRequestAndWait(ctx context.Context, prs processes, nRequests int) *errors.Error {
	currentEpoch, err := prs[0].relayClient.GetSuggestedEpochGet(ctx)
	if err != nil {
		return errors.Errorf("failed to get current epoch: %w", err)
	}

	requestHashesSent := make([]string, nRequests)
	eg, egCtx := errgroup.WithContext(ctx)
	eg.SetLimit(20)
	for i := range nRequests {
		eg.Go(func() error {
			requestHash, err := prs.sendMessageToAllRelays(egCtx, currentEpoch.Epoch)
			if err != nil {
				return errors.Errorf("failed to send messages to all processes: %w", err)
			}
			requestHashesSent[i] = requestHash
			return nil
		})
	}
	if err := eg.Wait(); err != nil {
		return errors.Errorf("failed to send messages to all processes: %w", err)
	}

	sentTime := time.Now()
	slog.Info("Sent all requesst", "nRequests", nRequests, "time", sentTime)

	timer := time.NewTimer(0)
	defer timer.Stop()

	requestHashesAggregated := make(map[string]struct{})

cycle:
	for {
		select {
		case <-timer.C:
			for i := range requestHashesSent {
				requestHash := requestHashesSent[i]
				if _, ok := requestHashesAggregated[requestHash]; ok {
					continue
				}

				resp, err := prs[0].relayClient.GetAggregationProofGet(ctx, relay_api.GetAggregationProofGetParams{
					RequestHash: requestHash,
				})
				if err != nil {
					slog.Debug("Failed to get aggregation status", "error", err)
					continue
				}

				slog.Debug("Received aggregation proof", "requestHash", requestHash, "proof", common.Bytes2Hex(resp.MessageHash), "elapsed", time.Since(sentTime))

				requestHashesAggregated[requestHash] = struct{}{}
			}
			if len(requestHashesAggregated) == nRequests {
				slog.Info("All requests aggregated", "count", len(requestHashesAggregated), "elapsed", time.Since(sentTime))
				break cycle
			}
			timer.Reset(time.Second)
		case <-ctx.Done():
			slog.Info("Context done, stopping processes")
			break cycle
		}
	}
	return nil
}

func runProcesses(ctx context.Context, runSeparately bool) (processes, error) {
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

	var prs processes

	for i := range operatorsCount {
		secretKey := fmt.Sprintf(secretKeyTemplate, common.Bytes2Hex(new(big.Int).SetUint64(firstKey+uint64(i)).Bytes()))
		apiAddr := fmt.Sprintf(":%d", firstPort+i)
		args := append(commonArgs, "--secret-keys", secretKey, "--http-listen", apiAddr, "--storage-dir", fmt.Sprintf(".data/%03d", firstData+i))
		if i == 0 {
			args = append(args, firstArgs...)
		}

		pr := process{
			args:          args,
			apiAddr:       apiAddr,
			stdOut:        &bytes.Buffer{},
			stdErr:        &bytes.Buffer{},
			runSeparately: runSeparately,
		}

		if !runSeparately {
			pr.cmd = exec.Command(pathToExec, args...)
			pr.cmd.Stdout = pr.stdOut
			pr.cmd.Stderr = pr.stdErr
			err := pr.cmd.Start()
			if err != nil {
				return nil, errors.Errorf("failed to start process: %w", err)
			}
		}
		var err error
		pr.relayClient, err = relay_api.NewClient("http://localhost" + apiAddr + "/api/v1")
		if err != nil {
			return nil, errors.Errorf("failed to create relay client: %w", err)
		}

		slog.Debug("Started process", "args", pr.args)

		prs = append(prs, pr)
	}

	if !runSeparately {
		prs.waitServerStarted(ctx)
	}

	return prs, nil
}

func (prs processes) waitServerStarted(ctx context.Context) {
	var startedCound int

	for i := range 100 {
		startedCound = 0
		for _, pr := range prs {
			if strings.Contains(pr.stdOut.String(), "All missing epochs loaded") {
				startedCound++
			}
		}
		if startedCound == len(prs) {
			break
		}
		slog.Info("Not all processes started successfully, retrying...", "attempt", i+1, "startedCount", startedCound, "totalCount", len(prs))

		time.Sleep(time.Second)
	}
	if startedCound != len(prs) {
		prs.printErrLogs()
		panic("Not all processes started successfully. Check logs for details.")
	}
	slog.InfoContext(ctx, "All processes started", "count", len(prs))
}

func (prs processes) stopProcesses() {
	for _, pr := range prs {
		if pr.runSeparately {
			continue
		}
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

func (prs processes) sendMessageToAllRelays(ctx context.Context, epoch uint64) (string, error) {
	message := randomMessage(sizeOfMessageBytes)
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

func randomMessage(n int) []byte {
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		panic(fmt.Sprintf("failed to generate random bytes: %v", err))
	}
	return b
}

func (prs processes) printErrLogs() {
	for _, pr := range prs {
		if pr.stdErr.Len() > 0 {
			slog.Error("Process stderr", "pid", pr.cmd.Process.Pid, "stderr", pr.stdErr.String())
		}
		if pr.stdOut.Len() > 0 {
			slog.Info("Process stdout", "pid", pr.cmd.Process.Pid, "stdout", pr.stdOut.String())
		}
	}
}
