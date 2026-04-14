import { Account, parseEventLogs } from "viem";
import { getTimestamp, TypedContract, ViemProvider } from "../viem.js";
import { CircomCircuit } from "../zk/circomCircuit.js";
import { LeafInput, MerkleTree } from "../zk/merkeTreePoseidon.js";
import { expect } from "chai";

export const TREE_DEPTH = 4;

export type RecipientData = {
  amount: bigint,
  cliffDuration: number,
  index: number,
};

export type Context = {
  viem: ViemProvider,
  receiversInput: LeafInput[],
  receiversData: { [recipient: string]: RecipientData },
  withdrawCircuit: CircomCircuit,
  creationCircuit: CircomCircuit,
  Vesting: TypedContract<"PrivateVesting">,
  Token: TypedContract<"TestERC20">,
  tree: MerkleTree,
}

/**
 * Generate ZK proof for vesting creation
 */
export async function getCreateVestingProof(
  context: {
    receiversInput: LeafInput[],
    creationCircuit: CircomCircuit,
  },
) {
  const recipients = new Array<string>(1 << TREE_DEPTH);
  const amounts = new Array<string>(1 << TREE_DEPTH);
  const cliffDurations = new Array<string>(1 << TREE_DEPTH);

  for (let i = 0; i < 1 << TREE_DEPTH; i++) {
    const [recipient, amount, cliffDuration] = context.receiversInput[i] || [0n, 0n, 0n];
    recipients[i] = recipient ? recipient.toString() : "0";
    amounts[i] = amount ? amount.toString() : "0";
    cliffDurations[i] = cliffDuration ? cliffDuration.toString() : "0";
  }

  return await context.creationCircuit.generateCallData<2>({
    recipients,
    amounts,
    cliffDurations,
  });
}

type WithdrawProofOverwriteValues = {
  timePassed?: string,
  overwriteRoot?: string,
  overwriteRecipient?: string,
  overwriteWithdrawnAmount?: string,
};

/**
 * Generate ZK proof for vesting withdrawal
 */
export async function getWithdrawProof(
  context: Context,
  receiver: `0x${string}`,
  amount: number | bigint | string,
  overwrite?: WithdrawProofOverwriteValues,
) {
  const {
    timePassed,
  } = overwrite || {};

  const {
    viem,
    receiversData,
    withdrawCircuit,
    Vesting,
    tree,
  } = context;

  const receiverData = receiversData[receiver];
  if (!receiver) {
    throw new Error("No receiver found");
  }
  const path = tree.getPathForElement(receiverData.index);
  const _withdrawnAmount = (await Vesting.read.withdrawn([receiver]));
  const blockTimestamp = await getTimestamp(viem);
  const vestingStart = await Vesting.read.vestingStart();

  return await withdrawCircuit.generateCallData<5>({
    recipient: receiver,
    amount: amount.toString(),
    withdrawnAmount: _withdrawnAmount.toString(),
    totalAmount: receiverData.amount.toString(),
    root: tree.getRoot().toString(),
    cliffDuration: receiverData.cliffDuration.toString(),
    timePassed: timePassed || (blockTimestamp - vestingStart).toString(),

    pathElements: path.pathElements.map(x => x.toString()),
    pathIndices: path.pathIndices,
  });
}

/**
 * @param context Testing context
 * @param user User account
 * @param amount Amount to withdraw
 * @param receiver Tokens receiver
 * @param overwrite Tokens receiver
 */
export async function withdraw(
  context: Context,
  user: Account,
  amount: bigint,
  receiver = user.address,
  overwrite?: WithdrawProofOverwriteValues,
) {
  const { viem, Vesting, Token } = context;
  const {
    overwriteRoot,
    overwriteRecipient,
    overwriteWithdrawnAmount,
  } = overwrite || {};

  const proof = await getWithdrawProof(
    context,
    user.address,
    amount,
    overwrite,
  );

  if (overwriteRoot) {
    proof[3][4] = BigInt(overwriteRoot);
  }
  if (overwriteRecipient) {
    proof[3][0] = BigInt(overwriteRecipient);
  }
  if (overwriteWithdrawnAmount) {
    proof[3][2] = BigInt(overwriteWithdrawnAmount);
  }

  const receiverBalance1 = await Token.read.balanceOf([receiver]);
  const vestingBalance1 = await Token.read.balanceOf([Vesting.address]);

  const txHash = await Vesting.write.withdraw([
    ...proof,
    receiver,
  ], { account: user });

  const receiverBalance2 = await Token.read.balanceOf([receiver]);
  const vestingBalance2 = await Token.read.balanceOf([Vesting.address]);

  expect(receiverBalance2 - receiverBalance1).eq(amount);
  expect(vestingBalance1 - vestingBalance2).eq(amount);

  const receipt = await (await viem.getPublicClient()).waitForTransactionReceipt({
    hash: txHash,
  });
  const withdrawalLog = parseEventLogs({
    abi: Vesting.abi,
    logs: receipt.logs,
  })[0];
  expect(withdrawalLog.args.user.toLowerCase()).eq(user.address);
  expect(withdrawalLog.args.receiver.toLowerCase()).eq(receiver);
  expect(withdrawalLog.args.amount).eq(amount);
}