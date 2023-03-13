// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGovernorBravo {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event ProposalCanceled(uint256 id);
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event ProposalExecuted(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalThresholdSet(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event WhitelistAccountExpirationSet(address account, uint256 expiration);
    event WhitelistGuardianSet(address oldGuardian, address newGuardian);

    struct Receipt {
        bool a;
        uint8 b;
        uint96 c;
    }

    function BALLOT_TYPEHASH() external view returns (bytes32);

    function DOMAIN_TYPEHASH() external view returns (bytes32);

    function MAX_PROPOSAL_THRESHOLD() external view returns (uint256);

    function MAX_VOTING_DELAY() external view returns (uint256);

    function MAX_VOTING_PERIOD() external view returns (uint256);

    function MIN_PROPOSAL_THRESHOLD() external view returns (uint256);

    function MIN_VOTING_DELAY() external view returns (uint256);

    function MIN_VOTING_PERIOD() external view returns (uint256);

    function _acceptAdmin() external;

    function _initiate(address governorAlpha) external;

    function _setPendingAdmin(address newPendingAdmin) external;

    function _setProposalThreshold(uint256 newProposalThreshold) external;

    function _setVotingDelay(uint256 newVotingDelay) external;

    function _setVotingPeriod(uint256 newVotingPeriod) external;

    function _setWhitelistAccountExpiration(address account, uint256 expiration)
        external;

    function _setWhitelistGuardian(address account) external;

    function admin() external view returns (address);

    function cancel(uint256 proposalId) external;

    function castVote(uint256 proposalId, uint8 support) external;

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) external;

    function comp() external view returns (address);

    function execute(uint256 proposalId) external;

    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (Receipt memory);

    function implementation() external view returns (address);

    function initialProposalId() external view returns (uint256);

    function initialize(
        address timelock_,
        address comp_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_
    ) external;

    function isWhitelisted(address account) external view returns (bool);

    function latestProposalIds(address) external view returns (uint256);

    function name() external view returns (string memory);

    function pendingAdmin() external view returns (address);

    function proposalCount() external view returns (uint256);

    function proposalMaxOperations() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function proposals(uint256)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        );

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function queue(uint256 proposalId) external;

    function quorumVotes() external view returns (uint256);

    function state(uint256 proposalId) external view returns (uint8);

    function timelock() external view returns (address);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);

    function whitelistAccountExpirations(address)
        external
        view
        returns (uint256);

    function whitelistGuardian() external view returns (address);
}
