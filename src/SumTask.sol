// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISettlement} from "@symbioticfi/relay-contracts/src/interfaces/modules/settlement/ISettlement.sol";

contract SumTask {
    error AlreadyResponded();
    error InvalidQuorumSignature();
    error InvalidVerifyingEpoch();

    enum TaskStatus {
        CREATED,
        RESPONDED,
        EXPIRED,
        NOT_FOUND
    }

    struct Task {
        uint256 numberA;
        uint256 numberB;
        uint256 nonce;
        uint48 createdAt;
    }

    struct Response {
        uint48 answeredAt;
        uint256 answer;
    }

    event CreateTask(bytes32 indexed taskId, Task task);

    event RespondTask(bytes32 indexed taskId, Response response);

    uint32 public constant TASK_EXPIRY = 12_000;

    ISettlement public settlement;

    uint256 public nonce;

    mapping(bytes32 => Task) public tasks;

    mapping(bytes32 => Response) public responses;

    constructor(address _settlement) {
        settlement = ISettlement(_settlement);
    }

    function getTaskStatus(bytes32 taskId) public view returns (TaskStatus) {
        if (responses[taskId].answeredAt > 0) {
            return TaskStatus.RESPONDED;
        }

        if (tasks[taskId].createdAt == 0) {
            return TaskStatus.NOT_FOUND;
        }

        if (block.timestamp > tasks[taskId].createdAt + TASK_EXPIRY) {
            return TaskStatus.EXPIRED;
        }

        return TaskStatus.CREATED;
    }

    function createTask(uint256 numberA, uint256 numberB) public returns (bytes32 taskId) {
        uint256 nonce_ = nonce++;
        Task memory task = Task({numberA: numberA, numberB: numberB, nonce: nonce_, createdAt: uint48(block.timestamp)});
        taskId = keccak256(abi.encode(block.chainid, numberA, numberB, nonce_));
        tasks[taskId] = task;

        emit CreateTask(taskId, task);
    }

    function respondTask(bytes32 taskId, uint256 result, uint48 epoch, bytes calldata proof) public {
        // check if the task is not responded yet
        if (responses[taskId].answeredAt > 0) {
            revert AlreadyResponded();
        }

        // verify that the verifying epoch is not stale
        uint48 nextEpochCaptureTimestamp = settlement.getCaptureTimestampFromValSetHeaderAt(epoch + 1);
        if (nextEpochCaptureTimestamp > 0 && block.timestamp >= nextEpochCaptureTimestamp + TASK_EXPIRY) {
            revert InvalidVerifyingEpoch();
        }

        // verify the quorum signature
        if (!settlement.verifyQuorumSigAt(
                abi.encode(keccak256(abi.encode(taskId, result))),
                settlement.getRequiredKeyTagFromValSetHeaderAt(epoch),
                settlement.getQuorumThresholdFromValSetHeaderAt(epoch),
                proof,
                epoch,
                new bytes(0)
            )) {
            revert InvalidQuorumSignature();
        }

        Response memory response = Response({answeredAt: uint48(block.timestamp), answer: result});
        responses[taskId] = response;

        emit RespondTask(taskId, response);
    }
}
