// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

import { convert, convert } from "prb-math/sd59x18/Conversions.sol";
import { sqrt, wrap, log10, abs } from "prb-math/sd59x18/Math.sol";
import { SD59x18 } from "prb-math/sd59x18/ValueType.sol";
import { uMIN_SD59x18, uMAX_SD59x18 } from "prb-math/sd59x18/Constants.sol";

contract PdfLibTestConfig is Test {
    // 0.00000001%
    uint256 internal constant TOLERANCE = 1e10;

    int256 MIN_MEAN = -1e18;
    int256 MAX_MEAN = 1e18;
    uint256 STD_DEV_PERCENT_OF_MEAN = 30;
    uint256 X_STD_DEV_RANGE = 3;

    struct PdfTestConfig {
        int256 minMean;
        int256 maxMean;
        // stdDev will be within this % of mean (e.g. 30 = 30%)
        uint256 stdDevPercentOfMean;
        // x will be within this many stdDevs of mean
        uint256 xStdDevRange;
    }

    PdfTestConfig internal DEFAULT_CONFIG = PdfTestConfig({
        minMean: MIN_MEAN / 1e9,
        maxMean: MAX_MEAN / 1e9,
        stdDevPercentOfMean: STD_DEV_PERCENT_OF_MEAN,
        xStdDevRange: X_STD_DEV_RANGE
    });

    PdfTestConfig internal FULL_RANGE_CONFIG = PdfTestConfig({
        minMean: MIN_MEAN,
        maxMean: MAX_MEAN,
        stdDevPercentOfMean: STD_DEV_PERCENT_OF_MEAN,
        xStdDevRange: X_STD_DEV_RANGE
    });

    PdfTestConfig internal NARROW_RANGE_CONFIG =
        PdfTestConfig({ minMean: MIN_MEAN / 1e9, maxMean: MAX_MEAN / 1e9, stdDevPercentOfMean: 10, xStdDevRange: 1 });

    /**
     * @notice generate test values for pdf using default config
     */
    function generatePdfTestValues(int256 seed) public returns (int256 x, int256 stdDev, int256 mean) {
        return generatePdfTestValues(seed, DEFAULT_CONFIG);
    }

    /**
     * @notice generate test values for pdf with custom config
     * @param seed Random seed to generate values
     * @param config Configuration for bounds of generated values
     * @return x the x value to evaluate at
     * @return mean the mean of the distribution
     * @return stdDev the stdDev of the distribution
     */
    function generatePdfTestValues(
        int256 seed,
        PdfTestConfig memory config
    )
        public
        pure
        returns (int256 x, int256 mean, int256 stdDev)
    {
        int256 meanRange = config.maxMean - config.minMean;
        int256 meanMidpoint = config.minMean + (meanRange / 2);

        // If seed is out of range to find abs, modulo by 1e18 for random enough value
        bool seedOutOfRange = seed <= uMIN_SD59x18;
        if (seedOutOfRange) {
            seed = seed % meanRange;
        }
        int256 absSeed = int256(abs(wrap(seed)).unwrap());

        // Generate mean as midpoint ± random offset
        int256 maxOffset = meanRange / 2; // Maximum distance from midpoint
        int256 offset = absSeed % maxOffset;
        int256 side = seed % 2 == 0 ? int256(1) : int256(-1);
        mean = meanMidpoint + (side * offset);

        // Calculate stdDev as percentage of absolute mean value to ensure positive
        int256 absMean = mean < 0 ? -mean : mean;
        int256 stdDevRange = (absMean * int256(config.stdDevPercentOfMean)) / 100;

        // Ensure stdDev is always positive and at least 1
        stdDevRange = stdDevRange < 1 ? int256(1) : stdDevRange;
        stdDev = 1 + (absSeed % stdDevRange);

        // Generate x within configured number of stdDevs from mean
        side = seed % 2 == 0 ? int256(1) : int256(-1);
        x = mean + side * (absSeed % (stdDev * int256(config.xStdDevRange)));

        return (x, mean, stdDev);
    }
}
