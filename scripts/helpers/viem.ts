import { GetContractReturnType } from "viem";
import hre from "hardhat";
import { ArtifactMap } from "hardhat/types/artifacts";

export type ViemProvider = Awaited<
  ReturnType<typeof hre.network.connect>
>["viem"];

export type WalletClient = Awaited<
  ReturnType<ViemProvider["getWalletClients"]>
>[number];

export type TypedContract<
  ContractNameT extends keyof ArtifactMap
> = GetContractReturnType<
  ArtifactMap[ContractNameT]["abi"],
  WalletClient
>;

export async function getTimestamp(viem: ViemProvider) {
  return (await (await viem.getPublicClient()).getBlock()).timestamp;
}