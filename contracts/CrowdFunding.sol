// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    // 定义众筹项目结构
    struct Campaign {
        address owner;          // 发起人
        string title;           // 项目标题
        uint goal;              // 目标金额 (单位: wei)
        uint deadline;          // 截止时间戳
        uint amountCollected;   // 已筹集金额
        bool claimed;           // 发起人是否已取款
    }

    // 存储所有众筹项目 (ID -> 项目)
    mapping(uint => Campaign) public campaigns;
    // 记录谁给哪个项目捐了多少钱 (项目ID -> (捐款人地址 -> 金额))
    mapping(uint => mapping(address => uint)) public donations;
    
    uint public numberOfCampaigns = 0;

    // 发起众筹项目
    // _goal: 目标金额, _durationInDays: 持续几天
    function createCampaign(address _owner, string memory _title, uint _goal, uint _durationInDays) public returns (uint) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.goal = _goal;
        // block.timestamp 是当前区块时间，加上天数秒数就是截止时间
        campaign.deadline = block.timestamp + (_durationInDays * 1 days);
        campaign.amountCollected = 0;
        campaign.claimed = false;

        numberOfCampaigns++;

        return numberOfCampaigns - 1; // 返回项目ID
    }

    // 捐款功能 (注意这个 payable 关键字！)
    function donateToCampaign(uint _id) public payable {
        uint amount = msg.value; // 获取用户发送的 ETH 数量
        Campaign storage campaign = campaigns[_id];

        // 检查：项目必须还没结束
        require(block.timestamp < campaign.deadline, "The campaign is over.");

        campaign.amountCollected += amount;
        donations[_id][msg.sender] += amount;
    }

    // 情况1：众筹成功，发起人取钱
    function withdraw(uint _id) public {
        Campaign storage campaign = campaigns[_id];
        
        // 只有发起人能调
        require(msg.sender == campaign.owner, "Only owner can withdraw.");
        // 必须达到目标金额
        require(campaign.amountCollected >= campaign.goal, "Goal not reached.");
        // 钱还没被取走
        require(!campaign.claimed, "Funds already claimed.");

        campaign.claimed = true;
        
        // 转账逻辑：把合约里的钱转给发起人
        (bool sent, ) = payable(campaign.owner).call{value: campaign.amountCollected}("");
        require(sent, "Failed to send Ether");
    }

    // 情况2：众筹失败，捐款人退款
    function refund(uint _id) public {
        Campaign storage campaign = campaigns[_id];
        
        // 必须等到时间截止
        require(block.timestamp > campaign.deadline, "Campaign not over yet.");
        // 必须是没达到目标
        require(campaign.amountCollected < campaign.goal, "Campaign succeeded, cannot refund.");

        uint donatedAmount = donations[_id][msg.sender];
        require(donatedAmount > 0, "You have no funds to refund.");

        // 清零该用户的捐款记录（防止重入攻击，这是安全关键点！）
        donations[_id][msg.sender] = 0;

        // 退款
        (bool sent, ) = payable(msg.sender).call{value: donatedAmount}("");
        require(sent, "Failed to refund Ether");
    }
}
