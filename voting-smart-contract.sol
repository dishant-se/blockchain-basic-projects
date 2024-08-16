// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Vote {

    //first entity
    struct Voter {
        string name;
        uint age;
        uint voterId;
        Gender gender;
        uint voteCandidateId; //candidate id to whom voter has voted
        address voterAddress;
    }

    //second entity
    struct Candidate {
        string name;
        string party;
        uint age;
        Gender gender;
        uint candidateId;
        address candidateAddress; //candidate EOA
        uint votes; //vote count
    }

    //third entity
    address public electionCommission;

    address public winner;
    uint nextVoterId = 1;
    uint nextCandidateId = 1;
    uint startTime;
    uint endTime;
    bool stopVoting;


    mapping(uint => Voter) voterDetails;
    mapping(uint => Candidate) candidateDetails;


    enum VotingStatus {NotStarted, InProgress, Ended}
    enum Gender {NotSpecified, Male, Female, Other}


    constructor() {
        electionCommission=msg.sender; //msg.sender is a global variable
        //msg.sender stores the EOA address of entity calling the function
    }


    modifier isVotingPeriod() {
        require(block.timestamp >= startTime && block.timestamp <= endTime && stopVoting == false, "Voting time over.");
        _;
    }


    modifier onlyCommissioner() {
        require(msg.sender == electionCommission, "Not Authorized.");
        _;
    }

    modifier ageChecker(uint _age) {
        require(_age > 18, "Age must be greater than 18.");
        _;
    }


    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint _age,
        Gender _gender
    ) external ageChecker(_age) {
        require(isCandidateNotRegistered(msg.sender), "You are already registered");
        require(nextCandidateId < 3, "Max Candidate Limit");
        require(msg.sender != electionCommission, "You are from election commision!");
        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            age: _age,
            gender: _gender,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
       });
       nextCandidateId++;
    }


    function isCandidateNotRegistered(address _person) internal view returns (bool) {
        for (uint i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _person) {
                return false;
            }
        }
        return true;
    }


    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](nextCandidateId - 1);
        for (uint i = 0; i < nextCandidateId - 1; i++) {
            candidateList[i] = candidateDetails[i + 1];
        }
        return candidateList;
    }


    function isVoterNotRegistered(address _person) internal view returns (bool) {
        for (uint i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voterAddress == _person) {
                return false;
            }
        }
        return true;
    }


    function registerVoter(
        string calldata _name,
        uint _age,
        Gender _gender
    ) external ageChecker(_age) {
        require(isVoterNotRegistered(msg.sender), "Voter already registered.");
        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            gender: _gender,
            voterId: nextVoterId,
            voteCandidateId: 0,
            voterAddress: msg.sender
        });
        nextVoterId++;
    }


    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](nextVoterId - 1);
        for (uint i = 0; i < nextVoterId - 1; i++) {
            voterList[i] = voterDetails[i + 1];
        }
        return voterList;
    }


    function castVote(uint _voterId, uint _candidateId) external isVotingPeriod() {
        require(voterDetails[_voterId].voteCandidateId == 0, "Already Voted");
        require(voterDetails[_voterId].voterAddress == msg.sender, "Unauthorized Access");
        require(_candidateId >= 1 && _candidateId < 3, "No such candidate");
        voterDetails[_voterId].voteCandidateId = _candidateId;
        candidateDetails[_candidateId].votes += 1;
    }


    function setVotingPeriod(uint _startTime, uint _endTime) external onlyCommissioner() {
        require(_startTime < _endTime, "Starttime must be lower than endtime");
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
    }


    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted;
        } else if (block.timestamp > startTime && block.timestamp < endTime && stopVoting == false) {
            return VotingStatus.InProgress;
        } else {
            return VotingStatus.Ended;
        }
    }


    function announceVotingResult() external onlyCommissioner() returns(address) {
        uint maxVotes = 0;
        for (uint i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maxVotes) {
                winner = candidateDetails[i].candidateAddress;
                maxVotes = candidateDetails[i].votes;
            }
        }
        return winner;
    }


    function emergencyStopVoting() public onlyCommissioner() {
       stopVoting = true;
    }

    /* ToDo - 
    1. Create function that will use ID proof while registration of candidate and votes. Now we are able to register 
        candidate & voter using same address with different name, age, etc. 
    2. Create a function resumeVoting() to switch stopVoting flag from true to false which only EC can call.
    */
}