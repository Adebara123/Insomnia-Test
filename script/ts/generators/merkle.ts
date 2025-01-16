import { encodePacked, getAddress, isAddress, keccak256 } from "viem";
import csv from "csv-parser";
import { createReadStream, writeFile } from "fs";
import path from "path";
import { MerkleTree } from "merkletreejs";

function main() {
  const phase1Addresses = path.join(__dirname, "../phase1.csv");
  const phase2Addresses = path.join(__dirname, "../phase2.csv");

  const phase1Proofs = path.join(__dirname, "output/phase1-merkle-data.json");
  const phase2Proofs = path.join(__dirname, "output/phase2-merkle-data.json");

  const merkleGenerator = (path: string, output: string, type: string[]) => {
    let user_dist_list: `0x${string}`[][] = [];
    let leaves: `0x${string}`[] = [];

    createReadStream(path)
      .pipe(csv())
      .on("data", (row) => {
        if (!isAddress(row["address"])) {
          throw new Error(`Invalid address format: ${row["address"]}`);
        }

        const rowDetails: any[] = Object.values(row);
        const [firstItem, ...rest] = rowDetails;
        const user_dist = [getAddress(firstItem), ...rest];

        const leaf = keccak256(encodePacked(type, user_dist));

        user_dist_list.push(user_dist);
        leaves.push(leaf);
      })
      .on("end", () => {
        // create merkle tree from leaves
        const merkleTree = new MerkleTree(leaves, keccak256, {
          sortPairs: true,
        });

        // get root of merkle tree
        const root = merkleTree.getHexRoot();
        // // create proof file
        writeLeaves(merkleTree, user_dist_list, leaves, root);
      });

    function writeLeaves(
      merkleTree: MerkleTree,
      user_dist_list: `0x${string}`[][],
      leaves: `0x${string}`[],
      root: string
    ) {
      const full_dist: { [key: string]: { leaf: string; proof: string[] } } =
        {};

      for (let i = 0; i < user_dist_list.length; i++) {
        // get leaf hash from leaves
        const leafHash = leaves[i];

        // compute dist object
        const user_dist = {
          leaf: leafHash,
          proof: merkleTree.getHexProof(leafHash),
        };

        // add record to full distribution
        full_dist[user_dist_list[i][0]] = user_dist;
      }

      const merkleInfo = {
        merkleRoot: root,
      };

      const distributions = Object.assign(full_dist, merkleInfo);

      writeFile(output, JSON.stringify(distributions, null, 4), (err) => {
        if (err) {
          console.error(err);
          return;
        }

        console.log(output, "has been written to with a root hash of:\n", root);
      });
    }
  };

  // Merkle generator for phase 1
  merkleGenerator(phase1Addresses, phase1Proofs, ["address"]);

  // Merkle generator  for phase 2
  merkleGenerator(phase2Addresses, phase2Proofs, ["address", "uint256"]);
}

main();
