// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { convert, convert } from "prb-math/sd59x18/Conversions.sol";
import { exp, div, mul, inv, pow, wrap, sqrt, abs, ln } from "prb-math/sd59x18/Math.sol";
import { SD59x18 } from "prb-math/sd59x18/ValueType.sol";

import { console2 } from "forge-std/console2.sol";

/**
 * @title PdfLib
 *
 * @notice A library of functions related to the Probability Density Function of a normal distribution.
 *
 * @author jamco.eth (www.github.com/jamesmccomish)
 *
 * @dev
 * - TODO isTurning point should have better check for the first derivative being zero
 */
library PdfLib {
    using { wrap } for int256;
    using { exp, div, mul, inv, pow, ln } for SD59x18;

    enum TurningPoint {
        MINIMUM,
        MAXIMUM
    }

    // TODO
    SD59x18 internal constant FIRST_DERIVATIVE_TOLERANCE = SD59x18.wrap(1e12);

    SD59x18 internal constant TWO = SD59x18.wrap(2e18);
    SD59x18 internal constant PI = SD59x18.wrap(3_141_592_653_589_793_238);
    SD59x18 internal constant SQRT_2PI = SD59x18.wrap(2_506_628_274_631_000_502);

    /**
     * @notice Probability Density Function
     *
     * @param x The value at which to evaluate the pdf.
     * @param mean The mean of the distribution.
     * @param sigma The Standard Deviation of the distribution.
     * @return p The value of the pdf at x.
     *
     * @dev Equal to `p(x) = (1 / σ√2π)e^((-(x - µ)^2) / 2σ^2)`.
     */
    function pdf(int256 x, int256 mean, int256 sigma) internal pure returns (int256) {
        return pdf(convert(x), convert(mean), convert(sigma)).unwrap();
    }

    function isMinimumPoint(
        int256 x0,
        int256 mean1,
        int256 sigma1,
        int256 mean2,
        int256 sigma2
    )
        internal
        pure
        returns (bool)
    {
        return isTurningPoint(
            convert(x0), convert(mean1), convert(sigma1), convert(mean2), convert(sigma2), TurningPoint.MINIMUM
        );
    }

    function isMaximumPoint(
        int256 x0,
        int256 mean1,
        int256 sigma1,
        int256 mean2,
        int256 sigma2
    )
        internal
        pure
        returns (bool)
    {
        return isTurningPoint(
            convert(x0), convert(mean1), convert(sigma1), convert(mean2), convert(sigma2), TurningPoint.MAXIMUM
        );
    }

    /**
     * @notice Calculate the difference between two pdfs
     *
     * @param scale The scale of the pdf
     * @param x The value at which to evaluate the pdf
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2 The sigma of the second distribution
     * @return The difference between the two pdfs
     *
     * @dev Note:
     * - The curve pdf2 - pdf1 is not a valid pdf
     * - This function is useful only to get the difference between two pdfs at a given x
     */
    function pdfDifference(
        int256 scale,
        int256 x,
        int256 mean1,
        int256 sigma1,
        int256 mean2,
        int256 sigma2
    )
        internal
        pure
        returns (int256)
    {
        return pdfDifference(wrap(x), wrap(mean1), wrap(sigma1), wrap(mean2), wrap(sigma2)).unwrap();
    }

    function pdf(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18 p) {
        console2.log("x", x.unwrap());
        console2.log("mean", mean.unwrap());
        console2.log("sigma", sigma.unwrap());

        // -(x - µ)^2
        SD59x18 xMinusMean = x - mean;
        // console2.log("xMinusMean", xMinusMean.unwrap());
        SD59x18 xMinusMeanSquared = xMinusMean.mul(xMinusMean);
        // console2.log("xMinusMeanSquared", xMinusMeanSquared.unwrap());
        SD59x18 exponentNumerator = -xMinusMeanSquared;
        // console2.log("exponentNumerator", exponentNumerator.unwrap());
        // 2σ^2
        SD59x18 exponentDenominator = TWO.mul(sigma.mul(sigma));
        // console2.log("exponentDenominator", exponentDenominator.unwrap());
        SD59x18 exponentFull = exponentNumerator.div(exponentDenominator);
        // console2.log("exponentFull", exponentFull.unwrap());
        // e^((-(x - µ)^2) / 2σ^2)
        SD59x18 exponentResult = exp(exponentFull);
        // console2.log("exponentResult", exponentResult.unwrap());
        // (1 / σ√2π)
        SD59x18 coDenominator = sigma.mul(SQRT_2PI);
        // console2.log("coDenominator", coDenominator.unwrap());
        SD59x18 coefficient = inv(coDenominator);
        // console2.log("coefficient", coefficient.unwrap());

        // p = (1 / σ√2π)e^((-(x - µ)^2) / 2σ^2)
        p = mul(coefficient, exponentResult);
    }

    /**
     *
     * @notice Calculate the first derivative of the normal pdf
     *
     * @dev Equal to `-(x-μ)/σ² * pdf(x)`
     *
     * @param x The value at which to evaluate the pdf
     * @param mean The mean of the distribution
     * @param sigma The Standard Deviation of the distribution
     */
    function pdfDerivativeAtX(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {
        SD59x18 pdfVal = pdf(x, mean, sigma);
        console2.log("=== pdfVal", pdfVal.unwrap());

        SD59x18 xMinusMean = x - mean;
        console2.log("xMinusMean", xMinusMean.unwrap());

        SD59x18 variance = sigma.mul(sigma);
        console2.log("variance", variance.unwrap());

        SD59x18 divideByVariance = -xMinusMean.div(variance);
        console2.log("divideByVariance", divideByVariance.unwrap());

        SD59x18 result = (divideByVariance.mul(pdfVal));
        console2.log("pdfDerivativeAtX", result.unwrap());

        return result;
    }

    /**
     *
     * @notice Calculate the second derivative of the normal pdf
     *
     * @dev Equal to `[(x-μ)²/σ⁴ - 1/σ²] * pdf(x)`
     *
     * @param x The value at which to evaluate the pdf
     * @param mean  The mean of the distribution
     * @param sigma The Standard Deviation of the distribution
     */
    function pdfSecondDerivativeAtX(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {
        // (x-μ)²
        SD59x18 xMinusMean = x - mean;
        SD59x18 xMinusMeanSquared = xMinusMean.mul(xMinusMean);
        // (x-μ)²/σ²
        SD59x18 divideByVariance = xMinusMeanSquared.div(sigma.mul(sigma));
        // (x-μ)²/σ⁴ scaled
        SD59x18 term1 = divideByVariance.div(sigma.mul(sigma));
        // 1/σ²
        SD59x18 term2 = inv(sigma.mul(sigma));

        // full second derivative: [(x-μ)²/σ⁴ - 1/σ²] * pdf(x)
        SD59x18 result = (term1.sub(term2)).mul(pdf(x, mean, sigma));
        //console2.log("pdfSecondDerivativeAtX", result.unwrap());

        return result;
    }

    /**
     *
     * @notice Check if x0 is a turning point of g(x) - f(x)
     * @param x0 The point to check
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2  The sigma of the second distribution
     * @param turningPoint Whether to check if x0 is a minimum or maximum point
     *
     * @dev There is no closed form of the solution for the minimum point of g(x) - f(x)
     *      We can use the first and second derivative tests to check if x0 is a minimum point
     */
    function isTurningPoint(
        SD59x18 x0,
        SD59x18 mean1,
        SD59x18 sigma1,
        SD59x18 mean2,
        SD59x18 sigma2,
        TurningPoint turningPoint
    )
        public
        pure
        returns (bool)
    {
        console2.log("=== x0", x0.unwrap());
        console2.log("=== mean1", mean1.unwrap());
        console2.log("=== sigma1", sigma1.unwrap());
        console2.log("=== mean2", mean2.unwrap());
        console2.log("=== sigma2", sigma2.unwrap());

        // Calculate first derivative of g(x) - f(x) at x0
        SD59x18 firstDerivative = pdfDerivativeAtX(x0, mean2, sigma2).sub(pdfDerivativeAtX(x0, mean1, sigma1));
        console2.log("difference firstDerivative", (firstDerivative.unwrap()));

        // Calculate second derivative of g(x) - f(x) at x0
        SD59x18 secondDerivative =
            pdfSecondDerivativeAtX(x0, mean2, sigma2).sub(pdfSecondDerivativeAtX(x0, mean1, sigma1));
        console2.log("difference secondDerivative", (secondDerivative.unwrap()));

        // For x0 to be a turning point the first derivative should be zero (or very close to zero)
        bool isFirstDerivativeZero = abs(firstDerivative) < FIRST_DERIVATIVE_TOLERANCE;
        // TODO confirm reasonable error

        // TODO equal was added below in case the final mean and var are completely correct, but this needs checked
        bool secondDerivativeCondition = turningPoint == TurningPoint.MINIMUM
            // For a minimum point the second derivative should be positive
            ? secondDerivative.gte(SD59x18.wrap(0))
            // For a maximum point the second derivative should be negative
            : secondDerivative.lte(SD59x18.wrap(0));

        console2.log("=== isFirstDerivativeZero", isFirstDerivativeZero);
        console2.log("=== secondDerivativeCondition", secondDerivativeCondition);

        return isFirstDerivativeZero && secondDerivativeCondition;
    }

    /**
     *
     * @notice Check if x0 is a minimum point of g(x) - f(x)
     * @param x0 The point to check
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2  The sigma of the second distribution
     *
     * @dev There is no closed form of the solution for the minimum point of g(x) - f(x)
     *      We can use the first and second derivative tests to check if x0 is a minimum point
     */
    function isMinimumPoint(
        SD59x18 x0,
        SD59x18 mean1,
        SD59x18 sigma1,
        SD59x18 mean2,
        SD59x18 sigma2
    )
        public
        pure
        returns (bool)
    {
        return isTurningPoint(x0, mean1, sigma1, mean2, sigma2, TurningPoint.MINIMUM);
    }

    function isMaximumPoint(
        SD59x18 x0,
        SD59x18 mean1,
        SD59x18 sigma1,
        SD59x18 mean2,
        SD59x18 sigma2
    )
        public
        pure
        returns (bool)
    {
        return isTurningPoint(x0, mean1, sigma1, mean2, sigma2, TurningPoint.MAXIMUM);
    }

    function pdfDifference(
        SD59x18 x,
        SD59x18 mean1,
        SD59x18 sigma1,
        SD59x18 mean2,
        SD59x18 sigma2
    )
        internal
        pure
        returns (SD59x18)
    {
        return pdf(x, mean1, sigma1).sub(pdf(x, mean2, sigma2));
    }

    // TODO
    // function erf(SD59x18 x) internal pure returns (SD59x18) {}

    // TODO
    // function cdf(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {}
}
