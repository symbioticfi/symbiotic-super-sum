// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ICreateX {
    struct Values {
        uint256 constructorAmount;
        uint256 initCallAmount;
    }

    function deployCreate3(bytes32 salt, bytes memory initCode) external payable returns (address);
    function deployCreate3AndInit(
        bytes32 salt,
        bytes memory code,
        bytes memory data,
        Values memory values
    ) external returns (address);
}
