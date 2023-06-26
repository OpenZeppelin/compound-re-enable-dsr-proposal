pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Helpers.sol";
import "./Globals.sol";
// import "../src/MakerInterfaces.sol";


contract PostProposal is Globals {

  uint256 initialDaiBalance;
  uint256 initialCDaiBalance;

  function setUp() public {

    vm.createSelectFork("mainnet", blockNumberOfInterest);

    // from scenario/src/Builder/InterestRateModelBuilder.ts, line 170
    irModel4 = new DAIInterestRateModelV4(2 ether, 0.9 ether, DaiPotAddress, DaiJugAddress, governorBravoAddress);

    initialDaiBalance = dai.balanceOf(cDaiAddress);
    initialCDaiBalance = cDai.totalSupply();
    // Pass the compound proposal
    uint256 proposalID = proposeIntegratingDSR();
    passProposal(proposalID);
    executeProposal(proposalID);
  }

  function test_cDaiImplementationIsProposedAddress() public {
    assertEq(cDai.implementation(), cDaiDelegateAddressDSR);
  }

  function test_cDaiIRModelIsProposedAddress() public {
    assertEq(address(cDai.interestRateModel()), address(irModel4));
  }

  function test_cDaiNowHasHasCorrectDaiJoinAddress() public {
      assertEq(
        CDaiDelegate(cDaiAddress).daiJoinAddress(),
        DaiJoinAddress
      );
    }

    function test_cDaiNowHasHasCorrectPotAddress() public {
      assertEq(
        CDaiDelegate(cDaiAddress).potAddress(),
        DaiPotAddress
      );
    }

    function test_cDaiNowHasHasCorrectVatAddress() public {
      assertEq(
        CDaiDelegate(cDaiAddress).vatAddress(),
        DaiVatAddress
      );
    }

  function test_cDaiBalanceInDaiIsZero() public {
    // the proposal is to move everything into the pot, so this should be zero
    assertEq(dai.balanceOf(cDaiAddress), 0);
  }

  function test_cDaiDSRDelegateBalanceInDaiIsZero() public {
    assertEq(dai.balanceOf(cDaiDelegateAddressDSR), 0);
  }

  function test_cDaiDSRDelegateBalanceInPotIsZero() public {
    assertEq(pot.pie(cDaiDelegateAddressDSR), 0);
  }

  function test_cDaiBalanceInDaiIsInPot() public {
    assertEq(
            pot.pie(cDaiAddress),
            (initialDaiBalance * 10 ** 27) / pot.chi()
        );
  }

  function test_PrintVatBalanceOfcDai() public {
    console.log("vat.dai(cDaiAddress): %s", vat.dai(cDaiAddress));
  }

  function test_PrintcDaiAllowance() public {
    console.log("Allowance after: %s", cDai.allowance(cDaiAddress, DaiJoinAddress));
  }

  function test_PotCanModifyVatBalancesForCDai() public {
    assertEq(vat.can(cDaiAddress, DaiPotAddress), 1);
        
  } 

  function test_DaiJoinCanModifyVatBalancesForCDai() public {
    assertEq(vat.can(cDaiAddress, DaiJoinAddress), 1);
  }

  function test_PrintPotDsr() public {
    console.log("pot.dsr(): %s", pot.dsr());
  }

  function test_IsInterestAccruedOverTimeForCDaiAtOnePercent() public {
    pot.drip();
    // dai = wad * chi
    uint256 cDaiDaiBalanceStart = pot.pie(cDaiAddress) * pot.chi();
    console.log("vat.dai(address(cDai)) before: %s", vat.dai(address(cDai)));
    console.log("chi: %s", pot.chi());
    console.log("pot.pie(cDaiAddress): %s", pot.pie(cDaiAddress));
    console.log("cDaiDaiBalanceStart: %s", cDaiDaiBalanceStart);
    
    increaseBlockTimestamp(365*24*60*60);
    pot.drip();
    uint256 cDaiDaiBalanceEnd = pot.pie(cDaiAddress) * pot.chi();
    console.log("vat.dai(address(cDai)) after: %s", vat.dai(address(cDai)));
    console.log("chi: %s", pot.chi());
    console.log("pot.pie(cDaiAddress): %s", pot.pie(cDaiAddress));
    console.log("cDaiDaiBalanceEnd: %s", cDaiDaiBalanceEnd);

    
    assertApproxEqRel((cDaiDaiBalanceStart*101)/100, cDaiDaiBalanceEnd, 0.00001e18);
    // we don't want the above test to be vacuously true
    assertGt(cDaiDaiBalanceStart,0);
  }

  function test_PrintDaiJoinDotDai() public {
    console.logString("daiJoin.dai()");
    console.logAddress(address(DaiJoinLike(DaiJoinAddress).dai()));
  }

  function test_BlockRateIs12PerSecond() public {
    uint irBlocksPerYear = DAIInterestRateModelV4(address(cDai.interestRateModel())).blocksPerYear();
    uint postMergeBlocksPerYear = 365*24*60*60/12;
    assertEq(irBlocksPerYear, postMergeBlocksPerYear);
  }

  function test_CanUsersBorrowCDaiAndRepay() public {
    // From this TX: https://etherscan.io/tx/0x8c000144e6ffe856d6049d8c07a0ec8630b7acaeb1360b62d6071ad5e8266076#eventlog
        address alice = address(0x173Ac361f92F8Ba8bD42EFeB46c1EdFf36111A07);
        uint256 borrowAmount = 4200000000000000000000;
        
        // User should have zero dai
        assertEq(dai.balanceOf(alice), 0);
        // User attempts to borrows dai
        vm.startPrank(alice);
        cDai.borrow(borrowAmount);
        // Did the dai go to the user?
        assertEq(dai.balanceOf(alice), borrowAmount);
        // User attempts to repay loan
        cDai.repayBorrow(borrowAmount);
        // Does the user have any dai?
        assertEq(dai.balanceOf(alice), 0);
        vm.stopPrank();
  }


  // Transfer
  function test_CanUserBorrowAndTransfer() public {
    // random addresses
    address alice = address(0xDbc05b1eCB4fdaEf943819C0B04e9ef6df4bAbd6);
    address bob = address(0x721B68fA152a930F3df71F54aC1ce7ed3ac5f867);
    uint cDAI_BORROW_AMOUNT = 1e6;
    vm.deal(alice,1000 ether);
    vm.startPrank(alice);
    console.log("Alice Eth: %s", alice.balance);
    
    console.log("----Minting----");
    cEth.mint{value: 100 ether}();
    console.log("Alice Eth: %s", alice.balance);
    console.log("Alice cEth: %s", cEth.balanceOf(alice));

    console.log("----Borrowing----");
    address[] memory marketTargets = new address[](1);
    marketTargets[0] = cEthAddress;
    comptroller.enterMarkets(marketTargets);
    uint borrowReturn = cDai.borrow(cDAI_BORROW_AMOUNT);
    console.logUint(borrowReturn);
    // emit Failure(error: 3, info: 14, detail: 4)
    // Error: INSUFFICIENT_SHORTFALL
    // Info:  SET_PENDING_ADMIN_OWNER_CHECK
    // Detail: 14

    console.log("Alice Eth: %s", alice.balance);
    console.log("Alice cEth: %s", cEth.balanceOf(alice));
    console.log("Alice Dai: %s", dai.balanceOf(alice));


    
    console.log("----Transferring----");
    dai.transfer(bob, cDAI_BORROW_AMOUNT);
    console.log("Alice Eth: %s", alice.balance);
    console.log("Alice cEth: %s", cEth.balanceOf(alice));
    console.log("Alice Dai: %s", dai.balanceOf(alice));
    vm.stopPrank();

    // alice should have nothing
    // assertEq(dai.balanceOf(alice), 0 );
    console.log("dai.balanceOf(alice): %s", dai.balanceOf(alice));
    // bob should have alice's entire borrow
    // assertEq(dai.balanceOf(bob), 1e18);
    console.log("dai.balanceOf(bob): %s", dai.balanceOf(bob));

  }

}