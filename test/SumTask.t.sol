// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SumTask} from "../src/SumTask.sol";
import {SettlementMock} from "./mock/SettlementMock.sol";

contract SumTaskTest is Test {
    SumTask public sumTask;

    function setUp() public {
        sumTask = new SumTask(address(new SettlementMock()));
    }

    function test_CreateTask() public {
        sumTask.createTask(50, 50);
        assertEq(sumTask.nonce(), 1);
    }

    function test_RespondToTask() public {
        bytes32 taskId = sumTask.createTask(50, 50);
        sumTask.respondTask(taskId, 100, 1, new bytes(0));
        (uint48 answeredAt, uint256 answer) = sumTask.responses(taskId);
        assertEq(answer, 100);
        assertEq(answeredAt, uint48(block.timestamp));
    }
}
