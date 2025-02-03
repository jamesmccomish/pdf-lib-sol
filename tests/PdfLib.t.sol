// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Misc test utils
import { console2 } from "forge-std/console2.sol";
import { stdMath } from "forge-std/StdMath.sol";

// Config
import { PdfLibTestConfig } from "@test/config/PdfLibTestConfig.t.sol";

// Math utils from prb-math
import { convert, convert } from "prb-math/sd59x18/Conversions.sol";
import { sqrt, wrap, log10, abs } from "prb-math/sd59x18/Math.sol";
import { SD59x18 } from "prb-math/sd59x18/ValueType.sol";
import { uMIN_SD59x18, uMAX_SD59x18 } from "prb-math/sd59x18/Constants.sol";

// Data
import { GeneratePdfTestData, PdfTestData, Curve, DifferenceExtrema } from "@test/scripts/GeneratePdfTestData.s.sol";

// Lib to test
import { PdfLib } from "@src/PdfLib.sol";

contract PdfLibTest is PdfLibTestConfig, GeneratePdfTestData {
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant ONE_ETHER = 1 ether;
    uint256 internal constant HALF_ETHER = 0.5 ether;

    PdfTestData internal testData;

    function test_pdf_int256Wrapper(int256 seed) public {
        //seed = 9_671_416_071_630_577_420_746_185_271_013;
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);
        // int256 x = 3;
        // int256 stdDev = 1;

        console2.log("x", x);
        console2.log("mean", mean);
        console2.log("stdDev", stdDev);

        int256 p = PdfLib.pdf(x, mean, stdDev);
        console2.log("--- p", p);
        int256 pCheck = calculatePdf(mean, stdDev, x);
        console2.log("pCheck", pCheck);

        mean = mean * 1e10;
        x = x * 1e10;
        stdDev = stdDev * 1e10;

        console2.log("x", x);
        console2.log("mean", mean);
        console2.log("stdDev", stdDev);

        int256 p2 = PdfLib.pdf(x, mean, stdDev);
        console2.log("--- p2", p2);
        int256 p2Check = calculatePdf(mean, stdDev, x);
        console2.log("p2Check", p2Check);

        // assertApproxEqRel(p, pCheck, TOLERANCE);
    }

    function test_pdfScaledInputs() public { }

    // function test_pdf_SD59x18(int256 seed) public {
    //     (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);

    //     int256 p1 = PdfLib.pdf(convert(x), convert(mean), convert(stdDev)).unwrap();
    //     int256 p1Check = calculatePdf(mean, stdDev, x);
    //     assertApproxEqRel(p1, p1Check, TOLERANCE);

    //     x = x * 10;
    //     mean = mean * 10;
    //     stdDev = stdDev * 10;

    //     int256 p2 = PdfLib.pdf(convert(x), convert(mean), convert(stdDev)).unwrap();
    //     int256 p2Check = calculatePdf(mean, stdDev, x);
    //     assertApproxEqRel(p2, p2Check, TOLERANCE);
    //     assertApproxEqRel(p1, p2 * 10, TOLERANCE);
    //     assertApproxEqRel(p1Check, p2Check * 10, TOLERANCE);
    // }

    function test_pdfDerivitiveAtX(int256 seed) public {
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);

        // Calculate the derivative and check against typescript pdf functions
        int256 p1 = PdfLib.pdfDerivativeAtX(convert(x), convert(mean), convert(stdDev)).unwrap();
        console2.log("p1", p1);
        int256 p1Check = calculateDerivative(mean, stdDev, x);
        console2.log("p1Check", p1Check);

        // x on the other side of the mean
        int256 x2 = mean + mean - x;
        int256 p2 = PdfLib.pdfDerivativeAtX(convert(x2), convert(mean), convert(stdDev)).unwrap();
        console2.log("p2", p2);
        int256 p2Check = calculateDerivative(mean, stdDev, x2);
        console2.log("p2Check", p2Check);

        assertEq(p1, -p2);
        assertEq(p1Check, -p2Check);
        assertApproxEqRel(p1, p1Check, TOLERANCE);
        assertApproxEqRel(p2, p2Check, TOLERANCE);
    }

    // TODO fix tolerance check
    function test_pdfSecondDerivitiveAtX(int256 seed) public {
        // Run with narrow range as second derivitive drops to 0 outside this
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed, NARROW_RANGE_CONFIG);
        // x = 1.05e5;
        //  mean = 1.1e5;
        //  stdDev = 1e4;

        console2.log("x", x);
        console2.log("stdDev", stdDev);
        console2.log("mean", mean);
        int256 p1 = PdfLib.pdfSecondDerivativeAtX(convert(x), convert(mean), convert(stdDev)).unwrap();
        console2.log("p1 deriv", p1);
        int256 p1Check = calculateSecondDerivative(mean, stdDev, x);
        console2.log("p1Check", p1Check);

        int256 x2 = mean + mean - x;
        int256 p2 = PdfLib.pdfSecondDerivativeAtX(convert(x2), convert(mean), convert(stdDev)).unwrap();
        console2.log("p2", p2);
        int256 p2Check = calculateSecondDerivative(mean, stdDev, x2);
        console2.log("p2Check", p2Check);

        assertEq(p1, p2);
        assertEq(p1Check, p2Check);
        assertApproxEqRel(p1, p1Check, TOLERANCE);
        assertApproxEqRel(p2, p2Check, TOLERANCE);
    }

    function test_isMinimumPoint_in256Wrapper(int256 seed1, int256 seed2) public {
        // We just use this to generate the stdDevs, x is unused
        (, int256 mean1, int256 stdDev1) = generatePdfTestValues(seed1, NARROW_RANGE_CONFIG);
        (, int256 mean2, int256 stdDev2) = generatePdfTestValues(seed2, NARROW_RANGE_CONFIG);

        // Use ts to calculate the minimum point, and take x from that
        PdfTestData memory pdfData = calculateCurvePoints(mean1, stdDev1, mean2, stdDev2, 0);

        bool isMinimum =
            PdfLib.isMinimumPoint(pdfData.differenceExtrema.min.x / 1e18, (mean1), (stdDev1), (mean2), (stdDev2));

        assertEq(isMinimum, true);
    }

    // function test_isMinimumPoint_SD59x18(int256 mean1, int256 mean2, int256 seed) public {
    //     // Means should be within 50% of each other
    //     vm.assume(mean1 >= 0 && mean2 >= 0 && mean1 <= type(int256).max / 2 && mean2 <= type(int256).max / 2);
    //     vm.assume(mean1 > mean2 - mean1 / 2 && mean1 < mean2 + mean1 / 2);

    //     // We just use this to generate the stdDevs, x is unused
    //     (, int256 stdDev1) = generatePdfTestValues(mean1, seed);
    //     (, int256 stdDev2) = generatePdfTestValues(mean2, seed);

    //     // Use ts to calculate the minimum point, and take x from that
    //     MarketData memory testMarketData = calculateCurvePoints(mean1, stdDev1, mean2, stdDev2, 0, scale);

    //     bool isMinimum = PdfLib.isMinimumPoint(
    //         scale_SD59x18,
    //         wrap(testMarketData.differenceExtrema.min.x),
    //         convert(mean1),
    //         convert(stdDev1),
    //         convert(mean2),
    //         convert(stdDev2)
    //     );
    //     assertEq(isMinimum, true);
    // }
}
