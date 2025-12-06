const hre = require("hardhat");

async function main() {
  console.log("正在部署 Voting 合约...");

  // 1. 获取合约工厂
  const Voting = await hre.ethers.getContractFactory("Voting");
  
  // 2. 发送部署交易
  const voting = await Voting.deploy();

  // 3. 等待合约在链上确认
  await voting.waitForDeployment();

  console.log("合约部署成功！");
  console.log("合约地址:", await voting.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
