// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, Vm} from "forge-std/Test.sol";

import "../src/MultiUnityNFT.sol";

import { Setup } from   "./helperSetup.t.sol";

// This test focus on the mainnet forking for the sablier contract


contract MultiUnityNFTMainnetForkingTest is Setup {

    function test_sucessfulsablierVesting () public {
        // Using public mint for this case 
        vm.startPrank(owner);
        nft.advancePhase();
        nft.advancePhase();
        vm.stopPrank();
        
        vm.startPrank(user3);
        paymentToken.approve(address(nft), nft.FULL_PRICE());
        nft.mintPhase3();
        assertEq(nft.balanceOf(user3), 1);
        vm.stopPrank();
        vm.startPrank(owner);
        
        nft.advancePhase();
        uint256 steamID = nft.sablierVesting();

        assert(steamID > 0);
        vm.stopPrank();

    }


    function test_failedsablierVestingNotMintingTime () public {
        
         // Using public mint for this case 
        vm.startPrank(owner);
        nft.advancePhase();
        nft.advancePhase();
        vm.stopPrank();
        
        vm.startPrank(user3);
        paymentToken.approve(address(nft), nft.FULL_PRICE());
        nft.mintPhase3();
        assertEq(nft.balanceOf(user3), 1);
        vm.startPrank(owner);
        
        vm.expectRevert("Insomnia: Still in minting phase");
        nft.sablierVesting();
        vm.stopPrank();
        
    }

       function test_sablierVestingWithdrawal () public {
        // Using public mint for this case 
        vm.startPrank(owner);
        nft.advancePhase();
        nft.advancePhase();
        vm.stopPrank();
        
        vm.startPrank(user3);
        paymentToken.approve(address(nft), nft.FULL_PRICE());
        nft.mintPhase3();
        assertEq(nft.balanceOf(user3), 1);
        vm.startPrank(owner);
        nft.advancePhase();
        
        // ⁠vm.recordLogs();
        uint256 streamId = nft.sablierVesting();

             // Withdraw from Sablier
        vm.warp(block.timestamp + 104 weeks);

        uint128 withdrawalable = sablier.withdrawableAmountOf(streamId);
        
        vm.recordLogs();
        sablier.withdraw(streamId, owner, withdrawalable);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertGt(entries.length, 0);
        
        vm.stopPrank();

    }




}

    // usersMint();

    //     // Lock the miniting fee in a linear vesting schedule
    //     vm.startPrank(signer);

    //     vm.deal(signer, 100_000 ether);

    //     minter.setPhase(Minter.Phase.END);
    //     uint256 _streamId = minter.toSablier();

    //     // Withdraw from Sablier
    //     vm.warp(block.timestamp + 104 weeks);

    //     uint128 withdrawableAmount = SABLIER.withdrawableAmountOf(_streamId);

        // vm.recordLogs();
        // SABLIER.withdraw(_streamId, signer, withdrawableAmount);
        // Vm.Log[] memory entries = vm.getRecordedLogs();
        // assertGt(entries.length, 0);
    //     usersMint();

    //     // Lock the miniting fee in a linear vesting schedule
    //     vm.startPrank(signer);

    //     vm.deal(signer, 100_000 ether);

    //     minter.setPhase(Minter.Phase.END);
    //     uint256 _streamId = minter.toSablier();

    //     // Withdraw from Sablier
    //     vm.warp(block.timestamp + 104 weeks);

    //     uint128 withdrawableAmount = SABLIER.withdrawableAmountOf(_streamId);

    //     vm.recordLogs();
    //     SABLIER.withdraw(_streamId, signer, withdrawableAmount);
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     assertGt(entries.length, 0);

    //     vm.stopPrank();
    //     vm.stopPrank();