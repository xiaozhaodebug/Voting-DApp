const hre = require("hardhat");

async function main() {
  // 1. 获取测试账户
  // owner: 合约部署者, creator: 发起众筹的人, donor1: 捐款人
  const [owner, creator, donor1] = await hre.ethers.getSigners();

  // 2. 部署合约
  const CrowdFunding = await hre.ethers.getContractFactory("CrowdFunding");
  const crowdFunding = await CrowdFunding.deploy();
  await crowdFunding.waitForDeployment();
  const contractAddress = await crowdFunding.getAddress();
  console.log("众筹合约已部署到:", contractAddress);

  // 3. 发起一个众筹：目标 1 ETH，持续时间 30 天
  // parseEther("1") 会把 1 变成 1000000000000000000 (wei)
  const targetAmount = hre.ethers.parseEther("1"); 
  console.log("\n--- 1. 发起众筹 ---");
  const tx = await crowdFunding.createCampaign(creator.address, "Save the Pandas", targetAmount, 30);
  await tx.wait();
  console.log("项目 'Save the Pandas' 已创建");

  // 4. 捐款 (模拟失败场景：只捐了 0.5 ETH)
  console.log("\n--- 2. 用户捐款 ---");
  const donationAmount = hre.ethers.parseEther("0.5");
  // 注意：调用合约转账时，要在 overrides 对象里传 value
  await crowdFunding.connect(donor1).donateToCampaign(0, { value: donationAmount });
  console.log("Donor1 捐赠了 0.5 ETH");

  // 查看当前筹款金额
  const campaign = await crowdFunding.campaigns(0);
  console.log(`当前已筹集: ${hre.ethers.formatEther(campaign.amountCollected)} ETH`);

  // 5. 模拟时光飞逝 (Hardhat 特有功能)
  // 我们让区块链时间强制快进 31 天，让众筹过期
  console.log("\n--- 3. 31天后... ---");
  await hre.network.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
  await hre.network.provider.send("evm_mine"); // 挖出一个新块确认时间

  // 6. 申请退款
  console.log("\n--- 4. 执行退款 ---");
  // 记录退款前余额
  const balanceBefore = await hre.ethers.provider.getBalance(donor1.address);
  
  // 执行退款
  await crowdFunding.connect(donor1).refund(0);
  
  // 记录退款后余额
  const balanceAfter = await hre.ethers.provider.getBalance(donor1.address);
  console.log("退款成功！");
  console.log(`余额变化: +${hre.ethers.formatEther(balanceAfter - balanceBefore)} ETH (大概值，扣除了Gas费)`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
