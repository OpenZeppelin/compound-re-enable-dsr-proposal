// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Helpers is Test {
    function increaseBlockNumber(uint256 increment) public {
        vm.roll(block.number + increment);
        vm.warp(block.timestamp + (increment * 12)); // 12 is the avg second
    }

    function increaseBlockTimestamp(uint256 increment) public {
        vm.warp(block.timestamp + increment);
        vm.roll(block.number + (increment / 12));
    }
}
