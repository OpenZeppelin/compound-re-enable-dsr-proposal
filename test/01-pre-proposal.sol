// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Helpers.sol";
import "./Globals.sol";
// import "../src/MakerInterfaces.sol";


contract PreProposal is Globals {

    function setUp() public {
      vm.createSelectFork("mainnet", blockNumberOfInterest);
    }

    function test_CurrentDelegateAddressIsCorrect() public {
      assertEq(cDai.implementation(), cDaiDelegateAddressCurrent);
    }

    function test_CurrentIRModelAddressIsCorrect() public {
      assertEq(address(cDai.interestRateModel()), cDaiIRModelAddressCurrent);
    }

    function test_DelegatesHaveZeroBalanceInPot() public {
      assertEq(pot.pie(cDaiDelegateAddressCurrent), 0);
      assertEq(pot.pie(cDaiDelegateAddressDSR), 0);
    }

    function test_cDaiHasZeroBalanceInPot() public {
      assertEq(pot.pie(cDaiAddress), 0);
    }
        
    function test_DelegatesHaveZeroBalanceInVat() public {
      assertEq(vat.dai(cDaiDelegateAddressCurrent), 0);
      assertEq(vat.dai(cDaiDelegateAddressDSR), 0);
    }
    
    function test_DelegatorHasNonZeroBalanceInVat() public {
      // The cDai contract should have some dai left over in the vat
      // Todo: what does this mean?
      assertGe(vat.dai(cDaiAddress), 0);
      console.log("vat.dai(CDaiAddress): %s", vat.dai(cDaiAddress)); // 10758279428878719677676031
      // Todo: what are its decimals?
    }

    function test_cDaiHasNotGivenAllowanceToDaiJoin() public {
      assertEq(cDai.allowance(cDaiAddress, DaiJoinAddress), 0);
    }
    
    function test_cDaiHasWhitelistedPotAndJoinInVat() public {
      assertEq(vat.can(cDaiAddress, DaiPotAddress), 1);
      assertEq(vat.can(cDaiAddress, DaiJoinAddress), 1);
    }

    function test_PrintcDaiAllowance() public {
      console.log("Allowance before: %s", cDai.allowance(cDaiAddress, DaiJoinAddress));
    }

}