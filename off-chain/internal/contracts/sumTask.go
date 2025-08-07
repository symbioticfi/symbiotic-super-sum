// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contracts

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// SumTaskResponse is an auto generated low-level Go binding around an user-defined struct.
type SumTaskResponse struct {
	AnsweredAt *big.Int
	Answer     *big.Int
}

// SumTaskTask is an auto generated low-level Go binding around an user-defined struct.
type SumTaskTask struct {
	NumberA   *big.Int
	NumberB   *big.Int
	Nonce     *big.Int
	CreatedAt *big.Int
}

// SumTaskMetaData contains all meta data concerning the SumTask contract.
var SumTaskMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_settlement\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"TASK_EXPIRY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"createTask\",\"inputs\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"taskId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getTaskStatus\",\"inputs\":[{\"name\":\"taskId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumSumTask.TaskStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"nonce\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"respondTask\",\"inputs\":[{\"name\":\"taskId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"result\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"epoch\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"responses\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"answeredAt\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"answer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"settlement\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISettlement\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"tasks\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"CreateTask\",\"inputs\":[{\"name\":\"taskId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"task\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structSumTask.Task\",\"components\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RespondTask\",\"inputs\":[{\"name\":\"taskId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"response\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structSumTask.Response\",\"components\":[{\"name\":\"answeredAt\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"answer\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AlreadyResponded\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidQuorumSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidVerifyingEpoch\",\"inputs\":[]}]",
}

// SumTaskABI is the input ABI used to generate the binding from.
// Deprecated: Use SumTaskMetaData.ABI instead.
var SumTaskABI = SumTaskMetaData.ABI

// SumTask is an auto generated Go binding around an Ethereum contract.
type SumTask struct {
	SumTaskCaller     // Read-only binding to the contract
	SumTaskTransactor // Write-only binding to the contract
	SumTaskFilterer   // Log filterer for contract events
}

// SumTaskCaller is an auto generated read-only Go binding around an Ethereum contract.
type SumTaskCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SumTaskTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SumTaskTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SumTaskFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SumTaskFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SumTaskSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SumTaskSession struct {
	Contract     *SumTask          // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SumTaskCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SumTaskCallerSession struct {
	Contract *SumTaskCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts  // Call options to use throughout this session
}

// SumTaskTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SumTaskTransactorSession struct {
	Contract     *SumTaskTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// SumTaskRaw is an auto generated low-level Go binding around an Ethereum contract.
type SumTaskRaw struct {
	Contract *SumTask // Generic contract binding to access the raw methods on
}

// SumTaskCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SumTaskCallerRaw struct {
	Contract *SumTaskCaller // Generic read-only contract binding to access the raw methods on
}

// SumTaskTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SumTaskTransactorRaw struct {
	Contract *SumTaskTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSumTask creates a new instance of SumTask, bound to a specific deployed contract.
func NewSumTask(address common.Address, backend bind.ContractBackend) (*SumTask, error) {
	contract, err := bindSumTask(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SumTask{SumTaskCaller: SumTaskCaller{contract: contract}, SumTaskTransactor: SumTaskTransactor{contract: contract}, SumTaskFilterer: SumTaskFilterer{contract: contract}}, nil
}

// NewSumTaskCaller creates a new read-only instance of SumTask, bound to a specific deployed contract.
func NewSumTaskCaller(address common.Address, caller bind.ContractCaller) (*SumTaskCaller, error) {
	contract, err := bindSumTask(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SumTaskCaller{contract: contract}, nil
}

// NewSumTaskTransactor creates a new write-only instance of SumTask, bound to a specific deployed contract.
func NewSumTaskTransactor(address common.Address, transactor bind.ContractTransactor) (*SumTaskTransactor, error) {
	contract, err := bindSumTask(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SumTaskTransactor{contract: contract}, nil
}

// NewSumTaskFilterer creates a new log filterer instance of SumTask, bound to a specific deployed contract.
func NewSumTaskFilterer(address common.Address, filterer bind.ContractFilterer) (*SumTaskFilterer, error) {
	contract, err := bindSumTask(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SumTaskFilterer{contract: contract}, nil
}

// bindSumTask binds a generic wrapper to an already deployed contract.
func bindSumTask(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SumTaskMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SumTask *SumTaskRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SumTask.Contract.SumTaskCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SumTask *SumTaskRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SumTask.Contract.SumTaskTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SumTask *SumTaskRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SumTask.Contract.SumTaskTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SumTask *SumTaskCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SumTask.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SumTask *SumTaskTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SumTask.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SumTask *SumTaskTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SumTask.Contract.contract.Transact(opts, method, params...)
}

// TASKEXPIRY is a free data retrieval call binding the contract method 0x240697b6.
//
// Solidity: function TASK_EXPIRY() view returns(uint32)
func (_SumTask *SumTaskCaller) TASKEXPIRY(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "TASK_EXPIRY")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// TASKEXPIRY is a free data retrieval call binding the contract method 0x240697b6.
//
// Solidity: function TASK_EXPIRY() view returns(uint32)
func (_SumTask *SumTaskSession) TASKEXPIRY() (uint32, error) {
	return _SumTask.Contract.TASKEXPIRY(&_SumTask.CallOpts)
}

// TASKEXPIRY is a free data retrieval call binding the contract method 0x240697b6.
//
// Solidity: function TASK_EXPIRY() view returns(uint32)
func (_SumTask *SumTaskCallerSession) TASKEXPIRY() (uint32, error) {
	return _SumTask.Contract.TASKEXPIRY(&_SumTask.CallOpts)
}

// GetTaskStatus is a free data retrieval call binding the contract method 0x2bf6cc79.
//
// Solidity: function getTaskStatus(bytes32 taskId) view returns(uint8)
func (_SumTask *SumTaskCaller) GetTaskStatus(opts *bind.CallOpts, taskId [32]byte) (uint8, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "getTaskStatus", taskId)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetTaskStatus is a free data retrieval call binding the contract method 0x2bf6cc79.
//
// Solidity: function getTaskStatus(bytes32 taskId) view returns(uint8)
func (_SumTask *SumTaskSession) GetTaskStatus(taskId [32]byte) (uint8, error) {
	return _SumTask.Contract.GetTaskStatus(&_SumTask.CallOpts, taskId)
}

// GetTaskStatus is a free data retrieval call binding the contract method 0x2bf6cc79.
//
// Solidity: function getTaskStatus(bytes32 taskId) view returns(uint8)
func (_SumTask *SumTaskCallerSession) GetTaskStatus(taskId [32]byte) (uint8, error) {
	return _SumTask.Contract.GetTaskStatus(&_SumTask.CallOpts, taskId)
}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_SumTask *SumTaskCaller) Nonce(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "nonce")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_SumTask *SumTaskSession) Nonce() (*big.Int, error) {
	return _SumTask.Contract.Nonce(&_SumTask.CallOpts)
}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_SumTask *SumTaskCallerSession) Nonce() (*big.Int, error) {
	return _SumTask.Contract.Nonce(&_SumTask.CallOpts)
}

// Responses is a free data retrieval call binding the contract method 0x72164a6c.
//
// Solidity: function responses(bytes32 ) view returns(uint48 answeredAt, uint256 answer)
func (_SumTask *SumTaskCaller) Responses(opts *bind.CallOpts, arg0 [32]byte) (struct {
	AnsweredAt *big.Int
	Answer     *big.Int
}, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "responses", arg0)

	outstruct := new(struct {
		AnsweredAt *big.Int
		Answer     *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.AnsweredAt = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Answer = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Responses is a free data retrieval call binding the contract method 0x72164a6c.
//
// Solidity: function responses(bytes32 ) view returns(uint48 answeredAt, uint256 answer)
func (_SumTask *SumTaskSession) Responses(arg0 [32]byte) (struct {
	AnsweredAt *big.Int
	Answer     *big.Int
}, error) {
	return _SumTask.Contract.Responses(&_SumTask.CallOpts, arg0)
}

// Responses is a free data retrieval call binding the contract method 0x72164a6c.
//
// Solidity: function responses(bytes32 ) view returns(uint48 answeredAt, uint256 answer)
func (_SumTask *SumTaskCallerSession) Responses(arg0 [32]byte) (struct {
	AnsweredAt *big.Int
	Answer     *big.Int
}, error) {
	return _SumTask.Contract.Responses(&_SumTask.CallOpts, arg0)
}

// Settlement is a free data retrieval call binding the contract method 0x51160630.
//
// Solidity: function settlement() view returns(address)
func (_SumTask *SumTaskCaller) Settlement(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "settlement")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Settlement is a free data retrieval call binding the contract method 0x51160630.
//
// Solidity: function settlement() view returns(address)
func (_SumTask *SumTaskSession) Settlement() (common.Address, error) {
	return _SumTask.Contract.Settlement(&_SumTask.CallOpts)
}

// Settlement is a free data retrieval call binding the contract method 0x51160630.
//
// Solidity: function settlement() view returns(address)
func (_SumTask *SumTaskCallerSession) Settlement() (common.Address, error) {
	return _SumTask.Contract.Settlement(&_SumTask.CallOpts)
}

// Tasks is a free data retrieval call binding the contract method 0xe579f500.
//
// Solidity: function tasks(bytes32 ) view returns(uint256 numberA, uint256 numberB, uint256 nonce, uint48 createdAt)
func (_SumTask *SumTaskCaller) Tasks(opts *bind.CallOpts, arg0 [32]byte) (struct {
	NumberA   *big.Int
	NumberB   *big.Int
	Nonce     *big.Int
	CreatedAt *big.Int
}, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "tasks", arg0)

	outstruct := new(struct {
		NumberA   *big.Int
		NumberB   *big.Int
		Nonce     *big.Int
		CreatedAt *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.NumberA = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.NumberB = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Nonce = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.CreatedAt = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Tasks is a free data retrieval call binding the contract method 0xe579f500.
//
// Solidity: function tasks(bytes32 ) view returns(uint256 numberA, uint256 numberB, uint256 nonce, uint48 createdAt)
func (_SumTask *SumTaskSession) Tasks(arg0 [32]byte) (struct {
	NumberA   *big.Int
	NumberB   *big.Int
	Nonce     *big.Int
	CreatedAt *big.Int
}, error) {
	return _SumTask.Contract.Tasks(&_SumTask.CallOpts, arg0)
}

// Tasks is a free data retrieval call binding the contract method 0xe579f500.
//
// Solidity: function tasks(bytes32 ) view returns(uint256 numberA, uint256 numberB, uint256 nonce, uint48 createdAt)
func (_SumTask *SumTaskCallerSession) Tasks(arg0 [32]byte) (struct {
	NumberA   *big.Int
	NumberB   *big.Int
	Nonce     *big.Int
	CreatedAt *big.Int
}, error) {
	return _SumTask.Contract.Tasks(&_SumTask.CallOpts, arg0)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(bytes32 taskId)
func (_SumTask *SumTaskTransactor) CreateTask(opts *bind.TransactOpts, numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.contract.Transact(opts, "createTask", numberA, numberB)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(bytes32 taskId)
func (_SumTask *SumTaskSession) CreateTask(numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.Contract.CreateTask(&_SumTask.TransactOpts, numberA, numberB)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(bytes32 taskId)
func (_SumTask *SumTaskTransactorSession) CreateTask(numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.Contract.CreateTask(&_SumTask.TransactOpts, numberA, numberB)
}

// RespondTask is a paid mutator transaction binding the contract method 0xc92914cd.
//
// Solidity: function respondTask(bytes32 taskId, uint256 result, uint48 epoch, bytes proof) returns()
func (_SumTask *SumTaskTransactor) RespondTask(opts *bind.TransactOpts, taskId [32]byte, result *big.Int, epoch *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.contract.Transact(opts, "respondTask", taskId, result, epoch, proof)
}

// RespondTask is a paid mutator transaction binding the contract method 0xc92914cd.
//
// Solidity: function respondTask(bytes32 taskId, uint256 result, uint48 epoch, bytes proof) returns()
func (_SumTask *SumTaskSession) RespondTask(taskId [32]byte, result *big.Int, epoch *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.Contract.RespondTask(&_SumTask.TransactOpts, taskId, result, epoch, proof)
}

// RespondTask is a paid mutator transaction binding the contract method 0xc92914cd.
//
// Solidity: function respondTask(bytes32 taskId, uint256 result, uint48 epoch, bytes proof) returns()
func (_SumTask *SumTaskTransactorSession) RespondTask(taskId [32]byte, result *big.Int, epoch *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.Contract.RespondTask(&_SumTask.TransactOpts, taskId, result, epoch, proof)
}

// SumTaskCreateTaskIterator is returned from FilterCreateTask and is used to iterate over the raw logs and unpacked data for CreateTask events raised by the SumTask contract.
type SumTaskCreateTaskIterator struct {
	Event *SumTaskCreateTask // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SumTaskCreateTaskIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SumTaskCreateTask)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SumTaskCreateTask)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SumTaskCreateTaskIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SumTaskCreateTaskIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SumTaskCreateTask represents a CreateTask event raised by the SumTask contract.
type SumTaskCreateTask struct {
	TaskId [32]byte
	Task   SumTaskTask
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterCreateTask is a free log retrieval operation binding the contract event 0x091f91724daf92df11de4c7b494af095ec9c1325865974e9750636fbe5373677.
//
// Solidity: event CreateTask(bytes32 indexed taskId, (uint256,uint256,uint256,uint48) task)
func (_SumTask *SumTaskFilterer) FilterCreateTask(opts *bind.FilterOpts, taskId [][32]byte) (*SumTaskCreateTaskIterator, error) {

	var taskIdRule []interface{}
	for _, taskIdItem := range taskId {
		taskIdRule = append(taskIdRule, taskIdItem)
	}

	logs, sub, err := _SumTask.contract.FilterLogs(opts, "CreateTask", taskIdRule)
	if err != nil {
		return nil, err
	}
	return &SumTaskCreateTaskIterator{contract: _SumTask.contract, event: "CreateTask", logs: logs, sub: sub}, nil
}

// WatchCreateTask is a free log subscription operation binding the contract event 0x091f91724daf92df11de4c7b494af095ec9c1325865974e9750636fbe5373677.
//
// Solidity: event CreateTask(bytes32 indexed taskId, (uint256,uint256,uint256,uint48) task)
func (_SumTask *SumTaskFilterer) WatchCreateTask(opts *bind.WatchOpts, sink chan<- *SumTaskCreateTask, taskId [][32]byte) (event.Subscription, error) {

	var taskIdRule []interface{}
	for _, taskIdItem := range taskId {
		taskIdRule = append(taskIdRule, taskIdItem)
	}

	logs, sub, err := _SumTask.contract.WatchLogs(opts, "CreateTask", taskIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SumTaskCreateTask)
				if err := _SumTask.contract.UnpackLog(event, "CreateTask", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCreateTask is a log parse operation binding the contract event 0x091f91724daf92df11de4c7b494af095ec9c1325865974e9750636fbe5373677.
//
// Solidity: event CreateTask(bytes32 indexed taskId, (uint256,uint256,uint256,uint48) task)
func (_SumTask *SumTaskFilterer) ParseCreateTask(log types.Log) (*SumTaskCreateTask, error) {
	event := new(SumTaskCreateTask)
	if err := _SumTask.contract.UnpackLog(event, "CreateTask", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SumTaskRespondTaskIterator is returned from FilterRespondTask and is used to iterate over the raw logs and unpacked data for RespondTask events raised by the SumTask contract.
type SumTaskRespondTaskIterator struct {
	Event *SumTaskRespondTask // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SumTaskRespondTaskIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SumTaskRespondTask)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SumTaskRespondTask)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SumTaskRespondTaskIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SumTaskRespondTaskIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SumTaskRespondTask represents a RespondTask event raised by the SumTask contract.
type SumTaskRespondTask struct {
	TaskId   [32]byte
	Response SumTaskResponse
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterRespondTask is a free log retrieval operation binding the contract event 0xfc4f6d5b11d191a9cdec60e7a5819b4695dba8d8365e7afb1f24b159ceb7e287.
//
// Solidity: event RespondTask(bytes32 indexed taskId, (uint48,uint256) response)
func (_SumTask *SumTaskFilterer) FilterRespondTask(opts *bind.FilterOpts, taskId [][32]byte) (*SumTaskRespondTaskIterator, error) {

	var taskIdRule []interface{}
	for _, taskIdItem := range taskId {
		taskIdRule = append(taskIdRule, taskIdItem)
	}

	logs, sub, err := _SumTask.contract.FilterLogs(opts, "RespondTask", taskIdRule)
	if err != nil {
		return nil, err
	}
	return &SumTaskRespondTaskIterator{contract: _SumTask.contract, event: "RespondTask", logs: logs, sub: sub}, nil
}

// WatchRespondTask is a free log subscription operation binding the contract event 0xfc4f6d5b11d191a9cdec60e7a5819b4695dba8d8365e7afb1f24b159ceb7e287.
//
// Solidity: event RespondTask(bytes32 indexed taskId, (uint48,uint256) response)
func (_SumTask *SumTaskFilterer) WatchRespondTask(opts *bind.WatchOpts, sink chan<- *SumTaskRespondTask, taskId [][32]byte) (event.Subscription, error) {

	var taskIdRule []interface{}
	for _, taskIdItem := range taskId {
		taskIdRule = append(taskIdRule, taskIdItem)
	}

	logs, sub, err := _SumTask.contract.WatchLogs(opts, "RespondTask", taskIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SumTaskRespondTask)
				if err := _SumTask.contract.UnpackLog(event, "RespondTask", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRespondTask is a log parse operation binding the contract event 0xfc4f6d5b11d191a9cdec60e7a5819b4695dba8d8365e7afb1f24b159ceb7e287.
//
// Solidity: event RespondTask(bytes32 indexed taskId, (uint48,uint256) response)
func (_SumTask *SumTaskFilterer) ParseRespondTask(log types.Log) (*SumTaskRespondTask, error) {
	event := new(SumTaskRespondTask)
	if err := _SumTask.contract.UnpackLog(event, "RespondTask", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
