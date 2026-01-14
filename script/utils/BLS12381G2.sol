// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BLS12381} from "@symbioticfi/relay-contracts/src/libraries/utils/BLS12381.sol";

/**
 * @title BLS12381G2
 * @notice Utility library for BLS12-381 G2 operations using precompiles
 * @dev Uses EIP-2537 precompiles for G2 scalar multiplication
 */
library BLS12381G2 {
    /**
     * @notice Precompile address for G2 scalar multiplication
     */
    address internal constant BLS12_G2MSM = 0x000000000000000000000000000000000000000E;

    /**
     * @notice Reverts when G2 scalar multiplication fails
     */
    error G2MSMFailed();

    /**
     * @notice Performs scalar multiplication on a G2 point
     * @param scalar The scalar to multiply by
     * @param g2Point The G2 point to multiply
     * @return result The resulting G2 point after scalar multiplication
     */
    function scalarMul(
        uint256 scalar,
        BLS12381.G2Point memory g2Point
    ) internal view returns (BLS12381.G2Point memory result) {
        assembly ("memory-safe") {
            let m := mload(0x40)

            // Copy G2 point (8 * 32 bytes = 256 bytes)
            mcopy(m, g2Point, 0x100)

            // Add scalar (32 bytes)
            mstore(add(m, 0x100), scalar)

            // Call precompile (input: 288 bytes, output: 256 bytes)
            if iszero(and(eq(returndatasize(), 0x100), staticcall(gas(), BLS12_G2MSM, m, 0x120, result, 0x100))) {
                mstore(0x00, 0x8c1e8178) // `G2MSMFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
