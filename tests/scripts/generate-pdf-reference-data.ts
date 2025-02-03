import { encodeAbiParameters, parseAbiParameters, parseEther } from 'viem';

import { normalDistributionPDF, pdfDerivative, pdfSecondDerivative } from './pdf-reference';
import { calculateDifferenceExtrema } from './pdf-test-utils';

// ----------------------------------------------------------------------------------------------------
// Test scripts
// ---------------------------------------------------------------------------------------------------- 

export const calculatePdf = (inputs: string[]) => {
  const [_, mean, stdDev, x] = inputsToNumbers(inputs)

  const pdf = normalDistributionPDF(mean, stdDev, x)
  const formattedPdf = BigInt(scientificToFixedPoint(pdf))

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
  const formattedDerivative = BigInt(scientificToFixedPoint(derivativeAtX))

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

export const calculatePdfDifference = (inputs: string[]) => {
  const [_, mean1, stdDev1, mean2, stdDev2, x] = inputsToNumbers(inputs)

  const pdfDifference = normalDistributionPDF(mean1, stdDev1, x) - normalDistributionPDF(mean2, stdDev2, x)
  const formattedPdfDifference = BigInt(scientificToFixedPoint(pdfDifference))

  const encoded = encodeAbiParameters(
    parseAbiParameters('int256 x'),
    [formattedPdfDifference]
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
  if (typeof obj === 'number') return BigInt(scientificToFixedPoint(obj))

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
    // @ts-ignore
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
  // Convert to string, keeping full precision
  let str = num.toString();

  // If no scientific notation, convert to scientific notation
  if (!str.includes('e')) {
    const n = num.toExponential()
    str = n.toString()
  }

  const [coefficient, exponent] = str.split('e').map(part => parseFloat(part || '0'));
  if (exponent < 0) {
    return Math.trunc(coefficient * 10 ** (18 + exponent)).toString()
  } else {
    return Math.trunc(coefficient * 10 ** exponent).toString()
  }
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
    case 'calculatePdfDifference':
      calculatePdfDifference(inputs)
      break
  }
}
run(process.argv.slice(2))

function test() {
  const a = 123.456e-9
  const b = 7878787878
  const c = -2.0568613326757935e-17
  const d = 4.2840997058421476e-10
  const e = 6.6768356e14
  const f = 0.12
  const g = 9

  const aFixed = scientificToFixedPoint(a)
  const bFixed = scientificToFixedPoint(b)
  const cFixed = scientificToFixedPoint(c)
  const dFixed = scientificToFixedPoint(d)
  const eFixed = scientificToFixedPoint(e)
  const fFixed = scientificToFixedPoint(f)
  const gFixed = scientificToFixedPoint(g)
  console.log(aFixed, aFixed.length)
  console.log(bFixed, bFixed.length)
  console.log(cFixed, cFixed.length)
  console.log(dFixed, dFixed.length)
  console.log(eFixed, eFixed.length)
  console.log(fFixed, fFixed.length)
  console.log(gFixed, gFixed.length)
}

// test()
