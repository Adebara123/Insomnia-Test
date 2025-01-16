# MultiUnity NFT Project

## Overview

MultiUnity NFT is a sophisticated smart contract implementation of an NFT (Non-Fungible Token) featuring a phased minting mechanism with strict access controls and an automated vesting system through Sablier protocol integration. The contract implements a four-phase minting strategy with varying pricing and verification requirements, culminating in a structured vesting schedule for collected funds.

## Technical Architecture

### Core Components

- ERC721 standard implementation for NFT functionality
- Merkle tree-based whitelist verification system
- ECDSA signature verification for Phase 2 minting
- Sablier V2 integration for linear vesting
- Custom ERC20 payment token integration
- Comprehensive access control system

### Contract Design Details

#### State Management

```solidity
bytes32 public phase1MerkleRoot;
bytes32 public phase2MerkleRoot;
uint256 public currentTokenID;
uint8 public currentPhase;
uint256 streamId;
```

- Maintains phase-specific Merkle roots for whitelist verification
- Tracks current minting phase and token ID
- Stores Sablier stream ID for vesting management

#### Constants

```solidity
uint256 public constant FULL_PRICE = 1000 ether;
uint256 public constant DISCOUNTED_PRICE = 500 ether;
uint256 public constant MAX_SUPPLY = 10000;
```

- Predefined pricing tiers for different minting phases
- Hard supply cap of 10,000 NFTs

### Minting Phases

#### Phase 1: Whitelist Mint

- **Access Control**: Merkle tree verification
- **Price**: Free mint
- **Implementation Details**:
  ```solidity
  function mintPhase1(bytes32[] calldata merkleProof) external nonReentrant {
      require(currentPhase == 1, "Insomnia: Not in phase 1");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(merkleProof, phase1MerkleRoot, leaf),
          "Insomnia: Invalid proof");
      // ... minting logic
  }
  ```

#### Phase 2: Signature-Based Discounted Mint

- **Access Control**:
  - Merkle tree verification
  - ECDSA signature verification
- **Price**: 500 tokens (DISCOUNTED_PRICE)
- **Implementation Details**:
  ```solidity
  function mintPhase2(bytes32[] calldata merkleProof, bytes calldata signature)
      external nonReentrant {
      // ... validation logic
      bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, "PHASE2_MINT"));
      bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
      address signer = ethSignedMessageHash.recover(signature);
      require(signer == owner(), "Insomnia: Invalid signature");
      // ... minting logic
  }
  ```

#### Phase 3: Public Mint

- **Access Control**: Open to all
- **Price**: 1000 tokens (FULL_PRICE)
- **Implementation Details**:
  ```solidity
  function mintPhase3() external nonReentrant {
      require(currentPhase == 3, "Insomnia: Not in phase 3");
      require(paymentToken.transferFrom(msg.sender, address(this), FULL_PRICE),
          "Insomnia: Payment failed");
      // ... minting logic
  }
  ```

#### Phase 4: Vesting Phase

- **Status**: Minting disabled
- **Functionality**: Initiates Sablier vesting
- **Vesting Configuration**:
  - Duration: 104 weeks (2 years)
  - Cliff Period: 52 weeks (1 year)
  ```solidity
  function sablierVesting() public onlyOwner returns (uint256) {
      require(currentPhase == 4, "Insomnia: Still in minting phase");
      // ... vesting setup logic
      params.durations = LockupLinear.Durations({
          cliff: 52 weeks,
          total: 104 weeks
      });
  }
  ```

### Security Implementation

#### Reentrancy Protection

- Implementation of OpenZeppelin's ReentrancyGuard
- All external minting functions protected with nonReentrant modifier
- Strict state updates before external calls

#### Access Control

- Ownable pattern for administrative functions
- Signature verification for Phase 2
- One-time-use signature tracking

```solidity
mapping(bytes => bool) public usedSignatures;
mapping(address => bool) public hasMinted;
```

#### Validation Checks

- Phase-specific requirements
- Supply cap enforcement
- Payment verification
- Duplicate mint prevention

## Testing Framework

### Unit Testing Suite (`test/multiUnityNFT.t.sol`)

#### Phase 1 Tests

- Successful whitelist minting
- Invalid Merkle proof handling
- Duplicate mint prevention
- Phase transition validation

#### Phase 2 Tests

- Signature verification
- Discounted price validation
- Merkle proof verification
- Used signature detection

#### Phase 3 Tests

- Public minting functionality
- Payment processing
- Supply cap enforcement

#### Phase 4 Tests

- Vesting initialization
- Stream creation validation
- Withdrawal mechanics

### Integration Testing (`test/multiUnityNFTMainnetForking.t.sol`)

#### Sablier Integration Tests

```solidity
function test_sucessfulsablierVesting() public {
    // Test setup
    vm.startPrank(owner);
    // ... minting and phase advancement
    uint256 steamID = nft.sablierVesting();
    assert(steamID > 0);
}
```

#### Vesting Tests

- Stream creation verification
- Withdrawal timing validation
- Amount calculation accuracy
- Error condition handling

## Development and Deployment

### Environment Setup

```bash
# Install foundry and dependencies
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install

# Install Node.js dependencies
yarn install
```

### Test Execution

```bash
# Run unit tests
forge test test/multiUnityNFT.t.sol -vv

# Run integration tests with mainnet fork
forge test test/multiUnityNFTMainnetForking.t.sol --fork-url YOUR_RPC_URL -vvvv
```

### Dependencies

- OpenZeppelin Contracts v5.0.0
  - ERC721
  - Ownable
  - ReentrancyGuard
  - ECDSA
  - MerkleProof
- Sablier V2 Core
  - ISablierV2LockupLinear
- PRBMath
  - UD60x18

## Technical Specifications

- Solidity Version: 0.8.26
- Compiler Optimization: Enabled
- Compiler Runs: 200
- Framework: Foundry
- Testing: Forge with Mainnet Forking capability
