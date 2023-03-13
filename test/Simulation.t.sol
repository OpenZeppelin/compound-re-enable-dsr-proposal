// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./Helpers.sol";
import "../src/IGovernorBravo.sol";
import "../src/CTokenInterfaces.sol";
import "../src/IERC20.sol";
import "../src/MakerInterfaces.sol";

contract SimulationTest is Helpers {
    // Contracts
    address public cDAIDelegateAddress =
        address(0xbB8bE4772fAA655C255309afc3c5207aA7b896Fd);
    address public DAIIRModelAddress =
        address(0xfeD941d39905B23D6FAf02C8301d40bD4834E27F);
    address public cDAIAddress =
        address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address public DAIAddress =
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public DAIJoinAddress =
        address(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    address public DAIPotAddress =
        address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address public DAIVatAddress =
        address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address public DSPauseAddress =
        address(0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB);

    IGovernorBravo governorBravo =
        IGovernorBravo(0xc0Da02939E1441F497fd74F78cE7Decb17B66529);

    CErc20Interface cDAI = CErc20Interface(cDAIAddress);

    PotLike pot = PotLike(DAIPotAddress);

    VatLike vat = VatLike(DAIVatAddress);

    IERC20 dai = IERC20(DAIAddress);

    // Voters
    address public PolychainCapital =
        address(0xea6C3Db2e7FCA00Ea9d7211a03e83f568Fc13BF7);

    address public BrainCapitalVentures =
        address(0x61258f12C459984F32b83C86A6Cc10aa339396dE);

    address public a16z = address(0x9AA835Bc7b8cE13B9B0C9764A52FbF71AC62cCF1);

    // Variables
    uint256 initialDAIBalance;

    /// @notice Setups the required state for the rest of the tests
    /// @dev We create, vote and execute the proposal to renable DSR as
    /// well as making some checks
    function setUp() public {
        initialDAIBalance = dai.balanceOf(cDAIAddress);
        checkInitialBalances();
        checkInitialWhitelist();
        checkInitialAllowance();
        // Pass the compound proposal
        uint256 proposalID = createProposal();
        voteOnProposal(proposalID);
        executeProposal(proposalID);
    }

    /// @notice Make sure the initial balances of the contracts are correct before
    // passing the proposal
    function checkInitialBalances() internal {
        assertEq(pot.pie(cDAIDelegateAddress), 0);
        assertEq(pot.pie(cDAIAddress), 0);
        assertEq(vat.dai(cDAIDelegateAddress), 0);

        // This should not be 0 because leftovers but it should be less than `chi`
        assertEq((vat.dai(cDAIAddress) <= pot.chi()), true);
    }

    /// @notice The initial allowance should be zero
    function checkInitialAllowance() internal {
        assertEq(cDAI.allowance(cDAIAddress, DAIJoinAddress), 0);
    }

    /// @notice cDAI Addresses should be whitelisted on both Pot and Join
    function checkInitialWhitelist() internal {
        assertEq(vat.can(cDAIAddress, DAIPotAddress), 1);
        assertEq(vat.can(cDAIAddress, DAIJoinAddress), 1);
    }

    /// @notice Create the proposal exactly as it was submitted by the community
    /// @dev This code can be reused to pass any proposal
    function createProposal() internal returns (uint256) {
        // Targets
        address[] memory targets = new address[](2);
        targets[0] = address(cDAIAddress);
        targets[1] = address(cDAIAddress);

        // Values
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        // Signatures
        string[] memory signatures = new string[](2);
        signatures[0] = "_setImplementation(address,bool,bytes)";
        signatures[1] = "_setInterestRateModel(address)";

        // Calldatas
        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encode(
            cDAIDelegateAddress,
            true,
            abi.encode(DAIJoinAddress, DAIPotAddress)
        );
        calldatas[1] = abi.encode(DAIIRModelAddress);

        // Description
        string memory description = "Proposal to renable DSR";

        // We submit the proposal passing as large COMP holder
        vm.prank(PolychainCapital);

        uint256 proposalID = governorBravo.propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );

        return proposalID;
    }

    /// @notice Pretend to be large COMP holders and vote yes on the proposal
    /// @dev If you change the block number in which the test is ran, make
    /// sure these addresses are still large COMP holders
    function voteOnProposal(uint256 proposalID) internal {
        // We increment the time based on the voting delay
        increaseBlockNumber(governorBravo.votingDelay() + 1);

        // We vote on the proposal passing as large COMP holders
        vm.prank(PolychainCapital);
        governorBravo.castVote(proposalID, 1);

        vm.prank(BrainCapitalVentures);
        governorBravo.castVote(proposalID, 1);

        vm.prank(a16z);
        governorBravo.castVote(proposalID, 1);
    }

    /// @notice Execute the proposal
    /// @dev Because of how timelock works, the block time & block numbers are
    /// increased, check Helpers.sol for more details
    function executeProposal(uint256 proposalID) internal {
        // We increment the time based on the voting period
        increaseBlockNumber(governorBravo.votingPeriod() + 1);

        // Queue the proposal
        vm.prank(PolychainCapital);
        governorBravo.queue(proposalID);

        // Wait the timelock delay
        increaseBlockTimestamp(172800 + 1); // 172800 is the Timelock delay 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925

        // Execute the proposal
        vm.prank(PolychainCapital);
        governorBravo.execute(proposalID);
    }

    /// @notice Make sure cDAI implementation is the cDAIDelegateAddress
    function testcDAIImplementation() public {
        assertEq(cDAI.implementation(), cDAIDelegateAddress);
    }

    /// @notice Make sure that the cDAI interest rate model is the DAIIRModelAddress
    function testInterestRate() public {
        assertEq(address(cDAI.interestRateModel()), DAIIRModelAddress);
    }

    /// @notice DAI balances should be 0 as the real balance is tracked through pot
    function testBalances() public {
        assertEq(dai.balanceOf(cDAIAddress), 0);
        assertEq(dai.balanceOf(cDAIDelegateAddress), 0);
        assertEq(pot.pie(cDAIDelegateAddress), 0);
        assertEq(
            pot.pie(cDAIAddress),
            (initialDAIBalance * 10 ** 27) / pot.chi()
        );
    }

    /// @notice Make sure that the allowance of cDAI is set to the maximum value
    function testFinalAllowance() internal {
        assertEq(
            cDAI.allowance(cDAIAddress, DAIJoinAddress),
            type(uint256).max
        );
    }

    /// @notice cDAI Addresses should be whitelisted on both Pot and Join
    function testFinalWhitelist() public {
        assertEq(vat.can(cDAIAddress, DAIPotAddress), 1);
        assertEq(vat.can(cDAIAddress, DAIJoinAddress), 1);
    }

    /// @notice Verify that the DSR is increased correctly
    /// @dev DSR is calculated for 10% yield with a base of 10^27, exponent is 1 year time
    /// and the value required to make that give 10% is 1000000003022265980097387650
    function testDSRIncrease() public {
        uint256 initialDsr = pot.dsr();
        assertEq(pot.wards(DSPauseAddress), 1);

        vm.prank(DSPauseAddress);
        pot.file(bytes32("dsr"), uint256(1000000003022265980097387650)); // We set the DSR to 10%

        uint256 finalDsr = pot.dsr();
        assertEq(initialDsr != finalDsr, true);
        assertEq(finalDsr, 1000000003022265980097387650);
    }

    /// @notice Verify that the interest rate is being accumulated correctly
    function testAccumulatedInterestOverTime() public {
        pot.drip();
        uint256 initialPotBalInVat = vat.dai(DAIPotAddress);

        increaseBlockTimestamp(365 * 24 * 60 * 60);
        pot.drip();

        uint256 finalPotBalInVat = vat.dai(DAIPotAddress);

        assertApproxEqRel(
            (initialPotBalInVat * 101) / 100,
            finalPotBalInVat,
            0.00001e18
        );
    }

    /// @notice Make sure that drip would revert in case that the DSR is soo large
    /// it causes an overflow
    function testExpectRevertOnDSRTooLarge() public {
        vm.prank(DSPauseAddress);
        pot.file(bytes32("dsr"), uint256(2000000000000000000000000000)); // too much

        assertEq(pot.dsr(), 2000000000000000000000000000);

        increaseBlockTimestamp(365 * 24 * 60 * 60);

        vm.expectRevert();
        pot.drip();
    }

    /// @notice If the DSR is 0, the drip should not change the vat balance
    function testZeroDSR() public {
        vm.prank(DSPauseAddress);
        pot.file(bytes32("dsr"), uint256(1000000000000000000000000000));
        assertEq(pot.dsr(), 1000000000000000000000000000);

        pot.drip();
        uint256 initialPotBalInVat = vat.dai(DAIPotAddress);

        increaseBlockTimestamp(365 * 24 * 60 * 60);

        pot.drip();
        uint256 finalPotBalInVat = vat.dai(DAIPotAddress);

        assertEq(initialPotBalInVat, finalPotBalInVat);
    }

    /// @notice The actual blockPerYear is not exactly set to 12 seconds
    /// per block
    /// @dev Just wanted to verify this assumption
    function testNonCurrentBlockRate() public {
        assertFalse(
            InterestRateModel(cDAI.interestRateModel()).blocksPerYear() ==
                (365 * 24 * 60 * 60) / 12
        );
    }

    /// @notice Borrows can still be made on cDAI after the proposal is executed
    /// @dev Make sure the address has enough balance if the test block number
    /// is changed
    function testBorrow() public {
        // Inspired on this TX: https://etherscan.io/tx/0x8c000144e6ffe856d6049d8c07a0ec8630b7acaeb1360b62d6071ad5e8266076#eventlog
        address alice = address(0x173Ac361f92F8Ba8bD42EFeB46c1EdFf36111A07);
        uint256 borrowAmount = 4200000000000000000000;

        vm.startPrank(alice);
        assertEq(dai.balanceOf(alice), 0);
        cDAI.borrow(borrowAmount);
        assertEq(dai.balanceOf(alice), borrowAmount);
        cDAI.repayBorrow(borrowAmount);
        vm.stopPrank();
    }

    /// @notice Mints can still be made on cDAI after the proposal is executed
    /// @dev Make sure the address has enough balance if the test block number changes
    function testMint() public {
        address bob = address(0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8);
        uint256 mintAmount = 100e18;

        vm.startPrank(bob);
        uint256 initialBalance = dai.balanceOf(bob);

        dai.approve(address(cDAI), type(uint256).max);

        cDAI.mint(mintAmount);

        assertEq(dai.balanceOf(bob), (initialBalance - mintAmount));
        assertEq(cDAI.balanceOf(bob) > 0, true);

        cDAI.redeem(cDAI.balanceOf(bob));
        assertApproxEqRel(dai.balanceOf(bob), initialBalance, 0.00000001e18);
        vm.stopPrank();
    }

    /// @notice Helper function that returns the Earnings of a user with DSR
    /// set to 0.
    function getCompoundUserWODSREarnings() internal returns (uint256) {
        vm.prank(DSPauseAddress);
        pot.file(bytes32("dsr"), uint256(1000000000000000000000000000));
        pot.drip();

        address bob = address(0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8);
        uint256 mintAmount = 100e18;

        vm.startPrank(bob);
        uint256 initialBalance = dai.balanceOf(bob);

        dai.approve(address(cDAI), type(uint256).max);

        cDAI.mint(mintAmount);

        assertEq(dai.balanceOf(bob), (initialBalance - mintAmount));
        assertEq(cDAI.balanceOf(bob) > 0, true);

        increaseBlockTimestamp(365 * 24 * 60 * 60);
        pot.drip();

        cDAI.redeem(cDAI.balanceOf(bob));
        vm.stopPrank();

        return ((dai.balanceOf(bob) - initialBalance) * 10 ** 18) / mintAmount;
    }

    /// @notice The returns for a Compound User should be larger when the DSR is enabled
    /// than if it was not enabled
    function testCompoundUserDSREarnings() public {
        address bob = address(0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8);
        uint256 mintAmount = 100e18;

        vm.startPrank(bob);
        uint256 initialBalance = dai.balanceOf(bob);

        dai.approve(address(cDAI), type(uint256).max);

        cDAI.mint(mintAmount);

        assertEq(dai.balanceOf(bob), (initialBalance - mintAmount));
        assertEq(cDAI.balanceOf(bob) > 0, true);

        increaseBlockTimestamp(365 * 24 * 60 * 60);
        pot.drip();

        cDAI.redeem(cDAI.balanceOf(bob));

        uint256 yearlyDSREarnings = (((dai.balanceOf(bob) - initialBalance) *
            10 ** 18) / mintAmount);

        vm.stopPrank();

        uint yearlyWODSREarnings = getCompoundUserWODSREarnings();

        assertEq(yearlyDSREarnings > yearlyWODSREarnings, true);
    }
}
