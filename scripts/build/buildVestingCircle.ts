import { CircomCircuit } from "../helpers/zk/circomCircuit.js";


async function main() {
  const vestingWithdrawCircuit = new CircomCircuit({
    name: "vestingWithdraw",
    localDependencies: [
      "utils/merkleTreePoseidon.circom",
    ],
  });

  await vestingWithdrawCircuit.buildFiles({
    smartContractPath: "contracts/VestingWithdrawVerifier.sol",
    smartContractName: "VestingWithdrawVerifier",
    ptauPower: 14,
  });

  const vestingMerkleTreeCircuit = new CircomCircuit({
    name: "vestingMerkleTree",
    localDependencies: [
      "utils/merkleTreePoseidon.circom",
    ],
  });

  await vestingMerkleTreeCircuit.buildFiles({
    smartContractPath: "contracts/VestingMerkleTreeVerifier.sol",
    smartContractName: "VestingMerkleTreeVerifier",
    ptauPower: 16,
  });
}

main();