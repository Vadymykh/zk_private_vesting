import { verifyContract as verifyHreContract } from "@nomicfoundation/hardhat-verify/verify";
import hre from "hardhat";

export async function verifyContract(
  name: string,
  address: string,
  constructorArgs: unknown[] | undefined
) {
  console.log(`Verifying ${name}`);
  try {
    await verifyHreContract(
      {
        address,
        constructorArgs,
        provider: "etherscan",
      },
      hre,
    );
  } catch (e) {
    console.log(e);
  }
}