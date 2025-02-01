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

    SD59x18 internal constant SCALAR = SD59x18.wrap(1e18);
    SD59x18 internal constant SCALAR_SQUARED = SD59x18.wrap(1e36);
    SD59x18 internal constant TWO = SD59x18.wrap(2e18);
    SD59x18 internal constant PI = SD59x18.wrap(3_141_592_653_589_793_238);
    SD59x18 public constant SQRT_PI = SD59x18.wrap(1_772_453_850_905_516_027);
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
    function pdf(int256 scale, int256 x, int256 mean, int256 sigma) internal pure returns (int256) {
        return pdf(wrap(scale), wrap(x), wrap(mean), wrap(sigma)).unwrap();
    }

    // function isMinimumPoint(
    //     int256 scale,
    //     int256 x0,
    //     int256 mean1,
    //     int256 sigma1,
    //     int256 mean2,
    //     int256 sigma2
    // )
    //     internal
    //     pure
    //     returns (bool)
    // {
    //     return isTurningPoint(
    //         wrap(scale), wrap(x0), wrap(mean1), wrap(sigma1), wrap(mean2), wrap(sigma2), TurningPoint.MINIMUM
    //     );
    // }

    // function isMaximumPoint(
    //     int256 scale,
    //     int256 x0,
    //     int256 mean1,
    //     int256 sigma1,
    //     int256 mean2,
    //     int256 sigma2
    // )
    //     internal
    //     pure
    //     returns (bool)
    // {
    //     return isTurningPoint(
    //         wrap(scale), wrap(x0), wrap(mean1), wrap(sigma1), wrap(mean2), wrap(sigma2), TurningPoint.MAXIMUM
    //     );
    // }

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
        return pdfDifference(wrap(scale), wrap(x), wrap(mean1), wrap(sigma1), wrap(mean2), wrap(sigma2)).unwrap();
    }

    function pdf(SD59x18 scale, SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18 p) {
        console2.log("--- pdf");
        console2.log("scale", scale.unwrap());
        console2.log("x", x.unwrap());
        console2.log("mean", mean.unwrap());
        console2.log("sigma", sigma.unwrap());

        // x - µ
        SD59x18 xMinusMean = x - mean;
        console2.log("xMinusMean", xMinusMean.unwrap());
        // -(x - µ)^2
        SD59x18 exponentNumerator = -xMinusMean.mul(xMinusMean);
        console2.log("exponentNumerator", exponentNumerator.unwrap());
        // 2σ^2
        SD59x18 exponentDenominator = TWO.mul(sigma.mul(sigma));
        console2.log("exponentDenominator", exponentDenominator.unwrap());
        SD59x18 exponentFull = exponentNumerator.div(exponentDenominator);
        console2.log("exponentFull", exponentFull.unwrap());
        // e^((-(x - µ)^2) / 2σ^2)
        SD59x18 exponentResult = exp(exponentFull);
        console2.log("exponentResult", exponentResult.unwrap());
        // (scale / σ√2π)
        SD59x18 denominator = sigma.mul(SQRT_2PI);
        console2.log("denominator", denominator.unwrap());
        SD59x18 coefficient = scale.div(denominator);
        console2.log("coefficient", coefficient.unwrap());

        // p = (1 / σ√2π)e^((-(x - µ)^2) / 2σ^2)
        p = mul(coefficient, exponentResult);
        // console2.log("pdf", p.unwrap());
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
    function pdfDerivativeAtX(SD59x18 scale, SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {
        SD59x18 pdfVal = pdf(scale, x, mean, sigma);
        //console2.log("=== pdfVal", pdfVal.unwrap());

        SD59x18 xMinusMean = x - mean;
        //console2.log("xMinusMean", xMinusMean.unwrap());

        SD59x18 variance = sigma.mul(sigma);
        //console2.log("variance", variance.unwrap());

        SD59x18 divideByVariance = -scale.mul(scale).mul((xMinusMean)).div(variance);
        //console2.log("divideByVariance", divideByVariance.unwrap());

        SD59x18 result = (divideByVariance.mul(pdfVal));
        //console2.log("pdfDerivativeAtX", result.unwrap());

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
    function pdfSecondDerivativeAtX(
        SD59x18 scale,
        SD59x18 x,
        SD59x18 mean,
        SD59x18 sigma
    )
        internal
        pure
        returns (SD59x18)
    {
        // (x-μ)²
        SD59x18 xMinusMean = x - mean;
        SD59x18 xMinusMeanSquared = xMinusMean.mul(xMinusMean);
        // (x-μ)²/σ²
        SD59x18 divideByVariance = xMinusMeanSquared.div(sigma.mul(sigma));
        // (x-μ)²/σ⁴ scaled
        SD59x18 term1 = scale.mul(scale).mul(divideByVariance).div(sigma.mul(sigma));
        // console2.log("term1", term1.unwrap());
        // 1/σ²
        SD59x18 term2 = scale.mul(scale).div(sigma.mul(sigma)); // mul SCALAR_SQUARED_SD59x18 ?
        //console2.log("term2", term2.unwrap());

        // full second derivative: [(x-μ)²/σ⁴ - 1/σ²] * pdf(x)
        SD59x18 result = (term1.sub(term2)).mul(pdf(scale, x, mean, sigma));
        //console2.log("pdfSecondDerivativeAtX", result.unwrap());

        return result;
    }

    // /**
    //  *
    //  * @notice Check if x0 is a turning point of g(x) - f(x)
    //  * @param x0 The point to check
    //  * @param mean1 The mean of the first distribution
    //  * @param sigma1 The sigma of the first distribution
    //  * @param mean2 The mean of the second distribution
    //  * @param sigma2  The sigma of the second distribution
    //  * @param turningPoint Whether to check if x0 is a minimum or maximum point
    //  *
    //  * @dev There is no closed form of the solution for the minimum point of g(x) - f(x)
    //  *      We can use the first and second derivative tests to check if x0 is a minimum point
    //  */
    // function isTurningPoint(
    //     SD59x18 scale,
    //     SD59x18 x0,
    //     SD59x18 mean1,
    //     SD59x18 sigma1,
    //     SD59x18 mean2,
    //     SD59x18 sigma2,
    //     TurningPoint turningPoint
    // )
    //     public
    //     pure
    //     returns (bool)
    // {
    //     // Calculate first derivative of g(x) - f(x) at x0
    //     SD59x18 firstDerivative =
    //         pdfDerivativeAtX(scale, x0, mean2, sigma2).sub(pdfDerivativeAtX(scale, x0, mean1, sigma1));
    //     // console2.log("difference firstDerivative", (firstDerivative.unwrap()));

    //     // Calculate second derivative of g(x) - f(x) at x0
    //     SD59x18 secondDerivative =
    //         pdfSecondDerivativeAtX(scale, x0, mean2, sigma2).sub(pdfSecondDerivativeAtX(scale, x0, mean1, sigma1));
    //     // console2.log("difference secondDerivative", (secondDerivative.unwrap()));

    //     // For x0 to be a turning point the first derivative should be zero (or very close to zero)
    //     bool isFirstDerivativeZero = abs(firstDerivative) < SD59x18.wrap(1e14);
    //     // TODO confirm reasonable error

    //     // TODO equal was added below in case the final mean and var are completely correct, but this needs checked
    //     bool secondDerivativeCondition = turningPoint == TurningPoint.MINIMUM
    //         // For a minimum point the second derivative should be positive
    //         ? secondDerivative.gte(SD59x18.wrap(0))
    //         // For a maximum point the second derivative should be negative
    //         : secondDerivative.lte(SD59x18.wrap(0));

    //     // console2.log("=== isFirstDerivativeZero", isFirstDerivativeZero);
    //     // console2.log("=== secondDerivativeCondition", secondDerivativeCondition);

    //     return isFirstDerivativeZero && secondDerivativeCondition;
    // }

    // /**
    //  *
    //  * @notice Check if x0 is a minimum point of g(x) - f(x)
    //  * @param x0 The point to check
    //  * @param mean1 The mean of the first distribution
    //  * @param sigma1 The sigma of the first distribution
    //  * @param mean2 The mean of the second distribution
    //  * @param sigma2  The sigma of the second distribution
    //  *
    //  * @dev There is no closed form of the solution for the minimum point of g(x) - f(x)
    //  *      We can use the first and second derivative tests to check if x0 is a minimum point
    //  */
    // function isMinimumPoint(
    //     SD59x18 scale,
    //     SD59x18 x0,
    //     SD59x18 mean1,
    //     SD59x18 sigma1,
    //     SD59x18 mean2,
    //     SD59x18 sigma2
    // )
    //     public
    //     pure
    //     returns (bool)
    // {
    //     return isTurningPoint(scale, x0, mean1, sigma1, mean2, sigma2, TurningPoint.MINIMUM);
    // }

    // function isMaximumPoint(
    //     SD59x18 scale,
    //     SD59x18 x0,
    //     SD59x18 mean1,
    //     SD59x18 sigma1,
    //     SD59x18 mean2,
    //     SD59x18 sigma2
    // )
    //     public
    //     pure
    //     returns (bool)
    // {
    //     return isTurningPoint(scale, x0, mean1, sigma1, mean2, sigma2, TurningPoint.MAXIMUM);
    // }

    function isAboveMinimumsigma(SD59x18 sigma, SD59x18 marketL2Norm, SD59x18 b) internal pure returns (bool) {
        SD59x18 norm2 = marketL2Norm.mul(marketL2Norm);
        //  console2.log("norm2", norm2.unwrap());

        SD59x18 b2 = b.mul(b);
        //console2.log("b2", b2.unwrap());

        SD59x18 minsigma = (norm2.div(SQRT_PI.mul(b2))); // TODO: check if this is correct
        //console2.log("minsigma", minsigma.unwrap());

        return sigma.gt(minsigma);
    }

    function pdfDifference(
        SD59x18 scale,
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
        SD59x18 pdf1 = pdf(scale, x, mean1, sigma1);
        //console2.log("pdf1", pdf1.unwrap());

        SD59x18 pdf2 = pdf(scale, x, mean2, sigma2);
        // console2.log("pdf2", pdf2.unwrap());

        return pdf1.sub(pdf2);
    }

    function erf(SD59x18 x) internal pure returns (SD59x18) {
        // 1. Save the sign of x since erf(-x) = -erf(x)
        SD59x18 sign = x.gte(wrap(0)) ? wrap(1) : wrap(-1);
        x = abs(x);

        // 2. Pre-calculate the Taylor series terms for erf(x)
        SD59x18 twoOverSqrtPi = wrap(1_128_379_167_095_512_573); // 2/sqrt(pi) scaled by 1e18

        // Pre-calculated terms for the first 10 terms of the Taylor series
        SD59x18 term1 = x.div(convert(1)); // x^1 / 1!
        SD59x18 term2 = x.pow(convert(3)).div(convert(3)); // x^3 / 3!
        SD59x18 term3 = x.pow(convert(5)).div(convert(10)); // x^5 / 5!
        SD59x18 term4 = x.pow(convert(7)).div(convert(42)); // x^7 / 7!
        SD59x18 term5 = x.pow(convert(9)).div(convert(216)); // x^9 / 9!

        // Sum the terms, applying the alternating sign
        SD59x18 sum = term1.sub(term2).add(term3).sub(term4).add(term5);

        // Multiply the sum by 2/sqrt(pi)
        SD59x18 result = twoOverSqrtPi.mul(sum);

        // Apply the sign
        return sign.mul(result);
    }

    function cdf(SD59x18 x, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {
        // Calculate (x - mean) / (sigma * sqrt(2))
        SD59x18 z = (x.sub(mean)).div(sigma.mul(SD59x18.wrap(1_414_213_562_373_095_048))); // sqrt(2) scaled by 1e18
        // console2.log("z", z.unwrap());

        if (z.eq(wrap(0))) {
            return wrap(0.5e18);
        }
        // Calculate erf(z)
        SD59x18 erfResult = erf(z);
        // console2.log("erfResult", erfResult.unwrap());

        // Calculate CDF using the relation to erf
        SD59x18 cdfResult = SD59x18.wrap(0.5e18).mul(SD59x18.wrap(1e18).add(erfResult));

        return cdfResult;
    }

    /**
     * @notice Calculates the definite integral of the PDF between two points
     * @param a Lower bound of integration
     * @param b Upper bound of integration
     * @param mean The mean (μ) of the distribution
     * @param sigma The standard deviation (σ) of the distribution
     * @return The probability mass between a and b
     */
    function pdfIntegral(SD59x18 a, SD59x18 b, SD59x18 mean, SD59x18 sigma) internal pure returns (SD59x18) {
        // Calculate CDF at upper bound
        SD59x18 upperCdf = cdf(b, mean, sigma);
        // Calculate CDF at lower bound
        SD59x18 lowerCdf = cdf(a, mean, sigma);
        // Return the difference
        return upperCdf.sub(lowerCdf);
    }
}
