// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // 候选人结构体
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // 存储候选人 ID -> 详细信息
    mapping(uint => Candidate) public candidates;
    // 存储 投票人地址 -> 是否已投票 (防止重复刷票)
    mapping(address => bool) public voters;
    
    // 候选人总数
    uint public candidatesCount;

    // 这是一个事件，投票成功后通知前端
    event VotedEvent(uint indexed _candidateId);

    // 构造函数：合约部署时自动执行，初始化两个候选人
    constructor() {
        addCandidate("Trump");
        addCandidate("Biden");
    }

    // 内部函数：添加候选人 logic
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // 核心功能：投票
    function vote(uint _candidateId) public {
        // 1. 检查：这个人是否投过票？
        require(!voters[msg.sender], "You have already voted.");

        // 2. 检查：投的候选人是否存在？
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID.");

        // 3. 记录：标记此地址已投票
        voters[msg.sender] = true;

        // 4. 计数：候选人票数 +1
        candidates[_candidateId].voteCount++;

        // 5. 触发事件
        emit VotedEvent(_candidateId);
    }
}
