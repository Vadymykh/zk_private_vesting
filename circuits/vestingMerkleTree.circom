pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/poseidon.circom";
include "./utils/merkleTreePoseidon.circom";

// Creator prooves he has all required data for merkle tree
// Recipient MUST NOT be duplicated, but we don't check it here to avoid unnecessary complexity
template VestingMerkleTree(depth) {
    // -------- INPUTS --------
    signal input recipients[1 << depth];
    signal input amounts[1 << depth];
    signal input cliffDurations[1 << depth];

    signal output root;
    signal output totalAmount;

    signal amountsAccumulator[1 << depth + 1];
    amountsAccumulator[0] <== 0;

    signal leafs[1 << depth];
    component hashers[1 << depth];
    component tree = MerkleRootFromLeaves(depth);
    for (var i = 0; i < 1 << depth; i++) {
        hashers[i] = Poseidon(3);

        hashers[i].inputs[0] <== recipients[i];
        hashers[i].inputs[1] <== amounts[i];
        hashers[i].inputs[2] <== cliffDurations[i];

        tree.leaves[i] <== hashers[i].out;
        amountsAccumulator[i + 1] <== amountsAccumulator[i] + amounts[i];
    }
    totalAmount <== amountsAccumulator[1 << depth];
    root <== tree.root;
}

component main = VestingMerkleTree(4);