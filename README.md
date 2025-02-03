# Probability Density Function Library [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

![PdfLib Logo](/assets/pdf-lib-sol-cover.png)

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

A library for Probability Density Functions in Solidity.

## Features

This library inclues a number of probability density functions, including:

- [pdf](/src/PdfLib.sol#L49): The probability density function
- [pdfDifference](/src/PdfLib.sol#L68): The difference between two pdfs
- [isMinimumPoint](/src/PdfLib.sol#L96): Checks if a point is the minimum point of a curve given by pdf2 - pdf1
- [isMaximumPoint](/src/PdfLib.sol#L123): Checks if a point is the maximum point of a curve given by pdf2 - pdf1
- [pdfDerivativeAtX](/src/PdfLib.sol#L180): The first derivative of a pdf at a given x
- [pdfSecondDerivativeAtX](/src/PdfLib.sol#L201): The second derivative of a pdf at a given x

There are [tests](/tests/PdfLib.t.sol) for each of these functions. And these test are run against reference data calculated in typescript based on [pdf-reference](/tests/scripts/pdf-reference.ts).

## License

This project is licensed under MIT.

Foundry template from [PaulRBerg](https://github.com/PaulRBerg/foundry-template)
