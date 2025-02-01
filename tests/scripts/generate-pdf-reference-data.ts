import { encodeAbiParameters, parseAbiParameters, parseEther } from 'viem';

import { normalDistributionPDF, pdfDerivative, pdfSecondDerivative } from './pdf-reference';
import { calculateDifferenceExtrema } from './pdf-test-utils';

// ----------------------------------------------------------------------------------------------------
// Test scripts
// ---------------------------------------------------------------------------------------------------- 

export const calculatePdf = (inputs: string[]) => {
  const [_, mean, stdDev, x, scale] = inputsToNumbers(inputs)

  const pdf = normalDistributionPDF(mean, stdDev, x, scale)
  const formattedPdf = parseEther(scientificToDecimal(pdf))

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedPdf]
  )
  console.log(encoded)

  return encoded
}

export const calculateCurvePoints = (inputs: string[]) => {
  console.log(inputs)
  const [_, mean1, stdDev1, mean2, stdDev2, x, scale] = inputsToNumbers(inputs)

  const curve1 = {
    mean: mean1 * scale,
    stdDev: stdDev1 * scale,
  };

  const curve2 = {
    mean: mean2 * scale,
    stdDev: stdDev2 * scale,
  };

  const differenceExtrema = calculateDifferenceExtrema(curve1, curve2);
  // console.log({ differenceExtrema })

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
  const [_, mean, stdDev, x, scale] = inputsToNumbers(inputs)

  const curve = {
    mean,
    stdDev,
  }

  const derivativeAtX = pdfDerivative(curve)(x, scale)
  // console.log(derivativeAtX)

  const formattedDerivative = parseEther(scientificToDecimal(derivativeAtX))
  //console.log(parsedToEther)

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedDerivative]
  )

  console.log(encoded)
  return encoded
}

export const calculateSecondDerivative = (inputs: string[]) => {
  const [_, mean, stdDev, x, scale] = inputsToNumbers(inputs)

  const curve = {
    mean,
    stdDev,
  }

  const secondDerivativeAtX = pdfSecondDerivative(curve)(x, scale)
  // console.log(secondDerivativeAtX)

  const formattedSecondDerivative = parseEther(scientificToDecimal(secondDerivativeAtX))
  //console.log(parsedToEther)

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
  if (typeof obj === 'number') return parseEther(scientificToDecimal(obj))

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
    'struct MarketData {Curve c1; Curve c2; DifferenceExtrema diff; int256 x; }'
  ])

  return encodeAbiParameters(
    params,
    [[pdfTestData.curve1, pdfTestData.curve2, pdfTestData.differenceExtrema, pdfTestData.x]]
  )
}

function scientificToDecimal(num: number): string {
  // Convert to string with maximum precision
  const str = num.toFixed(20);
  // Remove trailing zeros after decimal point
  return str.replace(/\.?0+$/, '');
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

