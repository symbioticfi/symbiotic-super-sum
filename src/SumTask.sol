// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISettlement} from "@symbioticfi/relay-contracts/interfaces/modules/settlement/ISettlement.sol";

contract SumTask {
    struct Task {
        uint256 numberA;
        uint256 numberB;
        uint32 taskCreatedBlock;
        uint48 requiredEpoch;
    }

    enum TaskStatus {
        CREATED,
        RESPONDED,
        EXPIRED,
        NOT_FOUND
    }

    event NewTaskCreated(uint32 indexed taskIndex, Task task);

    event TaskResponded(uint32 indexed taskIndex, uint256 result);

    uint32 public immutable TASK_RESPONSE_WINDOW_BLOCK = 1000;

    ISettlement public settlement;

    uint32 public tasksCount;

    mapping(uint32 => Task) public allTasks;

    mapping(uint32 => uint256) public allTaskResults;

    mapping(uint32 => bool) public isTaskResponded;

    constructor(address _settlement) {
        settlement = ISettlement(_settlement);
    }

    function getTaskStatus(uint32 taskIndex) external view returns (TaskStatus) {
        if (taskIndex >= tasksCount) {
            return TaskStatus.NOT_FOUND;
        }

        Task memory task = allTasks[taskIndex];

        if (uint32(block.number) > task.taskCreatedBlock + TASK_RESPONSE_WINDOW_BLOCK) {
            return TaskStatus.EXPIRED;
        }

        if (isTaskResponded[taskIndex]) {
            return TaskStatus.RESPONDED;
        }

        return TaskStatus.CREATED;
    }

    function createTask(uint256 numberA, uint256 numberB) external returns (uint32) {
        Task memory newTask = Task({
            numberA: numberA,
            numberB: numberB,
            taskCreatedBlock: uint32(block.number),
            requiredEpoch: settlement.getLastCommittedHeaderEpoch()
        });

        allTasks[tasksCount] = newTask;
        emit NewTaskCreated(tasksCount, newTask);

        return tasksCount++;
    }

    function respondTask(uint32 taskIndex, uint256 result, bytes calldata proof) external {
        // check task is exists
        require(taskIndex < tasksCount, "Task does not exist");

        Task memory task = allTasks[taskIndex];

        // check that the task is within the response window
        require(
            uint32(block.number) <= task.taskCreatedBlock + TASK_RESPONSE_WINDOW_BLOCK, "Responded to the task too late"
        );

        // verify the quorum signature
        bool isValid = settlement.verifyQuorumSigAt(
            abi.encode(keccak256(abi.encode(taskIndex, result))),
            settlement.getRequiredKeyTagFromValSetHeaderAt(task.requiredEpoch),
            settlement.getQuorumThresholdFromValSetHeaderAt(task.requiredEpoch),
            proof,
            task.requiredEpoch,
            new bytes(0)
        );
        require(isValid, "Invalid quorum signature");

        allTaskResults[taskIndex] = result;
        isTaskResponded[taskIndex] = true;

        emit TaskResponded(taskIndex, result);
    }
}
