import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SolivreKernelModule = buildModule("SolivreKernelModule", (m) => {
  const kernel = m.contract("SolivreKernel");
  return { kernel };
});

export default SolivreKernelModule;
