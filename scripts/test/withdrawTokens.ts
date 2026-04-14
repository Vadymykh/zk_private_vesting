import { network } from "hardhat";
import { TREE_DEPTH } from "../helpers/testing/vestingHelpers.js";
import { MerkleTree } from "../helpers/zk/merkeTreePoseidon.js";
import { receivers, receiversInput, withdrawCircuit } from "../helpers/testing/onChainVestingTesting.js";
import { toBig } from "../helpers/bigNumberHelpers.js";

async function main() {
  const { viem } = await network.connect();
  const client = await viem.getPublicClient();
  const [wallet] = await viem.getWalletClients();
  const amount = toBig(0.00015);

  console.log("Connecting to contract");
  const Vesting = await viem.getContractAt(
    "PrivateVesting", "0xb37B453595A41D60206FAA530261a9542ec4110B"
  );

  console.log("Building merkle tree");
  const tree = await MerkleTree.create(receiversInput, TREE_DEPTH);

  console.log("Fetching on chain data");
  const withdrawnAmount = await Vesting.read.withdrawn([wallet.account.address]);
  const vestingStart = await Vesting.read.vestingStart();
  const receiverData = receivers
    .find(r => r.recipient.toLowerCase() === wallet.account.address)!;

  console.log("Generating withdrawal proof");
  const path = tree.getPathForElement(0);

  const proof = await withdrawCircuit.generateCallData<5>({
    recipient: wallet.account.address,
    amount: amount.toString(),
    withdrawnAmount: withdrawnAmount.toString(),
    totalAmount: receiverData.amount.toString(),
    root: tree.getRoot().toString(),
    cliffDuration: receiverData.cliffDuration.toString(),
    timePassed: (BigInt(Math.floor(Date.now() / 1000) - 10) - vestingStart).toString(),

    pathElements: path.pathElements.map(x => x.toString()),
    pathIndices: path.pathIndices,
  });

  console.log("Sending withdrawal transaction");
  const txHash = await Vesting.write.withdraw([
    ...proof,
    wallet.account.address,
  ]);

  await client.waitForTransactionReceipt({ hash: txHash });

  console.log(`https://bscscan.com/tx/${txHash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
