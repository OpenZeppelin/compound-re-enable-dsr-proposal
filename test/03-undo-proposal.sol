pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Helpers.sol";
import "./Globals.sol";
// import "../src/MakerInterfaces.sol";


contract PostProposal is Globals {

  uint256 initialcDaiSupply;
  uint256 initialDaiBalance;

  function setUp() public {
    
    vm.createSelectFork("mainnet", blockNumberOfInterest);
    // from scenario/src/Builder/InterestRateModelBuilder.ts, line 170
    irModel4 = new DAIInterestRateModelV4(2 ether, 0.9 ether, DaiPotAddress, DaiJugAddress, governorBravoAddress);

    initialcDaiSupply = cDai.totalSupply();
    initialDaiBalance = dai.balanceOf(cDaiAddress);

    uint256 proposalID = proposeIntegratingDSR();
    passProposal(proposalID);
    executeProposal(proposalID);

    // let's show that things have changed
    assertEq(address(cDai.implementation()), cDaiDelegateAddressDSR);
    assertEq(address(cDai.interestRateModel()), address(irModel4));


    increaseBlockTimestamp(60*60*24*365); // fifty days

    proposalID = proposeRemovingDSR();
    passProposal(proposalID);
    executeProposal(proposalID);
  }


  function test_cDaiSupplyIsUnchanged() public {
    uint endDaiSupply = cDai.totalSupply();
    assertEq(initialcDaiSupply, endDaiSupply);
  }


  

  function test_DaiBalanceHasAccruedInterest() public {
    uint endDaiBalance = dai.balanceOf(cDaiAddress);
    // have we accrued interest correctly
    console.log("initialDaiBalance: %s", initialDaiBalance);
    console.log("endDaiBalance: %s", endDaiBalance);
    assertApproxEqRel((initialDaiBalance*101)/100, endDaiBalance, 0.001e18);
  }

  function test_DelegateAddressIsOriginal() public {
    assertEq(address(cDai.implementation()), cDaiDelegateAddressCurrent);
  }

  function test_IRModelIsOriginal() public {
    assertEq(address(cDai.interestRateModel()), cDaiIRModelAddressCurrent);
  }


}