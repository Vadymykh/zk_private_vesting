import { before, describe, it } from "node:test";
import { network } from "hardhat";
import { expect, use } from "chai";
import chaiAsPromised from "chai-as-promised";
import { parseEventLogs } from "viem";

import { CircomCircuit } from "../scripts/helpers/zk/circomCircuit.js";
import { MerkleTree } from "../scripts/helpers/zk/merkeTreePoseidon.js";
import { toBig } from "../scripts/helpers/bigNumberHelpers.js";
import { TypedContract } from "../scripts/helpers/viem.js";
import {
  Context,
  getCreateVestingProof,
  getWithdrawProof, RecipientData,
  TREE_DEPTH, withdraw
} from "../scripts/helpers/testing/vestingHelpers.js";

use(chaiAsPromised);

let context: Context;

describe("Vesting", async function () {
  const { viem, networkHelpers } = await network.connect();
  const walletClients = await viem.getWalletClients();

  const [deployer, user1, user2, user3, user4] = walletClients;

  let [withdrawCircuit, creationCircuit]: CircomCircuit[] = [];
  let tree: MerkleTree;
  let WithdrawalVerifier: TypedContract<"VestingWithdrawVerifier">;
  let CreationVerifier: TypedContract<"VestingMerkleTreeVerifier">;
  let Vesting: TypedContract<"PrivateVesting">;
  let VestingFactory: TypedContract<"PrivateVestingFactory">;
  let Token: TypedContract<"TestERC20">;

  const receivers = [
    { recipient: user1.account.address, amount: toBig(100), cliffDuration: 3600 },
    { recipient: user2.account.address, amount: toBig(200), cliffDuration: 3600 * 2 },
    { recipient: user3.account.address, amount: toBig(300), cliffDuration: 3600 * 3 },
  ];
  const receiversInput = receivers
    .map(({ recipient, amount, cliffDuration }) => [
      BigInt(recipient),
      amount,
      BigInt(cliffDuration),
    ]);
  const receiversData = receivers
    .reduce((acc: {
      [recipient: string]: RecipientData
    }, { recipient, amount, cliffDuration }, index) => {
      acc[recipient] = { amount, cliffDuration, index };
      return acc;
    }, {});

  before(async () => {
    withdrawCircuit = new CircomCircuit({ name: "vestingWithdraw" });
    creationCircuit = new CircomCircuit({ name: "vestingMerkleTree" });
  })

  describe("Initialize", async function () {
    it("should deploy contracts", async function () {
      CreationVerifier = await viem.deployContract("VestingMerkleTreeVerifier");
      WithdrawalVerifier = await viem.deployContract("VestingWithdrawVerifier");
      VestingFactory = await viem.deployContract(
        "PrivateVestingFactory",
        [CreationVerifier.address, WithdrawalVerifier.address]
      );
      Token = await viem.deployContract(
        "TestERC20",
        ["TestToken", "TestToken", 18, toBig(1_000_000),]
      );
    });

    it("should built merkle tree", async function () {
      tree = await MerkleTree.create(receiversInput, TREE_DEPTH);
    });

    it("should deploy Vesting contract", async function () {
      await Token.write.approve([VestingFactory.address, toBig(600)], { account: deployer.account });
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
      const vestingAddress = vestingCreatedLog.args[0];

      Vesting = await viem.getContractAt("PrivateVesting", vestingAddress);
      expect((await Vesting.read.token()).toLowerCase()).eq(Token.address);
      expect(await Vesting.read.merkleTreeRoot()).eq(tree.getRoot());
      expect(await Token.read.balanceOf([Vesting.address])).eq(toBig(600));
    });

    it("should set context", async function () {
      context = {
        viem,
        receiversInput,
        receiversData,
        withdrawCircuit,
        creationCircuit,
        Vesting,
        Token,
        tree,
      };
    });
  });
  describe("Verification", async function () {

    it("should verify creation proof successfully", async function () {
      const createVestingProof = await getCreateVestingProof(context);
      const success = await CreationVerifier.read.verifyProof(
        createVestingProof,
      );
      expect(success).to.be.true;
      expect(tree.getRoot()).eq(createVestingProof[3][0], "Root matches");
      expect(toBig(600)).eq(createVestingProof[3][1], "Root matches");
    });

    it("should verify withdrawal proof successfully", async function () {
      const callData = await getWithdrawProof(
        context,
        user2.account.address,
        toBig(100),
        { timePassed: "7200" }
      );
      const success = await WithdrawalVerifier.read.verifyProof(
        callData,
      );
      expect(success).to.be.true;
    });

    describe("Reverts", async function () {
      it("should revert creating withdrawal proof if not enough time has passed", async function () {
        await expect(getWithdrawProof(
          context,
          user1.account.address,
          toBig(100),
          { timePassed: "3599" }
        )).to.be.rejectedWith("Error in template VestingWithdraw");
      });
      it("should revert creating withdrawal proof if withdrawing more than allowed to", async function () {
        await expect(getWithdrawProof(
          context,
          user1.account.address,
          (toBig(100) + 1n).toString(),
          { timePassed: "3600" }
        )).to.be.rejectedWith("Error in template VestingWithdraw");
      });
    });
  });
  describe("Withdrawals", async function () {
    it("should skip time", async function () {
      await networkHelpers.mine(3600, { interval: 1 });
    });

    it("should user 1 withdraw 99 / 100 tokens", async function () {
      await withdraw(context, user1.account, toBig(99));
    });

    it("should user 1 withdraw 100 / 100 tokens and different receiver receive amount", async function () {
      await withdraw(context, user1.account, toBig(1), user4.account.address);
    });

    it("should user 1 be able to withdraw no more", async function () {
      await expect(withdraw(context, user1.account, 1n))
        .to.be.rejectedWith("Error in template VestingWithdraw");
    });

    it("should skip time", async function () {
      await networkHelpers.mine(3600 * 2, { interval: 1 });
    });

    it("should user 2 withdraw full amount", async function () {
      await withdraw(context, user2.account, toBig(200));
    });
    describe("Reverts", async function () {
      it("should revert if too big `timePassed` value was passed", async function () {
        let errorCode = "";
        try {
          await withdraw(
            context, user3.account, toBig(200), user3.account.address,
            { timePassed: (3600 * 4).toString() }
          );
        } catch (e: any) {
          errorCode = e.cause.details;
        }
        expect(errorCode).include("InvalidTimePassed");
      });
      it("should revert if trying to withdraw on behalf of another user", async function () {
        let errorCode = "";
        try {
          await withdraw(
            context, user3.account, toBig(200), user3.account.address,
            { overwriteRecipient: user2.account.address }
          )
        } catch (e: any) {
          errorCode = e.cause.details;
        }
        expect(errorCode).include("InvalidRecipient");
      });
      it("should revert if merkle root is fabricated", async function () {
        let errorCode = "";
        try {
          await withdraw(
            context, user3.account, toBig(200), user3.account.address,
            { overwriteRoot: "22303319" }
          )
        } catch (e: any) {
          errorCode = e.cause.details;
        }
        expect(errorCode).include("InvalidMerkleTreeRoot");
      });
      it("should revert if passed invalid withdrawn amount", async function () {
        let errorCode = "";
        try {
          await withdraw(
            context, user3.account, toBig(200), user3.account.address,
            { overwriteWithdrawnAmount: '123456' }
          )
        } catch (e: any) {
          errorCode = e.cause.details;
        }
        expect(errorCode).include("InvalidWithdrawnAmount");
      });

    });
  });
});
