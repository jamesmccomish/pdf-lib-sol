import { Curve, difference, normalDistributionPDF, pdfDerivative } from './pdf-reference';

/**
 * @notice A set of utils for getting data for testing the pdf
 * 
 * @author peterferguson https://github.com/peterferguson
 * Modified from Onit Labs, Forecast Distribution Market
 */

/**
 * @notice Creates a function that returns the difference between two normal distributions
 */
export function createDifferenceData(curve1: any, curve2: any) {
  return (x: number) => {
    const c1 = normalDistributionPDF(curve1.mean, curve1.stdDev, x);
    const c2 = normalDistributionPDF(curve2.mean, curve2.stdDev, x);
    return { x, y: c2 - c1 };
  };
}

/**
 * @notice Calculates the minimum and maximum points of the difference between two normal distributions
 */
export function calculateDifferenceExtrema(curve1: any, curve2: any) {
  // Calculate domain based on curves
  const mean1 = curve1.mean;
  const mean2 = curve2.mean;
  const stdDev1 = curve1.stdDev;
  const stdDev2 = curve2.stdDev;

  // Taking 4 standard deviations from the mean covers 99.99% of the data
  const xMin = Math.min(mean1 - 4 * stdDev1, mean2 - 4 * stdDev2);
  const xMax = Math.max(mean1 + 4 * stdDev1, mean2 + 4 * stdDev2);

  // Create samples with more points for better initial guesses
  const samples = 1000;
  const step = (xMax - xMin) / (samples - 1);
  const xValues = Array.from({ length: samples }, (_, i) => xMin + step * i);

  // Calculate difference at each point
  const diffData = xValues.map(x => createDifferenceData(curve1, curve2)(x));

  const minPointApprox = diffData.reduce((min, point) => point.y < min.y ? point : min);
  const maxPointApprox = diffData.reduce((max, point) => point.y > max.y ? point : max);

  return {
    min: getTurningPoint(curve1, curve2, minPointApprox.x, "min"),
    max: getTurningPoint(curve1, curve2, maxPointApprox.x, "max")
  };
}

/**
 * @notice The zero point of the derivative of the difference between two normal distributions
 *
 * @dev Used in minimum and maximum point calculations
 */
export function getTurningPoint(
  firstCurve: Pick<Curve, "mean" | "stdDev">,
  secondCurve: Pick<Curve, "mean" | "stdDev">,
  initialX: number,
  turningPoint: "min" | "max"
) {
  const derivativeFn = differenceDerivative(secondCurve, firstCurve);
  // For max points, we negate the derivative to turn the problem into finding a minimum
  const adjustedDerivativeFn = turningPoint === "max"
    ? (x: number) => -derivativeFn(x)
    : derivativeFn;

  const gradientDescentResult = gradientDescent(
    adjustedDerivativeFn,
    initialX,
    0.01,
    10000,
    1e-6,
    0.5,
    turningPoint
  );

  return {
    x: gradientDescentResult,
    y: difference(secondCurve, firstCurve)(gradientDescentResult),
  };
}

/**
 * @notice The derivative of the difference between two normal distributions
 *
 * @dev Used in minimum and maximum point calculations
 */
export function differenceDerivative(
  firstCurve: Pick<Curve, "mean" | "stdDev">,
  secondCurve: Pick<Curve, "mean" | "stdDev">
) {
  return (x: number) => {
    return pdfDerivative(secondCurve)(x) - pdfDerivative(firstCurve)(x);
  };
}

/**
 * @notice Simple gradient descent when sensible initial values are known
 */
export function gradientDescent(
  derivative: (x: number) => number,
  initialX: number,
  stepSize: number,
  maxIterations: number,
  tolerance: number,
  stepReductionFactor: number,
  turningPoint: "min" | "max"
) {
  let x = initialX;
  let currentStepSize = stepSize;
  let previousGradient = Infinity;
  let oscillationCount = 0;

  for (let i = 0; i < maxIterations; i++) {
    const gradient = derivative(x);

    // Check if we've reached desired precision
    if (Math.abs(gradient) < tolerance) {
      // Verify we've found the correct type of turning point
      const nextGradient = derivative(x + 0.0001);
      const isCorrectTurningPoint = turningPoint === "min"
        ? nextGradient > gradient  // For minimum, gradient should be increasing
        : nextGradient < gradient; // For maximum, gradient should be decreasing

      if (isCorrectTurningPoint) {
        break;
      }
    }

    // Detect oscillation by checking if gradient changed sign
    if (Math.sign(gradient) !== Math.sign(previousGradient)) {
      oscillationCount++;
      // If oscillating, reduce step size
      if (oscillationCount > 2) {
        currentStepSize *= stepReductionFactor;
        oscillationCount = 0;
      }
    }

    // Store current gradient for next iteration
    previousGradient = gradient;

    // Update x with adaptive step size
    x = x - currentStepSize * gradient;
  }

  return x;
}