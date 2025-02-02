import { encodeAbiParameters, parseAbiParameters, parseEther } from 'viem';

import { normalDistributionPDF, pdfDerivative, pdfSecondDerivative } from './pdf-reference';
import { calculateDifferenceExtrema } from './pdf-test-utils';

// ----------------------------------------------------------------------------------------------------
// Test scripts
// ---------------------------------------------------------------------------------------------------- 

export const calculatePdf = (inputs: string[]) => {
  const [_, mean, stdDev, x] = inputsToNumbers(inputs)

  const pdf = normalDistributionPDF(mean, stdDev, x)
  const formattedPdf = parseEther(scientificToFixedPoint(pdf))

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedPdf]
  )
  console.log(encoded)

  return encoded
}

export const calculateCurvePoints = (inputs: string[]) => {
  const [_, mean1, stdDev1, mean2, stdDev2, x] = inputsToNumbers(inputs)

  const curve1 = {
    mean: mean1,
    stdDev: stdDev1,
  };

  const curve2 = {
    mean: mean2,
    stdDev: stdDev2,
  };

  const differenceExtrema = calculateDifferenceExtrema(curve1, curve2);

  const pdfTestData = {
    curve1,
    curve2,
    x,
    differenceExtrema,
  }

  const encoded = encodePdfTestData(allObjectValuesToBigInt(pdfTestData))
  console.log(encoded)

  return encoded;
}

export const calculateDerivative = (inputs: string[]) => {
  const [_, mean, stdDev, x] = inputsToNumbers(inputs)

  const curve = {
    mean,
    stdDev,
  }

  const derivativeAtX = pdfDerivative(curve)(x)
  // console.log(derivativeAtX)

  const formattedDerivative = BigInt(scientificToFixedPoint(derivativeAtX))
  //console.log(parsedToEther)

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedDerivative]
  )

  console.log(encoded)
  return encoded
}

export const calculateSecondDerivative = (inputs: string[]) => {
  const [_, mean, stdDev, x] = inputsToNumbers(inputs)

  const curve = {
    mean,
    stdDev,
  }

  const secondDerivativeAtX = pdfSecondDerivative(curve)(x)

  const formattedSecondDerivative = BigInt(scientificToFixedPoint(secondDerivativeAtX))

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedSecondDerivative]
  )
  console.log(encoded)
  return encoded
}

// ----------------------------------------------------------------------------------------------------
// Helper functions
// ----------------------------------------------------------------------------------------------------

function inputsToNumbers(inputs: string[]) {
  return inputs.map(input => Number(input))
}

function allObjectValuesToBigInt(obj: any): any {
  if (typeof obj === 'number') return parseEther(scientificToFixedPoint(obj))

  if (typeof obj !== 'object' || obj === null) return obj;

  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [key, allObjectValuesToBigInt(value)])
  );
}

function encodePdfTestData(pdfTestData: any) {
  const params = parseAbiParameters([
    'PdfTestData pdfTestData',
    'struct Curve {int256 mean; int256 stdDev;}',
    'struct Point {int256 x; int256 y;}',
    'struct DifferenceExtrema {Point min; Point max;}',
    'struct PdfTestData {Curve c1; Curve c2; DifferenceExtrema diff; int256 x;}'
  ])

  return encodeAbiParameters(
    params,
    [[pdfTestData.curve1, pdfTestData.curve2, pdfTestData.differenceExtrema, pdfTestData.x]]
  )
}

/**
 * @notice Convert a number to Solidity's fixed-point representation (18 digits)
 * 
 * eg. -2.0568613326757935e-17 -> "-20" 
 * eg. 3.6 -> "3600000000000000000" 
 */
function scientificToFixedPoint(num: number): string {
  //console.log('num', num)
  // Convert to decimal string, keeping full precision
  const str = num.toString();
  //console.log('Decimal string:', str)

  // Parse scientific notation if present
  const [coefficient, exponent] = str.split('e').map(part => parseFloat(part || '0'));
  const finalNum = coefficient * Math.pow(10, exponent || 0);
  // console.log('Parsed number:', finalNum)
  return finalNum.toString()
}

// ----------------------------------------------------------------------------------------------------
// Run script
// ----------------------------------------------------------------------------------------------------

function run(inputs) {
  switch (inputs[0]) {
    case 'calculatePdf':
      calculatePdf(inputs)
      break
    case 'calculateCurvePoints':
      calculateCurvePoints(inputs)
      break
    case 'calculateDerivative':
      calculateDerivative(inputs)
      break
    case 'calculateSecondDerivative':
      calculateSecondDerivative(inputs)
      break
  }
}
run(process.argv.slice(2))

