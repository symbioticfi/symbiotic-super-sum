package contracts

import (
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

// VotingPowers provides the minimal binding needed for submitting slash transactions.
type VotingPowers struct {
	contract *bind.BoundContract
}

const votingPowersABI = `[{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint48","name":"captureTimestamp","type":"uint48"}],"name":"slash","outputs":[],"stateMutability":"nonpayable","type":"function"}]`

// NewVotingPowers creates a new instance of VotingPowers for the provided address and backend.
func NewVotingPowers(address common.Address, backend bind.ContractBackend) (*VotingPowers, error) {
	parsed, err := abi.JSON(strings.NewReader(votingPowersABI))
	if err != nil {
		return nil, err
	}

	contract := bind.NewBoundContract(address, parsed, backend, backend, backend)
	return &VotingPowers{contract: contract}, nil
}

// Slash submits a transaction calling VotingPowers.slash.
func (vp *VotingPowers) Slash(opts *bind.TransactOpts, operator common.Address, amount *big.Int, captureTimestamp *big.Int) (*types.Transaction, error) {
	return vp.contract.Transact(opts, "slash", operator, amount, captureTimestamp)
}
