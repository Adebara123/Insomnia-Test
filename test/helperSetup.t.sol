pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import "../src/MultiUnityNFT.sol";

contract Setup is Test {
    MultiUnityNFT nft;
    PaymentToken paymentToken;
    
    address owner;
    uint256 privateKey;
    address user1 = 0xB345C647AB748B8Eb15F906865234787968B0481; // Phase 1 user
    address user2 = 0x4e92846C27091840579035003Caa6fC28E474672; // Phase 2 user
    address user3 = makeAddr("user3");
    ISablierV2LockupLinear sablier = ISablierV2LockupLinear(0xAFb979d9afAd1aD27C5eFf4E27226E3AB9e5dCC9);
    // Merkle tree data
    bytes32[] public phase1UserMerkleProof;
    bytes32[] public phase2UserMerkleProof;
    bytes32 public phase1Root;
    bytes32 public phase2Root;

    string merkle1Json;
    string merkle2Json;
    
    // Test signature
    bytes phase2Signature;

    // JSON data
    string root;
    
    function setUp() public {
        (owner, privateKey) = makeAddrAndKey("owner");
        vm.startPrank(owner);

        
        // Deploy contracts
        paymentToken = new PaymentToken();
        nft = new MultiUnityNFT(address(paymentToken), sablier); // Using 0 address for sablier for now
        root = vm.projectRoot();
        
        // Load Merkle data from JSON files
        string memory phase1Json = string.concat(root, "/script/ts/generators/output/phase1-merkle-data.json");
        string memory phase2Json = string.concat(root, "/script/ts/generators/output/phase2-merkle-data.json");
        
        console.log(phase1Json);

        merkle1Json = vm.readFile(phase1Json); // get the merkle tree data for phase1
        merkle2Json = vm.readFile(phase2Json); // get the merkle tree data for phase2

        // Parse Phase 1 JSON and set root
        phase1Root = vm.parseJsonBytes32(merkle1Json, ".merkleRoot");
        nft.setPhase1MerkleRoot(phase1Root);
        
        // Parse Phase 2 JSON and set root
        phase2Root = vm.parseJsonBytes32(merkle2Json, ".merkleRoot");
        nft.setPhase2MerkleRoot(phase2Root);
        



        // Get proof for user1 (Phase 1)
        string[] memory phase1ProofData = 
        vm.parseJsonStringArray(merkle1Json,".0xB345C647AB748B8Eb15F906865234787968B0481.proof");
        
        phase1UserMerkleProof = new bytes32[](phase1ProofData.length);

        for (uint256 i = 0; i < phase1ProofData.length; i++) {
            phase1UserMerkleProof[i] = vm.parseBytes32(phase1ProofData[i]);
        }
        
        // // Get proof for user2 (Phase 2)
        string[] memory phase2ProofData = vm.parseJsonStringArray(
            merkle2Json,
            ".0x4e92846C27091840579035003Caa6fC28E474672.proof"
        );
        phase2UserMerkleProof = new bytes32[](phase2ProofData.length);

        for (uint256 i = 0; i < phase2ProofData.length; i++) {
            phase2UserMerkleProof[i] = vm.parseBytes32(phase2ProofData[i]);
        }
        
        // Generate signature for Phase 2
        bytes32 messageHash = keccak256(abi.encodePacked(user2, "PHASE2_MINT"));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedMessageHash); // Using key 1 for owner
        phase2Signature = abi.encodePacked(r, s, v);
        
        // // Mint tokens to users for payment
        paymentToken.mint(user1, 1000 ether);
        paymentToken.mint(user2, 1000 ether);
        paymentToken.mint(user3, 1000 ether);
        
        vm.stopPrank();
    }
}