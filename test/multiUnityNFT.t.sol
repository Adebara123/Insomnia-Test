// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";

import "../src/MultiUnityNFT.sol";
import { Setup } from   "./helperSetup.t.sol";

contract MultiUnityNFTTest is Setup {

    // Phase 1 Tests
    function test_Phase1MintSuccess() public {
        vm.startPrank(user1);
        paymentToken.approve(address(nft), type(uint256).max);
        nft.mintPhase1(phase1UserMerkleProof);
        vm.expectRevert("Insomnia: Already minted");
        nft.mintPhase1(phase1UserMerkleProof);
        vm.stopPrank();
    }

     function test_Phase1MintFailRepeatedMint() public {
        vm.startPrank(user1);
        paymentToken.approve(address(nft), type(uint256).max);
        nft.mintPhase1(phase1UserMerkleProof);
        assertEq(nft.balanceOf(user1), 1);
        vm.stopPrank();
    }
    
    function test_Phase1MintFailInvalidProof() public {
        // Try to use user2's address with user1's proof
        vm.startPrank(user2);
        vm.expectRevert("Insomnia: Invalid proof");
        nft.mintPhase1(phase1UserMerkleProof);
        vm.stopPrank();
    }
    
    function test_Phase1MintFailWrongPhase() public {
        vm.prank(owner);
        nft.advancePhase(); // Move to phase 2
        
        vm.startPrank(user1);
        vm.expectRevert("Insomnia: Not in phase 1");
        nft.mintPhase1(phase1UserMerkleProof);
        vm.stopPrank();
    }
    
    // // Phase 2 Tests
    function test_Phase2MintSuccess() public {
        // Advance to phase 2
        vm.prank(owner);
        nft.advancePhase();
        
        vm.startPrank(user2);
        paymentToken.approve(address(nft), nft.DISCOUNTED_PRICE());
        nft.mintPhase2(phase2UserMerkleProof, phase2Signature);
        assertEq(nft.balanceOf(user2), 1);
        vm.stopPrank();
    }
    
    function test_Phase2MintFailInvalidSignature() public {
        vm.prank(owner);
        nft.advancePhase();
        
        // Generate invalid signature
        bytes32 messageHash = keccak256(abi.encodePacked(user2, "WRONG_MESSAGE"));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, ethSignedMessageHash); // Using different key
        bytes memory invalidSignature = abi.encodePacked(r, s, v);
        
        vm.startPrank(user2);
        paymentToken.approve(address(nft), nft.DISCOUNTED_PRICE());
        vm.expectRevert("Insomnia: Invalid signature");
        nft.mintPhase2(phase2UserMerkleProof, invalidSignature);
        vm.stopPrank();
    }
    
    function test_Phase2MintFailInvalidProof() public {
        vm.prank(owner);
        nft.advancePhase();
        
        // Try to use phase1 proof for phase2
        vm.startPrank(user2);
        paymentToken.approve(address(nft), nft.DISCOUNTED_PRICE());
        vm.expectRevert("Insomnia: Invalid proof");
        nft.mintPhase2(phase1UserMerkleProof, phase2Signature);
        vm.stopPrank();
    }
    
    function test_Phase2MintFailReusedSignature() public {
        vm.prank(owner);
        nft.advancePhase();
        
        vm.startPrank(user2);
        paymentToken.approve(address(nft), nft.DISCOUNTED_PRICE());
        nft.mintPhase2(phase2UserMerkleProof, phase2Signature);
        
        // Try to mint again with same signature
        vm.expectRevert("Insomnia: Already minted");
        nft.mintPhase2(phase2UserMerkleProof, phase2Signature);
        vm.stopPrank();
    }
    // // Phase 3 Tests
    function test_Phase3MintSuccess() public {
        // Advance to phase 3
        vm.startPrank(owner);
        nft.advancePhase();
        nft.advancePhase();
        vm.stopPrank();
        
        vm.startPrank(user3);
        paymentToken.approve(address(nft), nft.FULL_PRICE());
        nft.mintPhase3();
        assertEq(nft.balanceOf(user3), 1);
        vm.stopPrank();
    }
    
    function test_Phase3MintFailWrongPhase() public {
        vm.startPrank(user3);
        paymentToken.approve(address(nft), nft.FULL_PRICE());
        vm.expectRevert("Insomnia: Not in phase 3");
        nft.mintPhase3();
        vm.stopPrank();
    }
    
    // General test
    function test_AdvancePhaseFailFinalPhase() public {
        vm.startPrank(owner);
        nft.advancePhase(); // Phase 2
        nft.advancePhase(); // Phase 3
        nft.advancePhase(); // Minting over phase
        vm.expectRevert("Insomnia: Already in final phase");
        nft.advancePhase();
        vm.stopPrank();
    }

    function test_PaymentFailurePhase2() public {
        vm.prank(owner);
        nft.advancePhase();

        vm.startPrank(user2);
        // Don't approve payment
        vm.expectRevert();
        nft.mintPhase2(phase2UserMerkleProof, phase2Signature);
        vm.stopPrank();
    }

    function test_PaymentFailurePhase3() public {
        vm.startPrank(owner);
        nft.advancePhase();
        nft.advancePhase();
        vm.stopPrank();

        vm.startPrank(user3);
        // Don't approve payment
        vm.expectRevert();
        nft.mintPhase3();
        vm.stopPrank();
    }
}

