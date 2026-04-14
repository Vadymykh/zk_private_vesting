import { network } from "hardhat";
import { verifyContract } from "./helpers/verifyHelpers.js";
import {
  deployVesting,
  tokenAddress
} from "./helpers/testing/onChainVestingTesting.js";

const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

async function main() {
  const { viem } = await network.connect();

  console.log("Deploying CreationVerifier contract");
  const CreationVerifier = await viem.deployContract("VestingMerkleTreeVerifier");
  console.log(`CreationVerifier deployed to: ${CreationVerifier.address.toLowerCase()}`);

  console.log("Deploying VestingWithdrawVerifier contract");
  const VestingWithdrawVerifier = await viem.deployContract("VestingWithdrawVerifier");
  console.log(`VestingWithdrawVerifier deployed to: ${VestingWithdrawVerifier.address.toLowerCase()}`);

  console.log("Deploying VestingFactory contract");
  const VestingFactory = await viem.deployContract(
    "PrivateVestingFactory",
    [CreationVerifier.address, VestingWithdrawVerifier.address]
  );
  console.log(`VestingFactory deployed to: ${VestingFactory.address.toLowerCase()}`);

  console.log("Deploying PrivateVesting contract");
  const { vestingAddress, merkleTreeRoot } = await deployVesting(viem, VestingFactory);
  console.log(`PrivateVesting deployed to: ${vestingAddress.toLowerCase()}`);

  /******************************************** VERIFICATION ********************************************/
  /******************************************** VERIFICATION ********************************************/

  console.log("We verify now, Please wait!");
  await delay(20000);

  await verifyContract("CreationVerifier", CreationVerifier.address, []);
  await verifyContract("VestingWithdrawVerifier", VestingWithdrawVerifier.address, []);
  await verifyContract("VestingFactory", VestingFactory.address, [CreationVerifier.address, VestingWithdrawVerifier.address]);
  await verifyContract("PrivateVesting", vestingAddress, [
    tokenAddress,
    VestingWithdrawVerifier.address,
    merkleTreeRoot
  ]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
