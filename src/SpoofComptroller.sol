pragma solidity ^0.8.10;

// to be used with liquidateBorrow
// see Foundry's etch cheat
contract SpoofComptroller {

  function liquidateBorrowAllowed( 
    address cTokenBorrowed, 
    address cTokenCollateral, 
    address liquidator, 
    address borrower, 
    uint repayAmount) external returns (uint) {
    
    return 0;

  }

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed, 
    address cTokenCollateral, 
    uint actualRepayAmount) external returns (uint, uint) {
    // Todo: calculate this correctly
    return (0, 1e6);

  }

}