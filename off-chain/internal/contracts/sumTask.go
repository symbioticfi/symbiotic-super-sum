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

// SumTaskTask is an auto generated low-level Go binding around an user-defined struct.
type SumTaskTask struct {
	NumberA          *big.Int
	NumberB          *big.Int
	TaskCreatedBlock uint32
	RequiredEpoch    *big.Int
}

// SumTaskMetaData contains all meta data concerning the SumTask contract.
var SumTaskMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_settlement\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"TASK_RESPONSE_WINDOW_BLOCK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"allTaskResults\",\"inputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"allTasks\",\"inputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"taskCreatedBlock\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"requiredEpoch\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"createTask\",\"inputs\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getTaskStatus\",\"inputs\":[{\"name\":\"taskIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumSumTask.TaskStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isTaskResponded\",\"inputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"respondTask\",\"inputs\":[{\"name\":\"taskIndex\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"result\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settlement\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISettlement\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"tasksCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"NewTaskCreated\",\"inputs\":[{\"name\":\"taskIndex\",\"type\":\"uint32\",\"indexed\":true,\"internalType\":\"uint32\"},{\"name\":\"task\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structSumTask.Task\",\"components\":[{\"name\":\"numberA\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"numberB\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"taskCreatedBlock\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"requiredEpoch\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TaskResponded\",\"inputs\":[{\"name\":\"taskIndex\",\"type\":\"uint32\",\"indexed\":true,\"internalType\":\"uint32\"},{\"name\":\"result\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false}]",
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

// TASKRESPONSEWINDOWBLOCK is a free data retrieval call binding the contract method 0x1ad43189.
//
// Solidity: function TASK_RESPONSE_WINDOW_BLOCK() view returns(uint32)
func (_SumTask *SumTaskCaller) TASKRESPONSEWINDOWBLOCK(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "TASK_RESPONSE_WINDOW_BLOCK")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// TASKRESPONSEWINDOWBLOCK is a free data retrieval call binding the contract method 0x1ad43189.
//
// Solidity: function TASK_RESPONSE_WINDOW_BLOCK() view returns(uint32)
func (_SumTask *SumTaskSession) TASKRESPONSEWINDOWBLOCK() (uint32, error) {
	return _SumTask.Contract.TASKRESPONSEWINDOWBLOCK(&_SumTask.CallOpts)
}

// TASKRESPONSEWINDOWBLOCK is a free data retrieval call binding the contract method 0x1ad43189.
//
// Solidity: function TASK_RESPONSE_WINDOW_BLOCK() view returns(uint32)
func (_SumTask *SumTaskCallerSession) TASKRESPONSEWINDOWBLOCK() (uint32, error) {
	return _SumTask.Contract.TASKRESPONSEWINDOWBLOCK(&_SumTask.CallOpts)
}

// AllTaskResults is a free data retrieval call binding the contract method 0xd3879c37.
//
// Solidity: function allTaskResults(uint32 ) view returns(uint256)
func (_SumTask *SumTaskCaller) AllTaskResults(opts *bind.CallOpts, arg0 uint32) (*big.Int, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "allTaskResults", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AllTaskResults is a free data retrieval call binding the contract method 0xd3879c37.
//
// Solidity: function allTaskResults(uint32 ) view returns(uint256)
func (_SumTask *SumTaskSession) AllTaskResults(arg0 uint32) (*big.Int, error) {
	return _SumTask.Contract.AllTaskResults(&_SumTask.CallOpts, arg0)
}

// AllTaskResults is a free data retrieval call binding the contract method 0xd3879c37.
//
// Solidity: function allTaskResults(uint32 ) view returns(uint256)
func (_SumTask *SumTaskCallerSession) AllTaskResults(arg0 uint32) (*big.Int, error) {
	return _SumTask.Contract.AllTaskResults(&_SumTask.CallOpts, arg0)
}

// AllTasks is a free data retrieval call binding the contract method 0x82ee72e2.
//
// Solidity: function allTasks(uint32 ) view returns(uint256 numberA, uint256 numberB, uint32 taskCreatedBlock, uint48 requiredEpoch)
func (_SumTask *SumTaskCaller) AllTasks(opts *bind.CallOpts, arg0 uint32) (struct {
	NumberA          *big.Int
	NumberB          *big.Int
	TaskCreatedBlock uint32
	RequiredEpoch    *big.Int
}, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "allTasks", arg0)

	outstruct := new(struct {
		NumberA          *big.Int
		NumberB          *big.Int
		TaskCreatedBlock uint32
		RequiredEpoch    *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.NumberA = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.NumberB = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TaskCreatedBlock = *abi.ConvertType(out[2], new(uint32)).(*uint32)
	outstruct.RequiredEpoch = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// AllTasks is a free data retrieval call binding the contract method 0x82ee72e2.
//
// Solidity: function allTasks(uint32 ) view returns(uint256 numberA, uint256 numberB, uint32 taskCreatedBlock, uint48 requiredEpoch)
func (_SumTask *SumTaskSession) AllTasks(arg0 uint32) (struct {
	NumberA          *big.Int
	NumberB          *big.Int
	TaskCreatedBlock uint32
	RequiredEpoch    *big.Int
}, error) {
	return _SumTask.Contract.AllTasks(&_SumTask.CallOpts, arg0)
}

// AllTasks is a free data retrieval call binding the contract method 0x82ee72e2.
//
// Solidity: function allTasks(uint32 ) view returns(uint256 numberA, uint256 numberB, uint32 taskCreatedBlock, uint48 requiredEpoch)
func (_SumTask *SumTaskCallerSession) AllTasks(arg0 uint32) (struct {
	NumberA          *big.Int
	NumberB          *big.Int
	TaskCreatedBlock uint32
	RequiredEpoch    *big.Int
}, error) {
	return _SumTask.Contract.AllTasks(&_SumTask.CallOpts, arg0)
}

// GetTaskStatus is a free data retrieval call binding the contract method 0x8282e7f0.
//
// Solidity: function getTaskStatus(uint32 taskIndex) view returns(uint8)
func (_SumTask *SumTaskCaller) GetTaskStatus(opts *bind.CallOpts, taskIndex uint32) (uint8, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "getTaskStatus", taskIndex)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetTaskStatus is a free data retrieval call binding the contract method 0x8282e7f0.
//
// Solidity: function getTaskStatus(uint32 taskIndex) view returns(uint8)
func (_SumTask *SumTaskSession) GetTaskStatus(taskIndex uint32) (uint8, error) {
	return _SumTask.Contract.GetTaskStatus(&_SumTask.CallOpts, taskIndex)
}

// GetTaskStatus is a free data retrieval call binding the contract method 0x8282e7f0.
//
// Solidity: function getTaskStatus(uint32 taskIndex) view returns(uint8)
func (_SumTask *SumTaskCallerSession) GetTaskStatus(taskIndex uint32) (uint8, error) {
	return _SumTask.Contract.GetTaskStatus(&_SumTask.CallOpts, taskIndex)
}

// IsTaskResponded is a free data retrieval call binding the contract method 0x667f0f29.
//
// Solidity: function isTaskResponded(uint32 ) view returns(bool)
func (_SumTask *SumTaskCaller) IsTaskResponded(opts *bind.CallOpts, arg0 uint32) (bool, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "isTaskResponded", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsTaskResponded is a free data retrieval call binding the contract method 0x667f0f29.
//
// Solidity: function isTaskResponded(uint32 ) view returns(bool)
func (_SumTask *SumTaskSession) IsTaskResponded(arg0 uint32) (bool, error) {
	return _SumTask.Contract.IsTaskResponded(&_SumTask.CallOpts, arg0)
}

// IsTaskResponded is a free data retrieval call binding the contract method 0x667f0f29.
//
// Solidity: function isTaskResponded(uint32 ) view returns(bool)
func (_SumTask *SumTaskCallerSession) IsTaskResponded(arg0 uint32) (bool, error) {
	return _SumTask.Contract.IsTaskResponded(&_SumTask.CallOpts, arg0)
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

// TasksCount is a free data retrieval call binding the contract method 0xbb6a0f07.
//
// Solidity: function tasksCount() view returns(uint32)
func (_SumTask *SumTaskCaller) TasksCount(opts *bind.CallOpts) (uint32, error) {
	var out []interface{}
	err := _SumTask.contract.Call(opts, &out, "tasksCount")

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// TasksCount is a free data retrieval call binding the contract method 0xbb6a0f07.
//
// Solidity: function tasksCount() view returns(uint32)
func (_SumTask *SumTaskSession) TasksCount() (uint32, error) {
	return _SumTask.Contract.TasksCount(&_SumTask.CallOpts)
}

// TasksCount is a free data retrieval call binding the contract method 0xbb6a0f07.
//
// Solidity: function tasksCount() view returns(uint32)
func (_SumTask *SumTaskCallerSession) TasksCount() (uint32, error) {
	return _SumTask.Contract.TasksCount(&_SumTask.CallOpts)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(uint32)
func (_SumTask *SumTaskTransactor) CreateTask(opts *bind.TransactOpts, numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.contract.Transact(opts, "createTask", numberA, numberB)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(uint32)
func (_SumTask *SumTaskSession) CreateTask(numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.Contract.CreateTask(&_SumTask.TransactOpts, numberA, numberB)
}

// CreateTask is a paid mutator transaction binding the contract method 0xe75b2378.
//
// Solidity: function createTask(uint256 numberA, uint256 numberB) returns(uint32)
func (_SumTask *SumTaskTransactorSession) CreateTask(numberA *big.Int, numberB *big.Int) (*types.Transaction, error) {
	return _SumTask.Contract.CreateTask(&_SumTask.TransactOpts, numberA, numberB)
}

// RespondTask is a paid mutator transaction binding the contract method 0xd181bbbd.
//
// Solidity: function respondTask(uint32 taskIndex, uint256 result, bytes proof) returns()
func (_SumTask *SumTaskTransactor) RespondTask(opts *bind.TransactOpts, taskIndex uint32, result *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.contract.Transact(opts, "respondTask", taskIndex, result, proof)
}

// RespondTask is a paid mutator transaction binding the contract method 0xd181bbbd.
//
// Solidity: function respondTask(uint32 taskIndex, uint256 result, bytes proof) returns()
func (_SumTask *SumTaskSession) RespondTask(taskIndex uint32, result *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.Contract.RespondTask(&_SumTask.TransactOpts, taskIndex, result, proof)
}

// RespondTask is a paid mutator transaction binding the contract method 0xd181bbbd.
//
// Solidity: function respondTask(uint32 taskIndex, uint256 result, bytes proof) returns()
func (_SumTask *SumTaskTransactorSession) RespondTask(taskIndex uint32, result *big.Int, proof []byte) (*types.Transaction, error) {
	return _SumTask.Contract.RespondTask(&_SumTask.TransactOpts, taskIndex, result, proof)
}

// SumTaskNewTaskCreatedIterator is returned from FilterNewTaskCreated and is used to iterate over the raw logs and unpacked data for NewTaskCreated events raised by the SumTask contract.
type SumTaskNewTaskCreatedIterator struct {
	Event *SumTaskNewTaskCreated // Event containing the contract specifics and raw log

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
func (it *SumTaskNewTaskCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SumTaskNewTaskCreated)
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
		it.Event = new(SumTaskNewTaskCreated)
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
func (it *SumTaskNewTaskCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SumTaskNewTaskCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SumTaskNewTaskCreated represents a NewTaskCreated event raised by the SumTask contract.
type SumTaskNewTaskCreated struct {
	TaskIndex uint32
	Task      SumTaskTask
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterNewTaskCreated is a free log retrieval operation binding the contract event 0xc0cb9c28c78053682611e0a1398edcb2674b6fad7bee9358f7cfe8b15c11c46e.
//
// Solidity: event NewTaskCreated(uint32 indexed taskIndex, (uint256,uint256,uint32,uint48) task)
func (_SumTask *SumTaskFilterer) FilterNewTaskCreated(opts *bind.FilterOpts, taskIndex []uint32) (*SumTaskNewTaskCreatedIterator, error) {

	var taskIndexRule []interface{}
	for _, taskIndexItem := range taskIndex {
		taskIndexRule = append(taskIndexRule, taskIndexItem)
	}

	logs, sub, err := _SumTask.contract.FilterLogs(opts, "NewTaskCreated", taskIndexRule)
	if err != nil {
		return nil, err
	}
	return &SumTaskNewTaskCreatedIterator{contract: _SumTask.contract, event: "NewTaskCreated", logs: logs, sub: sub}, nil
}

// WatchNewTaskCreated is a free log subscription operation binding the contract event 0xc0cb9c28c78053682611e0a1398edcb2674b6fad7bee9358f7cfe8b15c11c46e.
//
// Solidity: event NewTaskCreated(uint32 indexed taskIndex, (uint256,uint256,uint32,uint48) task)
func (_SumTask *SumTaskFilterer) WatchNewTaskCreated(opts *bind.WatchOpts, sink chan<- *SumTaskNewTaskCreated, taskIndex []uint32) (event.Subscription, error) {

	var taskIndexRule []interface{}
	for _, taskIndexItem := range taskIndex {
		taskIndexRule = append(taskIndexRule, taskIndexItem)
	}

	logs, sub, err := _SumTask.contract.WatchLogs(opts, "NewTaskCreated", taskIndexRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SumTaskNewTaskCreated)
				if err := _SumTask.contract.UnpackLog(event, "NewTaskCreated", log); err != nil {
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

// ParseNewTaskCreated is a log parse operation binding the contract event 0xc0cb9c28c78053682611e0a1398edcb2674b6fad7bee9358f7cfe8b15c11c46e.
//
// Solidity: event NewTaskCreated(uint32 indexed taskIndex, (uint256,uint256,uint32,uint48) task)
func (_SumTask *SumTaskFilterer) ParseNewTaskCreated(log types.Log) (*SumTaskNewTaskCreated, error) {
	event := new(SumTaskNewTaskCreated)
	if err := _SumTask.contract.UnpackLog(event, "NewTaskCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SumTaskTaskRespondedIterator is returned from FilterTaskResponded and is used to iterate over the raw logs and unpacked data for TaskResponded events raised by the SumTask contract.
type SumTaskTaskRespondedIterator struct {
	Event *SumTaskTaskResponded // Event containing the contract specifics and raw log

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
func (it *SumTaskTaskRespondedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SumTaskTaskResponded)
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
		it.Event = new(SumTaskTaskResponded)
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
func (it *SumTaskTaskRespondedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SumTaskTaskRespondedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SumTaskTaskResponded represents a TaskResponded event raised by the SumTask contract.
type SumTaskTaskResponded struct {
	TaskIndex uint32
	Result    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterTaskResponded is a free log retrieval operation binding the contract event 0x9d8cbde9c8bf25180d70df692a5985b2234c9c0fca52c90ec57f7f583186b028.
//
// Solidity: event TaskResponded(uint32 indexed taskIndex, uint256 result)
func (_SumTask *SumTaskFilterer) FilterTaskResponded(opts *bind.FilterOpts, taskIndex []uint32) (*SumTaskTaskRespondedIterator, error) {

	var taskIndexRule []interface{}
	for _, taskIndexItem := range taskIndex {
		taskIndexRule = append(taskIndexRule, taskIndexItem)
	}

	logs, sub, err := _SumTask.contract.FilterLogs(opts, "TaskResponded", taskIndexRule)
	if err != nil {
		return nil, err
	}
	return &SumTaskTaskRespondedIterator{contract: _SumTask.contract, event: "TaskResponded", logs: logs, sub: sub}, nil
}

// WatchTaskResponded is a free log subscription operation binding the contract event 0x9d8cbde9c8bf25180d70df692a5985b2234c9c0fca52c90ec57f7f583186b028.
//
// Solidity: event TaskResponded(uint32 indexed taskIndex, uint256 result)
func (_SumTask *SumTaskFilterer) WatchTaskResponded(opts *bind.WatchOpts, sink chan<- *SumTaskTaskResponded, taskIndex []uint32) (event.Subscription, error) {

	var taskIndexRule []interface{}
	for _, taskIndexItem := range taskIndex {
		taskIndexRule = append(taskIndexRule, taskIndexItem)
	}

	logs, sub, err := _SumTask.contract.WatchLogs(opts, "TaskResponded", taskIndexRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SumTaskTaskResponded)
				if err := _SumTask.contract.UnpackLog(event, "TaskResponded", log); err != nil {
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

// ParseTaskResponded is a log parse operation binding the contract event 0x9d8cbde9c8bf25180d70df692a5985b2234c9c0fca52c90ec57f7f583186b028.
//
// Solidity: event TaskResponded(uint32 indexed taskIndex, uint256 result)
func (_SumTask *SumTaskFilterer) ParseTaskResponded(log types.Log) (*SumTaskTaskResponded, error) {
	event := new(SumTaskTaskResponded)
	if err := _SumTask.contract.UnpackLog(event, "TaskResponded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
