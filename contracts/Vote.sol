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
    uint voterCnt;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        lock = false;
        voterCnt = 0;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0, win: false}));
        }
    }

    function setLock(bool _lock) external {
        require(msg.sender == chairperson, "Only chairperson can set lock.");
        lock = _lock;
    }

    function checkAccount(string memory _ID) external view returns (int) {
        if(users[_ID] == address(0)) return -1;
        if(voters[msg.sender].isValid == false) return -2;
        if(users[_ID] != msg.sender) return -3;
        return 1;
    }

    function getVoterCnt() external view returns (uint) {
        return voterCnt;
    }

    function register(string memory _ID) external returns(int){
        if(users[_ID] != address(0)) return -1;
        if(voters[msg.sender].isValid) return -2;
        users[_ID] = msg.sender;
        voters[msg.sender].isValid = true;
        voters[msg.sender].voteto = -1;
        voterCnt += 1;
        return 1;
    }

    function getbollot(string memory _ID) external {
        require(lock == false, "The vote is locked.");
        require(users[_ID] != address(0), "You should register first.");
        require(users[_ID] == msg.sender, "Invalid user.");
        require(voters[msg.sender].voted == false, "You have already voted.");
        require(voters[msg.sender].bollot == 0, "You have already got bollot.");

        voters[msg.sender].bollot = 1;
    }

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
