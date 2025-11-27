import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatToolboxViemPlugin],

  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    // -----------------------------
    // LOCAL DEV (Hardhat node)
    // -----------------------------
    localhost: {
      type: "http",
      chainType: "l1",
      url: "http://127.0.0.1:8545",
    },

    // Simulated networks that toolbox uses internally
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },

    // -----------------------------
    // COTI gcEVM
    // -----------------------------
    coti: {
      type: "http",
      chainType: "l1",
      url: "https://rpc.coti.io",
      chainId: 30371,
      accounts: configVariable("COTI_PRIVATE_KEY")
        ? [configVariable("COTI_PRIVATE_KEY")]
        : [],
    },

    // Optional: Sepolia testnet
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
  },
});
