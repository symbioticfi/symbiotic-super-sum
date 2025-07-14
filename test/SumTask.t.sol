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
        assertEq(sumTask.tasksCount(), 1);
    }

    function test_RespondToTask() public {
        sumTask.createTask(50, 50);
        sumTask.respondTask(0, 100, new bytes(0));
        assertEq(sumTask.allTaskResults(0), 100);
    }
}
