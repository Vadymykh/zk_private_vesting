pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";
include "./utils/merkleTreePoseidon.circom";

// User prooves he has right to withdraw tokens
template VestingWithdraw(depth) {
    // -------- INPUTS --------
    signal input recipient;
    signal input amount;
    signal input withdrawnAmount;
    signal input totalAmount;
    signal input cliffDuration;
    signal input timePassed;

    signal input root;

    signal input pathElements[depth];
    signal input pathIndices[depth];

    // -------- LEAF HASH --------
    component leafHasher = Poseidon(3);
    leafHasher.inputs[0] <== recipient;
    leafHasher.inputs[1] <== totalAmount;
    leafHasher.inputs[2] <== cliffDuration;

    signal leaf;
    leaf <== leafHasher.out;

    // -------- MERKLE PROOF --------
    component merkleProof = MerkleRootFromBranch(depth);
    merkleProof.leaf <== leaf;

    for (var i = 0; i < depth; i++) {
        merkleProof.pathElements[i] <== pathElements[i];
        merkleProof.pathIndices[i] <== pathIndices[i];
    }

    // Check that root matches
    merkleProof.root === root;

    // -------- AMOUNT CHECK --------
    signal sum;
    sum <== amount + withdrawnAmount;

    component leq = LessEqThan(252);
    leq.in[0] <== sum;
    leq.in[1] <== totalAmount;

    // enforce sum <= totalAmount
    leq.out === 1;

    // -------- PERIOD CHECK --------
    component periodLeq = LessEqThan(252);
    periodLeq.in[0] <== cliffDuration;
    periodLeq.in[1] <== timePassed;

    // enforce cliffDuration <= timePassed
    periodLeq.out === 1;
}

component main {public [
    recipient,
    amount,
    withdrawnAmount,
    timePassed,
    root
]} = VestingWithdraw(4);