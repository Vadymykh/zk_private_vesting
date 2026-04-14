export type CircuitProof<T, PubSignalsNum extends number> = readonly [
  [T, T],
  [[T, T], [T, T]],
  [T, T],
  FixedArray<T, PubSignalsNum>
];

type FixedArray<T, N extends number, R extends T[] = []> =
  R['length'] extends N ? R : FixedArray<T, N, [...R, T]>;