// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { convert, convert } from "prb-math/sd59x18/Conversions.sol";
import { exp, div, mul, inv, pow, wrap, sqrt, abs, ln } from "prb-math/sd59x18/Math.sol";
import { SD59x18 } from "prb-math/sd59x18/ValueType.sol";

/**
 * @title PdfLib
 *
 * @notice A library of functions related to the Probability Density Function of a normal distribution.
 *
 * @author jamco.eth (www.github.com/jamesmccomish)
 */
library PdfLib {
    using { wrap } for int256;
    using { exp, div, mul, inv, pow, ln } for SD59x18;

    /**
     * @dev The type of turning point to check for
     * Used when confirming a point is the min/max difference between 2 pdfs
     */
    enum TurningPoint {
        MINIMUM,
        MAXIMUM
    }

    /// TODO Improve this with a lower tolerance
    /// @notice The tolerance for the first derivative to be considered zero
    SD59x18 internal constant FIRST_DERIVATIVE_TOLERANCE = SD59x18.wrap(1e12);

    /// @notice Some useful values converted to SD59x18
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

    /**
     * @notice Calculate the difference between two pdfs
     *
     * @param x The value at which to evaluate the pdf
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2 The sigma of the second distribution
     *
     * @return The difference between the two pdfs
     *
     * @dev Note:
     * - The curve pdf2 - pdf1 is not a valid pdf
     * - This function is useful only to get the difference between two pdfs at a given x
     */
    function pdfDifference(
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

    /**
     * @notice Check if x0 is a minimum point of g(x) - f(x)
     *
     * @param x0 The point to check
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2  The sigma of the second distribution
     *
     * @return True if x0 is a minimum point of g(x) - f(x)
     *
     * @dev There is no closed form of the solution for the minimum point of g(x) - f(x)
     *      We can use the first and second derivative tests to check if x0 is a minimum point
     */
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

    /**
     * @notice Check if x0 is a maximum point of g(x) - f(x)
     *
     * @param x0 The point to check
     * @param mean1 The mean of the first distribution
     * @param sigma1 The sigma of the first distribution
     * @param mean2 The mean of the second distribution
     * @param sigma2  The sigma of the second distribution
     *
     * @return isMaximum True if x0 is a maximum point of g(x) - f(x)
     */
    function isMaximumPoint(
        int256 x0,
        int256 mean1,
        int256 sigma1,
        int256 mean2,
        int256 sigma2
    )
        internal
        pure
        returns (bool isMaximum)
    {
        isMaximum = isTurningPoint(
            convert(x0), convert(mean1), convert(sigma1), convert(mean2), convert(sigma2), TurningPoint.MAXIMUM
        );
    }

    function pdf(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18 p) {
        // -(x - µ)^2
        SD59x18 xMinusMean = x - mean;
        SD59x18 xMinusMeanSquared = xMinusMean.mul(xMinusMean);
        SD59x18 exponentNumerator = -xMinusMeanSquared;
        // 2σ^2
        SD59x18 exponentDenominator = TWO.mul(sigma.mul(sigma));
        SD59x18 exponentFull = exponentNumerator.div(exponentDenominator);
        SD59x18 exponentResult = exp(exponentFull);
        // (1 / σ√2π)
        SD59x18 coDenominator = sigma.mul(SQRT_2PI);
        SD59x18 coefficient = inv(coDenominator);

        // p = (1 / σ√2π)e^((-(x - µ)^2) / 2σ^2)
        p = mul(coefficient, exponentResult);
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
    function pdfDerivativeAtX(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18 result) {
        // (x-µ)
        SD59x18 xMinusMean = x - mean;
        // σ²
        SD59x18 variance = sigma.mul(sigma);
        // -(x-µ)/σ²
        SD59x18 divideByVariance = -xMinusMean.div(variance);
        // -(x-µ)/σ² * pdf(x)
        result = (divideByVariance.mul(pdf(x, mean, sigma)));
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
    function pdfSecondDerivativeAtX(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18 result) {
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
        result = (term1.sub(term2)).mul(pdf(x, mean, sigma));
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
        // Calculate first derivative of g(x) - f(x) at x0
        SD59x18 firstDerivative = pdfDerivativeAtX(x0, mean2, sigma2).sub(pdfDerivativeAtX(x0, mean1, sigma1));

        // Calculate second derivative of g(x) - f(x) at x0
        SD59x18 secondDerivative =
            pdfSecondDerivativeAtX(x0, mean2, sigma2).sub(pdfSecondDerivativeAtX(x0, mean1, sigma1));

        // For x0 to be a turning point the first derivative should be zero (or very close to zero)
        bool isFirstDerivativeZero = abs(firstDerivative) < FIRST_DERIVATIVE_TOLERANCE;
        // TODO confirm reasonable error

        bool secondDerivativeCondition = turningPoint == TurningPoint.MINIMUM
            // For a minimum point the second derivative should be positive
            ? secondDerivative.gte(SD59x18.wrap(0))
            // For a maximum point the second derivative should be negative
            : secondDerivative.lte(SD59x18.wrap(0));

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

    // TODO
    // function erf(SD59x18 x) internal pure returns (SD59x18) {}

    // TODO
    // function cdf(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {}
}
