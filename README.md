# compound-re-enable-dsr-proposal

This repository contains Foundry tests for a Compound proposal that reinstates Dai Savings Rates for cDAI. Previously, cDAI was connected to MakerDAO's Dai Savings Rate (DSR) which was set at 0.01% yield by Maker Governance at the time. Since the yield was too low, the Compound team passed a proposal which removed the support for the DSR in an effort to save gas. Recently, Maker has reinstated the DSR's yield at an annualized 1%. This is independent of the amount of DAI deposited. For this reason, this proposal is intended to reactivate the DSR for cDAI.


## How to run the tests

**1. Clone the repository** 

`git clone git@github.com:OpenZeppelin/compound-re-enable-dsr-proposal.git`

**2. Set or export the RPC_MAINNET env var** 

We run these tests against Ethereum Mainnet. So foundry will need to know what RPC endpoint to use. You can set your the RPC directly in `foundry.toml` or set your environment variable `RPC_MAINNET` to it instead. You can get a free RPC URL from Alchemy or Infura. An example of temporarily exporting your RPC string:

`export RPC_MAINNET=https://eth-mainnet.g.alchemy.com/v2/<Your Token>`

**3. Run the tests** 

To run the tests simply run the command:

`forge test`

## Test Summary

A fork of the Ethereum Mainnet is created at block `16820728`, where we simulate the effects of the DSR proposal.

During the setup, the Reinstate DSR proposal is created and sent to the Compound Governor Bravo as if it was as submitted by a large COMP stakeholder. Then, acting as other COMP stakeholders, the proposal is voted on and the time is forwarded to the point where the proposal is ready to be queued. The proposal then gets queued and after more time passes, it finally gets executed.

Once the proposal is executed, the first tests validate that the DSR is now active for cDAI by verifying that the Implementation for `cDAI` is the `cDAIDelegateAddress` and that its interest rate is calculated by the `DAIIRModelAddress`. Balances are also validated to ensure that the DSR is working as expected.

Tests are now run to ensure that the `cDAI` contract is functioning as normal, by executing `borrow`, `repayBorrow`, `mint` and `reedem`  transactions while ensuing that the balances are updated correctly.

Finally, DSR interest rate calculations are also tested to ensure that they are correct and that `cDAI` users are being rewarded with the `DSR` yield alongside the normal `cDAI` yields.
