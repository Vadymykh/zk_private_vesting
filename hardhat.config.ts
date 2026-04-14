import "dotenv/config";
import { defineConfig, configVariable } from "hardhat/config";
import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import hardhatNetworkHelpers from "@nomicfoundation/hardhat-network-helpers";
import { sizeContracts } from "./tasks/size-contracts.js";

const accounts = [configVariable("PRIVATE_KEY")];

export default defineConfig({
  plugins: [hardhatToolboxViemPlugin, hardhatNetworkHelpers],
  tasks: [sizeContracts],
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
    bsc: { type: "http", url: configVariable("BSC_MAINNET_URL"), chainId: 56, accounts },
  },
  verify: {
    etherscan: {
      apiKey: configVariable("ETHERSCAN_API_KEY"),
    },
  },
});
