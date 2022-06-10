// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Vote {
    struct Voter {
        uint256 weight;
        bool voted;
        uint256 vote;
        bool getballot;
        address delegate;
    }

    struct Proposal {
        string name;
        uint256 voteCount;
    }

    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    address[] public delegates;
    bool public lock;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        lock = false;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function setLock(bool _lock) external {
        require(msg.sender == chairperson, "Only chairperson can set lock.");
        lock = _lock;
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );

        require(!voters[voter].getballot, "The voter already got ballot.");
        voters[voter].getballot = true;

        address to = voter;
        while (voters[to].delegate != address(0)) to = voters[to].delegate;

        Voter storage delegated = voters[to];
        if (delegated.voted) {
            require(lock == false, "Vote is locked.");
            proposals[delegated.vote].voteCount += 1;
        } else delegated.weight += 1;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted or delegated.");
        require(to != msg.sender, "Self-delegation is disallowed.");


        while (voters[to].delegate != address(0)) {
            delegates.push(to);
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        while(delegates.length > 0) {
            address from = delegates[delegates.length - 1];
            delegates.pop();
            voters[from].delegate = to;
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegated = voters[to];
        if (delegated.voted) {
            require(lock == false, "Vote is locked.");
            proposals[delegated.vote].voteCount += sender.weight;
        } else delegated.weight += sender.weight;
    }

    function vote(uint256 proposal) external {
        require(lock == false, "Vote is locked.");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted or delegated.");
        require(sender.weight != 0, "Has no right to vote.");

        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        require(lock == true, "Vote is not locked.");
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view returns (string memory winnerName_) {
        require(lock == true, "Vote is not locked.");
        winnerName_ = proposals[winningProposal()].name;
    }
}
