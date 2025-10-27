// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract SettlementMock {
    function getRequiredKeyTagFromValSetHeaderAt(uint48) public pure returns (uint8) {
        return 15;
    }

    function getQuorumThresholdFromValSetHeaderAt(uint48) public pure returns (uint256) {
        return 100;
    }

    function getCaptureTimestampFromValSetHeaderAt(uint48) public pure returns (uint48) {
        return 1_753_887_460;
    }

    function getLastCommittedHeaderEpoch() public pure returns (uint48) {
        return 1;
    }

    function verifyQuorumSigAt(bytes calldata, uint8, uint256, bytes calldata, uint48, bytes calldata)
        public
        pure
        returns (bool)
    {
        return true;
    }

    function verifyQuorumSig(bytes calldata, uint8, uint256, bytes calldata) public pure returns (bool) {
        return true;
    }
}
