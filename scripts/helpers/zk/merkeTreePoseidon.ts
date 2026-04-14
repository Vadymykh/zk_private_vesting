import { buildPoseidon, Poseidon } from "circomlibjs";

export type LeafInput = bigint[];

export class MerkleTree {
  private readonly poseidon: Poseidon;
  levels: bigint[][] = [];
  depth: number;

  constructor(poseidon: Poseidon, depth: number) {
    this.poseidon = poseidon;
    this.depth = depth;
  }

  static async create(leavesInput: LeafInput[], depth: number) {
    const poseidon = await buildPoseidon();
    const tree = new MerkleTree(poseidon, depth);

    const maxLeaves = 1 << depth;

    if (leavesInput.length > maxLeaves) {
      throw new Error("Too many leaves for given depth");
    }

    const leaves = leavesInput.map((input) =>
      tree.hash(input)
    );

    // pad with zeros
    while (leaves.length < maxLeaves) {
      leaves.push(tree.hash([0n, 0n, 0n]));
    }

    tree.build(leaves);
    return tree;
  }

  private hash(inputs: bigint[]): bigint {
    const poseidonRes = this.poseidon(inputs);
    return this.poseidon.F.toObject(poseidonRes);
  }

  private build(leaves: bigint[]) {
    this.levels = [leaves];

    while (this.levels[this.levels.length - 1].length > 1) {
      const current = this.levels[this.levels.length - 1];
      const next: bigint[] = [];

      for (let i = 0; i < current.length; i += 2) {
        const left = current[i];
        const right =
          i + 1 < current.length ? current[i + 1] : current[i]; // duplicate if odd

        next.push(this.hash([left, right]));
      }

      this.levels.push(next);
    }
  }

  getRoot(): bigint {
    return this.levels[this.levels.length - 1][0];
  }

  getPathForElement(index: number) {
    const pathElements: bigint[] = [];
    const pathIndices: number[] = [];

    let currentIndex = index;

    for (let level = 0; level < this.levels.length - 1; level++) {
      const nodes = this.levels[level];

      const isRight = currentIndex % 2;
      const pairIndex = isRight ? currentIndex - 1 : currentIndex + 1;

      pathElements.push(
        pairIndex < nodes.length ? nodes[pairIndex] : nodes[currentIndex]
      );

      pathIndices.push(isRight); // 0 = left, 1 = right

      currentIndex = Math.floor(currentIndex / 2);
    }

    return { pathElements, pathIndices };
  }
}