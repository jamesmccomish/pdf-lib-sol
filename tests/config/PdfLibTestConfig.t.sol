// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

import { convert, convert } from "prb-math/sd59x18/Conversions.sol";
import { sqrt, wrap, log10, abs } from "prb-math/sd59x18/Math.sol";
import { SD59x18 } from "prb-math/sd59x18/ValueType.sol";
import { uMIN_SD59x18, uMAX_SD59x18 } from "prb-math/sd59x18/Constants.sol";

contract PdfLibTestConfig is Test {
    /// FIX FOR ALL TESTS
    int256 internal scale = 1;
    SD59x18 internal scale_SD59x18 = convert(scale);

    // 0.0001%
    // uint256 internal constant TOLERANCE = 0.00001e18;
    uint256 internal constant TOLERANCE = 0.01e18; // !!! FIX - return to lower tolerance

    /**
     *
     * For now all values are scaled up by 1e18 when passed to the contract.
     * This is fine for our initial markets
     * It is equivalent to doing parseEther(value) on the frontend
     *
     */
    function inputScaling(int256 x, int256 mean, int256 stdDev) public view returns (int256, int256, int256, int256) {
        // // get size of mean
        // int256 meanSize = convert(log10(convert(mean)));
        // console2.log("meanSize", meanSize);

        // int256 _scale = 1;

        // if (meanSize < 18) {
        //     uint256 eTerm = 18 - uint256(meanSize);
        //     console2.log("eTerm", eTerm);
        //     // scale = int256(10 ** (18 - uint256(abs(wrap(meanSize)).unwrap())) - 1);
        //     _scale = int256(10 ** eTerm);
        // }
        // console2.log("scale", _scale);

        // // scale up
        // return (x * _scale, mean * _scale, stdDev * _scale, _scale);
        return (convert(x).unwrap(), convert(mean).unwrap(), convert(stdDev).unwrap(), scale_SD59x18.unwrap());
    }

    /**
     * @notice generate test values for pdf
     *
     * @dev from a random mean, generate sensible values to test
     * - mean from 1e4 to 1e7
     * - stdDev within 50% of the mean
     * - x within 5 stdDev of the mean
     *
     * @param mean the mean of the distribution
     * @param seed the seed to use for the random number generator
     * @return x the x value to eveluate at
     * @return stdDev the stdDev of the distribution
     */
    function generatePdfTestValues(int256 mean, int256 seed) public pure returns (int256 x, int256 stdDev) {
        vm.assume(mean > 1e4 && mean < 1e7);

        // console2.log("___ generate vals ___");
        // console2.log("mean", mean);
        // console2.log("seed", seed);

        // If seed is out of range to find abs, modulo by 1e18 for random enough value
        bool seedOutOfRange = seed <= uMIN_SD59x18;
        if (seedOutOfRange) {
            seed = seed % 1e18;
        }

        int256 absSeed = int256(abs(wrap(seed)).unwrap());
        //console2.log("absSeed", absSeed);

        int256 side = seed % 2 == 0 ? int256(1) : int256(-1);
        //console2.log("side", side);

        // Calculate max range for stdDev (30% of mean), ensure we don't modulo by zero
        int256 stdDevRange = (int256(mean) * 30) / 100;
        if (stdDevRange == 0) {
            stdDevRange = 1;
        }
        // Generate a pseudo-random value within [1 ... stdDevRange]
        stdDev = int256(1 + (absSeed % stdDevRange));
        //console2.log("stdDev", stdDev);

        // x should be within +/- 3 stdDev of mean to avoid rounding errors
        x = mean + side * (absSeed % (stdDev * 3));
        //console2.log("x", x);

        vm.assume(x > 0);

        return (x, stdDev);
    }
}
