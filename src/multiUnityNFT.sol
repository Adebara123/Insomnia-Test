// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";
import {ud60x18} from "@prb/math/src/UD60x18.sol";
import "./paymentToken.sol";


contract MultiUnityNFT is ERC721, Ownable, ReentrancyGuard {

    using ECDSA for bytes32;

    using MessageHashUtils for bytes32;

  
    // Constants
    uint256 public constant FULL_PRICE = 1000 ether;
    uint256 public constant DISCOUNTED_PRICE = 500 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    

    // State Variables
    bytes32 public phase1MerkleRoot;
    bytes32 public phase2MerkleRoot;
    uint256 public currentTokenID;
    uint8 public currentPhase;
    uint256 streamId;
    ISablierV2LockupLinear public sablier;
    PaymentToken public paymentToken;

    // Mappings 
    mapping(address => bool) public  hasMinted;
    mapping(bytes => bool) public usedSignatures;

    // Events
    event NFTMinted(address indexed minter, uint256 indexed tokenId, uint256 price);
    event PhaseAdvanced(uint256 newPhase);
    event Withdraw(address, uint256);

    constructor (
        address _paymentToken,
        ISablierV2LockupLinear _sablier
    ) ERC721("MultiUnityNFT", "MUN")  Ownable(msg.sender){
        paymentToken = PaymentToken(_paymentToken);
        sablier = _sablier;
        currentPhase = 1;
    }

     function mintPhase1(bytes32[] calldata merkleProof) external nonReentrant {
        require(currentPhase == 1, "Insomnia: Not in phase 1");
        require(!hasMinted[msg.sender], "Insomnia: Already minted");
        require(currentTokenID <= MAX_SUPPLY, "Insomnia: Max supply reached");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, phase1MerkleRoot, leaf),
            "Insomnia: Invalid proof"
        );

        _mintNFT(msg.sender, 0);
    }

    function mintPhase2(
        bytes32[] calldata merkleProof,
        bytes calldata signature
    ) external nonReentrant {
        require(currentPhase == 2, "Insomnia: Not in phase 2");
        require(!hasMinted[msg.sender], "Insomnia: Already minted");
        require(currentTokenID <= MAX_SUPPLY, "Insomnia: Max supply reached");
        require(!usedSignatures[signature], "Insomnia: Signature already used");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, DISCOUNTED_PRICE));
        require(
            MerkleProof.verify(merkleProof, phase2MerkleRoot, leaf),
            "Insomnia: Invalid proof"
        );

        // Verify signature
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, "PHASE2_MINT"));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == owner(), "Insomnia: Invalid signature");

        usedSignatures[signature] = true;
        
        require(
            paymentToken.transferFrom(msg.sender, address(this), DISCOUNTED_PRICE),
            "Insomnia: Payment failed"
        );

        _mintNFT(msg.sender, DISCOUNTED_PRICE);
    }

    function mintPhase3() external nonReentrant {
        require(currentPhase == 3, "Insomnia: Not in phase 3");
        require(!hasMinted[msg.sender], "Insomnia: Already minted");
        require(currentTokenID < MAX_SUPPLY, "Insomnia: Max supply reached");

        require(
            paymentToken.transferFrom(msg.sender, address(this), FULL_PRICE),
            "Insomnia: Payment failed"
        );

        _mintNFT(msg.sender, FULL_PRICE);
    }

    function sablierVesting() public onlyOwner returns (uint256) {

        require(currentPhase == 4, "Insomnia: Still in minting phase");
        uint totalAmount = paymentToken.balanceOf(address(this));
        paymentToken.approve(address(sablier), totalAmount);
        
        // Declare params struct
        LockupLinear.CreateWithDurations memory params;

        params.sender = address(this);
        params.recipient = owner();
        params.totalAmount = uint128(totalAmount);
        params.asset = paymentToken;
        params.cancelable = false;
        params.transferable = true;
        params.durations = LockupLinear.Durations({
            cliff:  52 weeks,
            total: 104 weeks
        });
        params.broker = Broker(address(0), ud60x18(0));

        return streamId = ISablierV2LockupLinear(sablier).createWithDurations(params);
    }


    // Internal function 
    function _mintNFT(address to, uint256 price) internal {
        uint256 tokenId = currentTokenID + 1;
        currentTokenID = tokenId;
        hasMinted[to] = true;
        _safeMint(to, tokenId);
        emit NFTMinted(to, tokenId, price);
    }


    // Admin funtions 
    function setPhase1MerkleRoot(bytes32 newRoot) external onlyOwner {
        phase1MerkleRoot = newRoot;
    }
    
    function setPhase2MerkleRoot(bytes32 newRoot) external onlyOwner {
        phase2MerkleRoot = newRoot;
    }

      function advancePhase() external  {
        require(currentPhase < 4, "Insomnia: Already in final phase");
        currentPhase++;
        emit PhaseAdvanced(currentPhase);
    }


}