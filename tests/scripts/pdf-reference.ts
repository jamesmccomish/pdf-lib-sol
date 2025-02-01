/**
 * @notice The probability density function of a normal distribution
 *
 * @dev Equivalent to the pdf function in the PdfLib.sol contract
 */
export const normalDistributionPDF = (
  mean: number,
  stdDev: number,
  x: number,
  scale: number = 1
) => {
  const numerator = Math.exp(-((x - mean) ** 2) / (2 * stdDev ** 2));
  const denominator = stdDev * Math.sqrt(2 * Math.PI);
  const result = (scale * numerator) / denominator;
  return result;
};

export function getNormalDistributionMaxY(
  curve: Pick<Curve, "mean" | "stdDev">
) {
  return 1 / (curve.stdDev * Math.sqrt(2 * Math.PI));
}

export type Curve = {
  mean: number;
  stdDev: number;
};

/**
 * @notice The difference between two normal distributions
 *
 * @dev Equivalent to the pdfDifference function in the PdfLib.sol contract
 */
export function difference(
  firstCurve: Pick<Curve, "mean" | "stdDev">,
  secondCurve: Pick<Curve, "mean" | "stdDev">
) {
  return (x: number) => {
    return (
      normalDistributionPDF(firstCurve.mean, firstCurve.stdDev, x) -
      normalDistributionPDF(secondCurve.mean, secondCurve.stdDev, x)
    );
  };
}

/**
 * @notice The derivative of the probability density function of a normal distribution
 *
 * @dev Equivalent to the pdfDerivativeAtX function in the PdfLib.sol contract
 *      p'(x) = -(x-μ)/σ² * p(x)
 */
export function pdfDerivative(curve: Pick<Curve, "mean" | "stdDev">) {
  return (x: number, scale: number = 1) =>
    -scale *
    ((x - curve.mean) / curve.stdDev ** 2) *
    normalDistributionPDF(curve.mean, curve.stdDev, x, scale);
}

/**
 * @notice The second derivative of the probability density function of a normal distribution
 *
 * @dev Equivalent to the pdfSecondDerivativeAtX function in the PdfLib.sol contract
 *      p''(x) = [(x-μ)²/σ⁴ - 1/σ²] * p(x)
 */
export function pdfSecondDerivative(curve: Pick<Curve, "mean" | "stdDev">) {
  return (x: number, scale: number = 1) => {
    const xMinusMean = x - curve.mean;
    const xMinusMeanSquared = xMinusMean ** 2;
    const term1 = (scale * scale * xMinusMeanSquared) / curve.stdDev ** 4;
    const term2 = (scale * scale) / curve.stdDev ** 2;
    return (
      (term1 - term2) *
      normalDistributionPDF(curve.mean, curve.stdDev, x, scale)
    );
  };
}




