// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ICreateX {
    function deployCreate3(bytes32 salt, bytes memory initCode) external payable returns (address);
}