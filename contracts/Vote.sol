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
        uint voteCnt;
        bool win;
    }

    address public chairperson;
    mapping(string => address) public users;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    bool public lock;
    uint public voterCnt;
    uint public proposalCnt;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        lock = false;
        voterCnt = 0;
        proposalCnt = proposalNames.length;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCnt: 0, win: false}));
        }
    }

    function setLock(bool _lock) external {
        require(msg.sender == chairperson, "Only chairperson can set lock.");
        lock = _lock;
    }

    function checkAccount(string memory _ID, address _acc) external view returns (uint) {
        if(users[_ID] == address(0)) return 2;
        if(voters[_acc].isValid == false) return 3;
        if(users[_ID] != _acc) return 4;
        return 1;
    }

    function register(string memory _ID, address _acc) external {
        require(users[_ID] == address(0), "ID already exists.");
        require(voters[_acc].isValid == false, "Account already registered.");
        users[_ID] = _acc;
        voters[_acc].isValid = true;
        voters[_acc].voteto = -1;
        voterCnt++;
    }

    function getBollot(string memory _ID) external {
        require(lock == false, "The vote is locked.");
        require(users[_ID] != address(0), "You should register first.");
        require(users[_ID] == msg.sender, "Invalid user.");
        require(voters[msg.sender].voted == false, "You have already voted.");
        require(voters[msg.sender].bollot == 0, "You have already got bollot.");

        voters[msg.sender].bollot = 1;
    }

    function getProposalName(uint proposal) external view returns (string memory, uint, bool) {
        return (proposals[proposal].name, proposals[proposal].voteCnt, proposals[proposal].win);
    }

    function getCurBollot(uint proposal) external view returns (uint) {
        return proposals[proposal].voteCnt;
    }

    function vote(uint proposal) external {
        require(lock == false, "Vote is locked.");
        Voter storage sender = voters[msg.sender];
        require(sender.voted == false, "Already voted.");
        require(sender.bollot != 0, "Have no bollot to vote.");

        sender.voted = true;
        sender.voteto = int(proposal);
        proposals[proposal].voteCnt += sender.bollot;
    }

    function result() public returns (uint maxCount) {
        require(lock == true, "Vote is not locked.");
        maxCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCnt > maxCount) {
                maxCount = proposals[p].voteCnt;
            }
        }

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCnt == maxCount) {
                proposals[p].win = true;
            }
        }
    }
}
