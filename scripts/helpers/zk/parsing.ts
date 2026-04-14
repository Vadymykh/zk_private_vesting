/**
 * Parse strings arrays to bigint values
 */
export function deepMapToBigInt(v: any): any {
  if (Array.isArray(v)) {
    return v.map(deepMapToBigInt);
  }
  return BigInt(v);
}