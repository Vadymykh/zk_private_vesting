import { formatUnits, parseUnits } from "ethers";

export const toNum = (bigNumber: bigint, decimals = 18): number => Number(formatUnits(bigNumber, decimals));
export const toBig = (number: number, decimals = 18): bigint => {
  return parseUnits(
    number.toLocaleString("en-US", { useGrouping: false, maximumFractionDigits: decimals }),
    decimals
  );
};