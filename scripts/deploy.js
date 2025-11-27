const hre = require("hardhat");

async function main() {
  const Orchestrator = await hre.ethers.getContractFactory("ProofOrchestrator");
  const orchestrator = await Orchestrator.deploy();

  await orchestrator.deployed();

  console.log("ProofOrchestrator deployed to:", orchestrator.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
