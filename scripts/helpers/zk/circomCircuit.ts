import { CircuitSignals } from "snarkjs";
import path from "path";
import { execSync, spawn } from "child_process";
import { mkdirSync, existsSync, readFileSync, writeFileSync, copyFileSync } from "fs";
import { fileURLToPath } from "url";
import { StdioOptions } from "node:child_process";
import { deepMapToBigInt } from "./parsing.js";
import { CircuitProof } from "./types.js";
import * as crypto from "node:crypto";

type Metadata = {
  mainCircomFileHash: string;
  dependencyFileHash: { [dep: string]: string };
}

export class CircomCircuit {
  name: string;
  // local .circom dependencies, that should trigger rebuild
  localDependencies: string[];
  // cache dir
  dir: string;
  // build dir
  buildDir: string;
  // random entropy value
  entropy?: string;

  filenames: {
    circom: string;
    ptau0: string;
    ptau1: string;
    ptauFinal: string;
    r1cs: string;
    zkey0: string;
    zkeyFinal: string;
    wasm: string;
    wasmFinal: string;
    metadata: string;
  }

  /**
   * @param name Name of circom file in `circuits/${name}.circom`
   * @param localDependencies List of local .circom dependencies, that should trigger rebuild
   * @param entropy (Optional) random entropy value
   * @param buildDir (Optional) Custom build directory
   */
  constructor({
    name,
    localDependencies = [],
    entropy,
    buildDir: _buildDir,
  }: {
    name: string,
    localDependencies?: string[],
    entropy?: string,
    buildDir?: string,
  }) {
    const _name = name.replace(" ", "");
    const dir = "./cache/circuits/" + _name;
    const buildDir = _buildDir || "./build/circuits";
    this.name = _name;
    this.dir = dir;
    this.buildDir = buildDir;
    this.localDependencies = localDependencies.map(dep => `circuits/${dep}`);
    this.entropy = entropy;

    this.filenames = {
      circom: `circuits/${name}.circom`,
      ptau0: `${dir}/pot12_0000.ptau`,
      ptau1: `${dir}/pot12_0001.ptau`,
      ptauFinal: `${dir}/pot12_final.ptau`,
      r1cs: `${dir}/${_name}.r1cs`,
      zkey0: `${dir}/${_name}_0000.zkey`,
      zkeyFinal: `${buildDir}/${_name}_final.zkey`,
      wasm: `${dir}/${_name}_js/${_name}.wasm`,
      wasmFinal: `${buildDir}/${_name}.wasm`,
      metadata: `${dir}/metadata.json`,
    }

    if (!existsSync(this.filenames.circom)) {
      throw new Error(`${this.filenames.circom} file not found`);
    }
  }

  /**
   * Automated process of building required files
   * @param smartContractPath (Optional) - path of required smart contract output file
   * @param smartContractName (Optional) - path of required smart contract output name
   * @param ptauPower PTAU power - higher for more complex circuits
   */
  async buildFiles({
    smartContractPath,
    smartContractName,
    ptauPower,
  }: {
    smartContractPath?: string,
    smartContractName?: string,
    ptauPower: number,
  }) {
    // Create cache dir if not exist
    mkdirSync(this.dir, { recursive: true });
    mkdirSync(this.buildDir, { recursive: true });

    let { requireRebuild, reason: rebuildReason } = this.checkRebuildRequired();
    if (rebuildReason) console.log(`${rebuildReason}, rebuilding`);

    if (!requireRebuild) {
      console.log(`Skipping build of ${this.name} zk files`);
      return;
    }

    console.log(`Building ${this.name} zk files`);

    // Compile circuit
    run(`circom ${this.filenames.circom} --r1cs --wasm --sym -o ${this.dir} -l ./node_modules`);
    // Copy file to final dir
    copyFileSync(this.filenames.wasm, this.filenames.wasmFinal);

    // Setup ptau
    if (!existsSync(this.filenames.ptauFinal)) {
      console.log("Setting up ptau files");
      run(`snarkjs powersoftau new bn128 ${ptauPower} ${this.filenames.ptau0} -v`);
      run(`snarkjs powersoftau contribute ${this.filenames.ptau0} ${this.filenames.ptau1} --name="First contribution" -e=${this.entropy || generateEntropy()} -v`);
      run(`npx snarkjs powersoftau prepare phase2 ${this.filenames.ptau1} ${this.filenames.ptauFinal} -v`);
    } else {
      console.log("Ptau file exist");
    }

    // Finalize zkey
    run(`npx snarkjs groth16 setup ${this.filenames.r1cs} ${this.filenames.ptauFinal} ${this.filenames.zkey0}`);
    run(`npx snarkjs zkey contribute ${this.filenames.zkey0} ${this.filenames.zkeyFinal} --name="1st Contributor Name" -e=${this.entropy || generateEntropy()} -v`);

    // Export verifier smart contract
    if (smartContractPath && smartContractName) {
      run(`npx snarkjs zkey export solidityverifier ${this.filenames.zkeyFinal} ${smartContractPath}`);
      // update smart contract name
      const absolutePath = path.resolve(smartContractPath);

      let content = readFileSync(absolutePath, "utf-8");
      content = content.replace("Groth16Verifier", smartContractName);
      content = content.replaceAll("uint256 constant ", "uint256 private constant ");
      content = content.replaceAll("uint16 constant ", "uint16 private constant ");
      writeFileSync(absolutePath, content);
    }

    console.log(`Successfully built ${this.name} zk files`);
  }

  checkRebuildRequired(): {
    requireRebuild: boolean,
    reason?: string,
  } {
    let res: {
      requireRebuild: boolean,
      reason?: string,
    } = { requireRebuild: false };

    if (existsSync(this.filenames.circom)) {
      const mainCircomFile = readFileSync(this.filenames.circom, "utf8");
      const mainCircomFileHash = crypto.createHash("sha256").update(mainCircomFile).digest("hex");
      let prevMetadata: Metadata;
      if (existsSync(this.filenames.metadata)) {
        prevMetadata = JSON.parse(readFileSync(this.filenames.metadata, "utf8"));
      } else {
        prevMetadata = {
          mainCircomFileHash: "",
          dependencyFileHash: {},
        };
        res.requireRebuild = true;
        res.reason = "No metadata file found";
      }
      if (prevMetadata.mainCircomFileHash !== mainCircomFileHash) {
        res.requireRebuild = true;
        if (!res.reason) res.reason = "Last modified ts doesn't match";
      }
      if (!existsSync(this.filenames.zkeyFinal)) {
        res.requireRebuild = true;
        if (!res.reason) res.reason = "zkeyFinal not found";
      }
      const metadata: Metadata = {
        mainCircomFileHash,
        dependencyFileHash: {},
      };
      for (const localDependency of this.localDependencies) {
        const prevHash = prevMetadata?.dependencyFileHash?.[localDependency];
        if (prevHash === undefined) {
          res.requireRebuild = true;
          if (!res.reason) res.reason = `Previous last modified ts for ${localDependency} dependency not found`;
        }
        const dependencyFile = readFileSync(localDependency, "utf8");
        const dependencyFileHash = crypto.createHash("sha256").update(dependencyFile).digest("hex");
        if (dependencyFileHash != prevHash) {
          res.requireRebuild = true;
          if (!res.reason) res.reason = `${localDependency} modified`;
        }
        metadata.dependencyFileHash[localDependency] = dependencyFileHash;
      }
      writeFileSync(
        this.filenames.metadata,
        JSON.stringify(metadata, null, 2),
      );
    } else {
      throw new Error(`${this.filenames.circom} file not found`);
    }

    return res;
  }

  async generateCallData<PubSignalsNum extends number>(
    input: CircuitSignals,
    cfg?: {
      logsEnabled?: boolean
    }
  ): Promise<CircuitProof<bigint, PubSignalsNum>> {
    const {
      logsEnabled = false
    } = cfg || {};

    /*
      Following code is a fix for a stuck process in this approach

           const { proof, publicSignals } = await groth16.fullProve(
             input,
             this.filenames.wasmFinal,
             this.filenames.zkeyFinal,
           );
           const calldata = await groth16.exportSolidityCallData(proof, publicSignals);
           const obj = JSON.parse(`[${calldata}]`);

           return deepMapToBigInt(obj);
     */

    const scriptFilename = fileURLToPath(import.meta.url);
    const scriptDirname = path.dirname(scriptFilename);
    const projectPath = process.cwd();
    const relativeToRepo = path.relative(projectPath, scriptDirname);

    return new Promise((resolve, reject) => {
      // using separate process to avoid unfinished tasks
      const child = spawn("node", [
        relativeToRepo + "/circomCircuitProveProcess.ts",
        JSON.stringify(input),
        this.filenames.wasmFinal,
        this.filenames.zkeyFinal,
      ], {
        cwd: projectPath
      });

      let stdout = "";
      let stderr = "";

      child.stdout.on("data", (data) => {
        if (logsEnabled) console.log(data.toString());
        stdout = data.toString();
      });

      child.stderr.on("data", (data) => {
        stderr = data.toString();
      });

      child.on("close", (code) => {
        if (code !== 0) {
          return reject(new Error(stderr || `Exit code ${code}`));
        }

        try {
          const obj = JSON.parse(`[${stdout.trim()}]`);
          resolve(deepMapToBigInt(obj));
        } catch (e) {
          reject(e);
        }
      });
    });
  }
}

function generateEntropy(bytes = 32) {
  const array = new Uint8Array(bytes);
  crypto.getRandomValues(array);
  return Array.from(array, b => b.toString(16).padStart(2, '0')).join('');
}

function run(
  cmd: string,
  cfg?: { stdio?: StdioOptions, logCommand?: boolean }
) {
  const {
    stdio = "inherit",
    logCommand = true,
  } = cfg || {};
  if (logCommand) {
    console.log(">", cmd);
  }
  execSync(cmd, { stdio });
}