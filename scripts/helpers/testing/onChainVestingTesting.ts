import { toBig } from "../bigNumberHelpers.js";
import { getCreateVestingProof } from "./vestingHelpers.js";
import { CircomCircuit } from "../zk/circomCircuit.js";
import { TypedContract, ViemProvider } from "../viem.js";
import { parseEventLogs } from "viem";
import { expect } from "chai";

export const creationCircuit = new CircomCircuit({ name: "vestingMerkleTree" });
export const withdrawCircuit = new CircomCircuit({ name: "vestingWithdraw" });
export const tokenAddress = "0x55d398326f99059ff775485246999027b3197955"; // USDT

export const receivers = [
  { recipient: "0xD022311DAcaa30f8396cA9d2C4662a2eF083A1Dd", amount: toBig(0.05), cliffDuration: 60 },
  { recipient: "0x63E2B5f07A28B7d8C527Fc958942851dd7719B35", amount: toBig(0.05), cliffDuration: 120 },
];
export const receiversInput = receivers
  .map(({ recipient, amount, cliffDuration }) => [
    BigInt(recipient),
    amount,
    BigInt(cliffDuration),
  ]);

export async function deployVesting(
  viem: ViemProvider,
  VestingFactory: TypedContract<"PrivateVestingFactory">,
) {
  const Token = await viem.getContractAt("TestERC20", tokenAddress);
  await Token.write.approve([VestingFactory.address, toBig(600)]);
  const createVestingProof = await getCreateVestingProof({
    receiversInput,
    creationCircuit,
  });

  const txHash = await VestingFactory.write.createPrivateVesting([
    Token.address,
    ...createVestingProof,
  ]);
  const receipt = await (await viem.getPublicClient()).waitForTransactionReceipt({
    hash: txHash,
  });
  const parsedLogs = parseEventLogs({
    abi: VestingFactory.abi,
    logs: receipt.logs,
  });
  const vestingCreatedLog = parsedLogs[0];
  expect(vestingCreatedLog.address).eq(VestingFactory.address);
  return { vestingAddress: vestingCreatedLog.args[0], merkleTreeRoot: createVestingProof[3][0] };
}