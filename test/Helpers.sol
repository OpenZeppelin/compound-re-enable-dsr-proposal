// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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

interface IOracle {
  function getUnderlyingPrice(address)
        external
        view
        returns (uint256);
}

contract FakeOracle is IOracle{
   // a fake price return to check the liquidation by returning the price 1 for everything (or small amount)
   // If you need to check other cases consider dividing the actual price by a denominator
  function getUnderlyingPrice(address asset)
        external
        view
        returns (uint256)
        {
          return 1;
          // return IOracle(ORACLE_ADDRESS).getUnderlyingPrice(asset) / DENOMINATOR;
        }
}