import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ProofOrchestratorModule = buildModule(
  "ProofOrchestratorModule",
  (m) => {
    const proofOrchestrator = m.contract("ProofOrchestrator");

    return { proofOrchestrator };
  }
);

export default ProofOrchestratorModule;
