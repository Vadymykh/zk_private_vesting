import { groth16 } from "snarkjs";

async function main() {
  const input = JSON.parse(process.argv[2]);
  const wasmPath = process.argv[3];
  const zkeyPath = process.argv[4];

  const { proof, publicSignals } = await groth16.fullProve(
    input,
    wasmPath,
    zkeyPath
  );

  const calldata = await groth16.exportSolidityCallData(
    proof,
    publicSignals
  );

  // send result via stdout
  console.log(calldata);
  // ending all tasks
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});