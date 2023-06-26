pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Helpers.sol";
import "./Globals.sol";
// import "../src/MakerInterfaces.sol";


contract PokeTest is Globals {

  function setUp() public {
    vm.createSelectFork("mainnet", blockNumberOfInterest);

    // from scenario/src/Builder/InterestRateModelBuilder.ts, line 170
    irModel4 = new DAIInterestRateModelV4(2 ether, 0.9 ether, DaiPotAddress, DaiJugAddress, governorBravoAddress);
  }
  // This test is to pull the multiplierPerBlock and jumpMultiplierPerBlock from the proposed interest rate model
  // These variables depend on calls to Maker's contracts and therefore were difficult to predict
  // See DAIInterestRateModelv4.poke() 
  function test_PrintMultiplierPerBlock() public {
    console.log("multiplierPerBlock: %s", irModel4.multiplierPerBlock());
    console.log("jumpMultiplierPerBlock: %s", irModel4.jumpMultiplierPerBlock());
  }

}