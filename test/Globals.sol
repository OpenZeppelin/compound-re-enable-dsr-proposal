// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./Helpers.sol";
import "../src/IGovernorBravo.sol";
import "../src/CTokenInterfaces.sol";
import "../src/IERC20.sol";
import "../src/MakerInterfaces.sol";
import "../src/DAIInterestRateModelV4.sol";

abstract contract Globals is Test, Helpers {

    // On-Chain Contract Addresses =========================

    // current cDai addresses
    address public cDaiAddress = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address public cDaiDelegateAddressCurrent = address(0x3363BAe2Fc44dA742Df13CD3ee94b6bB868ea376);
    address public cDaiIRModelAddressCurrent = address(0xFB564da37B41b2F6B6EDcc3e56FbF523bD9F2012);

    // cETH address
    address payable public cEthAddress = payable(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    CErc20Interface public cWBTC2 = CErc20Interface(0xccF4429DB6322D5C611ee964527D42E5d685DD6a);
    IERC20 public WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    // Governor Bravo
    address public governorBravoAddress = address(0xc0Da02939E1441F497fd74F78cE7Decb17B66529);
    // Comptroller
    address public comptrollerAddress = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    // proposed cDai addresses
    address public cDaiDelegateAddressDSR = address(0xbB8bE4772fAA655C255309afc3c5207aA7b896Fd);
    
    
    // address public cDaiIRModelAddressDSR = address(0xfeD941d39905B23D6FAf02C8301d40bD4834E27F);
    
    // Maker addresses
    address public DaiAddress = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public DaiJoinAddress = address(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    address public DaiPotAddress = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address public DaiJugAddress = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address public DaiVatAddress = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address public DSPauseAddress = address(0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB);

    // Contract Objects ===================================

    IGovernorBravo governorBravo = IGovernorBravo(governorBravoAddress);
    CErc20Interface cDai = CErc20Interface(cDaiAddress);
    CEther cEth = CEther(cEthAddress);
    ComptrollerInterface comptroller = ComptrollerInterface(comptrollerAddress);
    PotLike pot = PotLike(DaiPotAddress);
    VatLike vat = VatLike(DaiVatAddress);
    IERC20 dai = IERC20(DaiAddress);
    DAIInterestRateModelV4 irModel4; // create in setUp to interact with Maker on-chain
    uint blockNumberOfInterest = 16_820_728;
    

    // Voter Addresses =====================================
    address public PolychainCapital = address(0xea6C3Db2e7FCA00Ea9d7211a03e83f568Fc13BF7);
    address public BrainCapitalVentures = address(0x61258f12C459984F32b83C86A6Cc10aa339396dE);
    address public a16z = address(0x9AA835Bc7b8cE13B9B0C9764A52FbF71AC62cCF1);

    function proposeIntegratingDSR() internal returns (uint256) {
      // Targets
      address[] memory targets = new address[](2);
      targets[0] = address(cDaiAddress);
      targets[1] = address(cDaiAddress);

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
          cDaiDelegateAddressDSR,
          true,
          abi.encode(DaiJoinAddress, DaiPotAddress)
      );
      calldatas[1] = abi.encode(address(irModel4));

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

    function passProposal(uint256 proposalID) internal {
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


    function proposeRemovingDSR() internal returns (uint256) {


      // Targets
      address[] memory targets = new address[](2);
      targets[0] = address(cDaiAddress);
      targets[1] = address(cDaiAddress);

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
          cDaiDelegateAddressCurrent,
          true,
          abi.encode(DaiJoinAddress, DaiPotAddress) //unused
      );
      calldatas[1] = abi.encode(cDaiIRModelAddressCurrent);

      // Description
      string memory description = "Proposal to disable the DSR";

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

}
