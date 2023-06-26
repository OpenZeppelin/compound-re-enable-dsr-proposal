// SPDX-License-Identifier: None
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Helpers.sol";
import "./Globals.sol";
// import "../src/MakerInterfaces.sol";


contract Liquidations is Globals {

    address immutable alice = address(0x123456); // borrower
    address immutable bob = address(0x654321); // liquidator

  function logState(string memory s) public {
    console.log("=== %s ===", s);
    console.log("Alice WBTC balance: %e", WBTC.balanceOf(alice));
    console.log("Alice cWBTC balance: %e", cWBTC2.balanceOf(alice));
    console.log("Alice Dai balance: %e", dai.balanceOf(alice));
    console.log("Bob WBTC balance: %e", WBTC.balanceOf(bob));
    console.log("Bob cWBTC balance: %e", cWBTC2.balanceOf(bob));
    console.log("Bob Dai balance: %e", dai.balanceOf(bob));
  }

  function setUp() public {
    vm.createSelectFork("mainnet");
    irModel4 = new DAIInterestRateModelV4(2 ether, 0.9 ether, DaiPotAddress, DaiJugAddress, governorBravoAddress);
    // Pass the compound proposal
    uint256 proposalID = proposeIntegratingDSR();
    passProposal(proposalID);
    executeProposal(proposalID);
  }

  // Bob and alice both borrow, and bob liquidates a portion of alice's position after the price drop
  // Price drop is simulated by an oracle that always returns the price of 1 for all assets
  function test_CanLiquidateAfterPriceDrop() public {

    uint cDAI_BORROW_AMOUNT = 15e22;
    vm.deal(alice,1000 ether);
    vm.deal(bob, 1000 ether);

    vm.startPrank(alice);
    console.log("Alice Eth: %s", alice.balance);

    console.log("####Alice Borrow####");
    console.log("Alice is locking in cEth to borrow dai");
    console.log("----Minting----");
    cEth.mint{value: 100 ether}();
    console.log("Alice Eth: %s", alice.balance);
    console.log("Alice cEth: %s", cEth.balanceOf(alice));
    console.log("Alice cDAI: %s", dai.balanceOf(alice));

    console.log("----Borrowing----");
    address[] memory marketTargets = new address[](1);
    marketTargets[0] = cEthAddress;
    comptroller.enterMarkets(marketTargets);
    cDai.borrow(cDAI_BORROW_AMOUNT);

    console.log("Alice cDAI: %s", dai.balanceOf(alice));
    vm.stopPrank();

    vm.startPrank(bob);
    console.log("Bob Eth: %s", bob.balance);
    
    console.log("####Bob Borrow####");
    console.log("Bob is locking in cEth to borrow dai");
    console.log("----Minting----");
    cEth.mint{value: 300 ether}();
    console.log("Bob Eth: %s", bob.balance);
    console.log("Bob cEth: %s", cEth.balanceOf(bob));
    console.log("Bob cDAI: %s", dai.balanceOf(bob));

    console.log("####Borrowing####");
    comptroller.enterMarkets(marketTargets);
    cDai.borrow(3 * cDAI_BORROW_AMOUNT);

    console.log("Bob cDAI: %s", dai.balanceOf(bob));
    vm.stopPrank();


    console.log("####Changing Comptroller's oracle####");
    address comptrollerAdmin = comptroller.admin();

    vm.startPrank(comptrollerAdmin);
    address currentOracle = comptroller.oracle();

    console.log("Actual price of ctoken: %s", IOracle(currentOracle).getUnderlyingPrice(cEthAddress));

    comptroller._setPriceOracle(address(new FakeOracle()));
    address updatedOracle = comptroller.oracle();

    console.log("Forged price of ctoken: %s", IOracle(updatedOracle).getUnderlyingPrice(cEthAddress));
    vm.stopPrank();

    console.log("####Liquidation####");
    uint borrowBalanceBefore;
    uint borrowBalanceAfter;
    (,,borrowBalanceBefore,) = cDai.getAccountSnapshot(alice);

    uint aliceCEthBalanceBefore = cEth.balanceOf(alice);
    uint bobCEthBalanceBefore = cEth.balanceOf(bob);
    console.log("Alice's borrow balance before the liquidation is %s with collateral balance of %s (cEth)", borrowBalanceBefore, aliceCEthBalanceBefore);
    console.log("Bob's cEth balance before the liquidation is %s", bobCEthBalanceBefore);

    console.log("----Bob is liquidating Alice's position----");
    vm.startPrank(bob);
    dai.approve(cDaiAddress, 10 ether);
    cDai.liquidateBorrow(alice, 10 ether, cEth);
    vm.stopPrank();

    (,,borrowBalanceAfter,) = cDai.getAccountSnapshot(alice);
    uint aliceCEthBalanceAfter = cEth.balanceOf(alice);
    uint bobCEthBalanceAfter = cEth.balanceOf(bob);

    console.log("Alice's borrow balance after the liquidation is %s with collateral balance of %s (cEth)", borrowBalanceAfter, aliceCEthBalanceAfter);
    console.log("Bob's cEth balance after the liquidation is %s", bobCEthBalanceAfter);

    assertEq(aliceCEthBalanceBefore - aliceCEthBalanceAfter, bobCEthBalanceAfter - bobCEthBalanceBefore);
    assertTrue(borrowBalanceAfter < borrowBalanceBefore);
  }
}