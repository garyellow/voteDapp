// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Vote {
    struct Voter {
        uint bollot;
        bool voted;
        int voteto;
        bool isValid;
    }

    struct Proposal {
        string name;
        uint voteCount;
        bool win;
    }

    address public chairperson;
    mapping(string => address) public users;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    bool public lock;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        lock = false;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0, win: false}));
        }
    }

    function setLock(bool _lock) external {
        require(msg.sender == chairperson, "Only chairperson can set lock.");
        lock = _lock;
    }

    function register(string memory _ID) external returns (address _user) {
        require(users[_ID] == address(0), "You have already registered.");
        require(voters[msg.sender].isValid == false, "This account has been used.");
        users[_ID] = _user = msg.sender;
        voters[msg.sender].isValid = true;
        voters[msg.sender].voteto = -1;
    }

    function getbollot(string memory _ID) external {
        require(lock == false, "The vote is locked.");
        require(users[_ID] != address(0), "You should register first.");
        require(users[_ID] == msg.sender, "Invalid user.");
        require(voters[msg.sender].voted == false, "You have already voted.");
        require(voters[msg.sender].bollot == 0, "You have already got bollot.");

        voters[msg.sender].bollot = 1;
    }

    // function giveRightToVote(address voter) external {
    //     require(
    //         msg.sender == chairperson,
    //         "Only chairperson can give right to vote."
    //     );

    //     require(!voters[voter].getballot, "The voter already got ballot.");
    //     voters[voter].getballot = true;

    //     address to = voter;
    //     while (voters[to].delegate != address(0)) to = voters[to].delegate;

    //     Voter storage delegated = voters[to];
    //     if (delegated.voted) {
    //         require(lock == false, "Vote is locked.");
    //         proposals[delegated.vote].voteCount += 1;
    //     } else delegated.weight += 1;
    // }

    // function delegate(address to) external {
    //     Voter storage sender = voters[msg.sender];
    //     require(!sender.voted, "You already voted or delegated.");
    //     require(to != msg.sender, "Self-delegation is disallowed.");


    //     while (voters[to].delegate != address(0)) {
    //         delegates.push(to);
    //         to = voters[to].delegate;
    //         require(to != msg.sender, "Found loop in delegation.");
    //     }

    //     while(delegates.length > 0) {
    //         address from = delegates[delegates.length - 1];
    //         delegates.pop();
    //         voters[from].delegate = to;
    //     }

    //     sender.voted = true;
    //     sender.delegate = to;
    //     Voter storage delegated = voters[to];
    //     if (delegated.voted) {
    //         require(lock == false, "Vote is locked.");
    //         proposals[delegated.vote].voteCount += sender.weight;
    //     } else delegated.weight += sender.weight;
    // }

    function vote(uint proposal) external {
        require(lock == false, "Vote is locked.");
        Voter storage sender = voters[msg.sender];
        require(sender.voted == false, "Already voted.");
        require(sender.bollot != 0, "Have no bollot to vote.");

        sender.voted = true;
        sender.voteto = int(proposal);
        proposals[proposal].voteCount += sender.bollot;
    }

    function result() public returns (uint maxCount) {
        require(lock == true, "Vote is not locked.");
        maxCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > maxCount) {
                maxCount = proposals[p].voteCount;
            }
        }

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount == maxCount) {
                proposals[p].win = true;
            }
        }
    }
}
