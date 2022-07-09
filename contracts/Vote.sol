// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Vote {
    struct Voter {
        uint256 bollot;
        bool voted;
        int256 voteto;
    }

    struct Proposal {
        string name;
        string pic;
        string party;
        string politics;
        uint256 voteCnt;
        bool win;
    }

    address public chairperson;
    mapping(string => address) public users;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    bool public lock;
    uint256 public voterCnt;
    uint256 public proposalCnt;

    constructor(string[] memory proposalNames, string[] memory proposalPics, string[] memory proposalParties, string[] memory proposalPolitics) {
        chairperson = msg.sender;
        lock = false;
        voterCnt = 0;
        proposalCnt = proposalNames.length;
        for (uint256 i = 0; i < proposalCnt; i++) {
            proposals.push(
                Proposal({name: proposalNames[i], pic: proposalPics[i], party: proposalParties[i], politics: proposalPolitics[i], voteCnt: 0, win: false})
            );
        }
    }

    function setLock(bool _lock) external {
        require(msg.sender == chairperson, "Only chairperson can set lock.");
        lock = _lock;
        if (lock) {
            uint256 maxCount = 0;
            for (uint256 p = 0; p < proposals.length; p++) {
                if (proposals[p].voteCnt > maxCount) {
                    maxCount = proposals[p].voteCnt;
                }
            }

            for (uint256 p = 0; p < proposals.length; p++) {
                if (proposals[p].voteCnt == maxCount) {
                    proposals[p].win = true;
                }
            }
        } else {
            for (uint256 p = 0; p < proposals.length; p++) {
                proposals[p].win = false;
            }
        }
    }

    function newUser(string memory _ID) external view returns (bool) {
        return users[_ID] == address(0);
    }

    function checkAccount(string memory _ID, address _acc) external view returns (uint256) {
        if (users[_ID] == address(0)) return 2;
        if (voters[_acc].bollot == 0 && voters[_acc].voted == false) return 3;
        if (users[_ID] != _acc) return 4;
        return 1;
    }

    function register(string memory _ID, address _acc) external {
        require(users[_ID] == address(0), "ID already exists.");
        require(
            voters[_acc].bollot == 0 || voters[_acc].voted == false,
            "Account already registered."
        );
        users[_ID] = _acc;
        voters[_acc].bollot = 1;
        voters[_acc].voteto = -1;
        voterCnt++;
    }

    function vote(uint256 proposal) external {
        require(lock == false, "Vote is locked.");
        Voter storage sender = voters[msg.sender];
        require(sender.voted == false, "Already voted.");
        require(sender.bollot != 0, "Have no bollot to vote.");

        sender.voted = true;
        sender.voteto = int256(proposal);
        proposals[proposal].voteCnt += sender.bollot;
    }
}
