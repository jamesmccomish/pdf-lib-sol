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

    function test_pdf(int256 seed) public {
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);

        int256 p1 = PdfLib.pdf(x, mean, stdDev);
        int256 p1Check = calculatePdf(mean, stdDev, x);
        assertApproxEqRel(p1, p1Check, TOLERANCE, "p1 check");

        int256 scale = 1e2;
        mean = mean * scale;
        x = x * scale;
        stdDev = stdDev * scale;

        int256 p2 = PdfLib.pdf(x, mean, stdDev);
        int256 p2Check = calculatePdf(mean, stdDev, x);
        assertApproxEqRel(p2, p2Check, TOLERANCE, "p2 check");

        assertApproxEqRel(p1, p2 * scale, TOLERANCE, "p1 p2 scaled");
        assertApproxEqRel(p1Check, p2Check * scale, TOLERANCE, "p1Check p2Check scaled");
    }

    function test_pdfDifference(int256 seed) public {
        (int256 x, int256 mean1, int256 stdDev1) = generatePdfTestValues(seed);

        int256 mean2 = mean1 + (mean1 * (seed % 20)) / 100;
        int256 stdDev2 = stdDev1 + (stdDev1 * (seed % 20)) / 100;

        int256 diff = PdfLib.pdfDifference(
            convert(x), convert(mean1), convert(stdDev1), convert(mean2), convert(stdDev2)
        ).unwrap();
        int256 diffCheck = calculatePdfDifference(mean1, stdDev1, mean2, stdDev2, x);

        assertApproxEqRel(diff, diffCheck, TOLERANCE);
    }

    function test_isMinimumPoint(int256 seed) public {
        // We just use this to generate the stdDevs, x is unused
        (, int256 mean1, int256 stdDev1) = generatePdfTestValues(seed, NARROW_RANGE_CONFIG);

        int256 mean2 = mean1 + (mean1 * (seed % 20)) / 100;
        int256 stdDev2 = stdDev1 + (stdDev1 * (seed % 20)) / 100;

        // Use ts to calculate the minimum point, and take x from that
        PdfTestData memory pdfData = calculateCurvePoints(mean1, stdDev1, mean2, stdDev2, 0);

        bool isMinimum =
            PdfLib.isMinimumPoint(pdfData.differenceExtrema.min.x / 1e18, (mean1), (stdDev1), (mean2), (stdDev2));

        assertEq(isMinimum, true);
    }

    function test_pdfDerivitiveAtX(int256 seed) public {
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);

        // Calculate the derivative and check against typescript pdf functions
        int256 p1 = PdfLib.pdfDerivativeAtX(convert(x), convert(mean), convert(stdDev)).unwrap();
        int256 p1Check = calculateDerivative(mean, stdDev, x);

        // x on the other side of the mean
        int256 x2 = mean + mean - x;
        int256 p2 = PdfLib.pdfDerivativeAtX(convert(x2), convert(mean), convert(stdDev)).unwrap();
        int256 p2Check = calculateDerivative(mean, stdDev, x2);

        assertEq(p1, -p2);
        assertEq(p1Check, -p2Check);
        assertApproxEqRel(p1, p1Check, TOLERANCE);
        assertApproxEqRel(p2, p2Check, TOLERANCE);
    }

    function test_pdfSecondDerivitiveAtX(int256 seed) public {
        // Run with narrow range as second derivitive drops to 0 outside this
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed, NARROW_RANGE_CONFIG);

        int256 p1 = PdfLib.pdfSecondDerivativeAtX(convert(x), convert(mean), convert(stdDev)).unwrap();
        int256 p1Check = calculateSecondDerivative(mean, stdDev, x);

        int256 x2 = mean + mean - x;
        int256 p2 = PdfLib.pdfSecondDerivativeAtX(convert(x2), convert(mean), convert(stdDev)).unwrap();
        int256 p2Check = calculateSecondDerivative(mean, stdDev, x2);

        assertEq(p1, p2);
        assertEq(p1Check, p2Check);
        assertApproxEqRel(p1, p1Check, TOLERANCE);
        assertApproxEqRel(p2, p2Check, TOLERANCE);
    }

    function test_pdf_SD59x18(int256 seed) public {
        (int256 x, int256 mean, int256 stdDev) = generatePdfTestValues(seed);

        int256 p1 = PdfLib.pdf(convert(x), convert(mean), convert(stdDev)).unwrap();
        int256 p1Check = calculatePdf(mean, stdDev, x);
        assertApproxEqRel(p1, p1Check, TOLERANCE, "p1 check");

        x = x * 10;
        mean = mean * 10;
        stdDev = stdDev * 10;

        int256 p2 = PdfLib.pdf(convert(x), convert(mean), convert(stdDev)).unwrap();
        int256 p2Check = calculatePdf(mean, stdDev, x);
        assertApproxEqRel(p2, p2Check, TOLERANCE, "p2 check");

        assertApproxEqRel(p1, p2 * 10, TOLERANCE, "p1 p2 scaled ");
        assertApproxEqRel(p1Check, p2Check * 10, TOLERANCE, "p1Check p2Check scaled");
    }
}
