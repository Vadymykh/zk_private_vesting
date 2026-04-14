import { task } from "hardhat/config";

export const sizeContracts = task("size-contracts", "Print contract sizes")
  .setInlineAction(async (_taskArguments, hre) => {
    const artifacts = await hre.artifacts.getAllFullyQualifiedNames();

    for (const name of artifacts) {
      const artifact = await hre.artifacts.readArtifact(name);

      const size = (artifact.deployedBytecode.length - 2) / 2;

      console.log(`${name}:`.padEnd(100, ".") + `${size} bytes`);
    }
  })
  .build();