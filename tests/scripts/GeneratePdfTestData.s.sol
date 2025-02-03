// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* solhint-disable no-console */

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

struct Curve {
    int256 mean;
    int256 stdDev;
}

struct Point {
    int256 x;
    int256 y;
}

struct DifferenceExtrema {
    Point min;
    Point max;
}

struct PdfTestData {
    Curve curve1;
    Curve curve2;
    DifferenceExtrema differenceExtrema;
    int256 x;
}

contract GeneratePdfTestData is Test {
    function calculatePdf(int256 mean, int256 stdDev, int256 x) public returns (int256) {
        string[] memory cmd = new string[](6);

        cmd[0] = "bun";
        cmd[1] = "tests/scripts/generate-pdf-reference-data.ts";
        cmd[2] = "calculatePdf";
        cmd[3] = vm.toString(mean);
        cmd[4] = vm.toString(stdDev);
        cmd[5] = vm.toString(x);

        bytes memory res = vm.ffi(cmd);
        int256 result = abi.decode(res, (int256));
        return result;
    }

    function calculateCurvePoints(
        int256 mean1,
        int256 stdDev1,
        int256 mean2,
        int256 stdDev2,
        int256 x
    )
        public
        returns (PdfTestData memory)
    {
        string[] memory cmd = new string[](8);

        cmd[0] = "bun";
        cmd[1] = "tests/scripts/generate-pdf-reference-data.ts";
        cmd[2] = "calculateCurvePoints";
        cmd[3] = vm.toString(mean1);
        cmd[4] = vm.toString(stdDev1);
        cmd[5] = vm.toString(mean2);
        cmd[6] = vm.toString(stdDev2);
        cmd[7] = vm.toString(x);

        bytes memory res = vm.ffi(cmd);
        PdfTestData memory data = abi.decode(res, (PdfTestData));
        return data;
    }

    function calculateDerivative(int256 mean, int256 stdDev, int256 x) public returns (int256) {
        string[] memory cmd = new string[](6);

        cmd[0] = "bun";
        cmd[1] = "tests/scripts/generate-pdf-reference-data.ts";
        cmd[2] = "calculateDerivative";
        cmd[3] = vm.toString(mean);
        cmd[4] = vm.toString(stdDev);
        cmd[5] = vm.toString(x);

        bytes memory res = vm.ffi(cmd);
        int256 result = abi.decode(res, (int256));
        return result;
    }

    function calculateSecondDerivative(int256 mean, int256 stdDev, int256 x) public returns (int256) {
        string[] memory cmd = new string[](6);

        cmd[0] = "bun";
        cmd[1] = "tests/scripts/generate-pdf-reference-data.ts";
        cmd[2] = "calculateSecondDerivative";
        cmd[3] = vm.toString(mean);
        cmd[4] = vm.toString(stdDev);
        cmd[5] = vm.toString(x);

        bytes memory res = vm.ffi(cmd);
        int256 result = abi.decode(res, (int256));
        return result;
    }

    function calculatePdfDifference(
        int256 mean1,
        int256 stdDev1,
        int256 mean2,
        int256 stdDev2,
        int256 x
    )
        public
        returns (int256)
    {
        string[] memory cmd = new string[](8);

        cmd[0] = "bun";
        cmd[1] = "tests/scripts/generate-pdf-reference-data.ts";
        cmd[2] = "calculatePdfDifference";
        cmd[3] = vm.toString(mean1);
        cmd[4] = vm.toString(stdDev1);
        cmd[5] = vm.toString(mean2);
        cmd[6] = vm.toString(stdDev2);
        cmd[7] = vm.toString(x);

        string memory formatted = formatScriptRun(cmd);
        console2.log(formatted);

        bytes memory res = vm.ffi(cmd);
        int256 result = abi.decode(res, (int256));
        return result;
    }

    function formatScriptRun(string[] memory cmd) public pure returns (string memory formatted) {
        for (uint256 i = 0; i < cmd.length; i++) {
            formatted = string.concat(formatted, cmd[i]);
            if (i < cmd.length - 1) {
                formatted = string.concat(formatted, " ");
            }
        }
    }
}
