// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract SettlementMock {
    function getRequiredKeyTagFromValSetHeaderAt(uint48) public pure returns (uint8) {
        return 15;
    }

    function getQuorumThresholdFromValSetHeaderAt(uint48) public pure returns (uint256) {
        return 100;
    }

    function getLastCommittedHeaderEpoch() public pure returns (uint48) {
        return 1;
    }

    function verifyQuorumSig(bytes calldata, uint8, uint256, bytes calldata) public pure returns (bool) {
        return true;
    }
}
