pragma circom 2.2.3;

include "circomlib/circuits/poseidon.circom";

template MerkleRootFromBranch(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices[levels]; // 0 = left, 1 = right

    signal output root;

    component selectors[levels];
    component hashers[levels];

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].out;
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = Poseidon(2);
        hashers[i].inputs[0] <== selectors[i].left;
        hashers[i].inputs[1] <== selectors[i].right;
    }

    root <== hashers[levels - 1].out;
}

template MerkleRootFromLeaves(depth) {
    signal input leaves[1 << depth];
    signal output root;

    // store intermediate levels
    signal level[depth + 1][1 << depth];

    // level 0 = leaves
    for (var i = 0; i < (1 << depth); i++) {
        level[0][i] <== leaves[i];
    }

    // build tree
    component hashers[depth][1 << depth];
    for (var d = 0; d < depth; d++) {
        for (var i = 0; i < (1 << (depth - d - 1)); i++) {
            hashers[d][i] = Poseidon(2);

            hashers[d][i].inputs[0] <== level[d][2 * i];
            hashers[d][i].inputs[1] <== level[d][2 * i + 1];

            level[d + 1][i] <== hashers[d][i].out;
        }
    }

    root <== level[depth][0];
}


// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;         // 0 = left, 1 = right
    signal output left;
    signal output right;

    s * (1 - s) === 0;
    left <== (in[1] - in[0])*s + in[0];
    right <== (in[0] - in[1])*s + in[1];
}