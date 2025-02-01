// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Foo } from "../src/Foo.sol";

contract Deploy  {
    function run() public  returns (Foo foo) {
        foo = new Foo();
    }
}
 