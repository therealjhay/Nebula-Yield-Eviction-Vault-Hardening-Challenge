// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address user = address(0x4);
    
    address[] owners;
    
    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        vm.deal(owner1, 100 ether);
        vm.prank(owner1);
        vault = new Vault{value: 10 ether}(owners, 2);
    }

    function testDeposit() public {
        vm.deal(user, 5 ether);
        vm.prank(user);
        vault.deposit{value: 5 ether}();
        
        assertEq(vault.balances(user), 5 ether);
        assertEq(vault.totalVaultValue(), 15 ether);
    }
    
    function testWithdraw() public {
        vm.deal(user, 5 ether);
        vm.prank(user);
        vault.deposit{value: 5 ether}();
        
        uint256 preBalance = user.balance;
        vm.prank(user);
        vault.withdraw(2 ether);
        
        assertEq(vault.balances(user), 3 ether);
        assertEq(user.balance, preBalance + 2 ether);
    }
    
    function testMultisigFlowAndPause() public {
        // Test Multisig pausing the contract
        bytes memory pauseData = abi.encodeWithSignature("pause()");
        
        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, pauseData);
        
        vm.prank(owner2);
        vault.confirmTransaction(0);
        
        // Threshold is 2, so it's reached. Timelock is 1 hour.
        vm.warp(block.timestamp + 1 hours);
        
        vault.executeTransaction(0);
        
        assertTrue(vault.paused());
        
        // Unpause
        bytes memory unpauseData = abi.encodeWithSignature("unpause()");
        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, unpauseData);
        vm.prank(owner2);
        vault.confirmTransaction(1);
        
        vm.warp(block.timestamp + 1 hours);
        vault.executeTransaction(1);
        
        assertFalse(vault.paused());
    }
    
    function testClaim() public {
        bytes32 leaf1 = keccak256(abi.encodePacked(user, uint256(5 ether)));
        bytes32 leaf2 = keccak256(abi.encodePacked(owner1, uint256(10 ether)));
        
        bytes32 computedRoot = leaf1 < leaf2 
            ? keccak256(abi.encodePacked(leaf1, leaf2))
            : keccak256(abi.encodePacked(leaf2, leaf1));
        
        // Set merkle root via multisig
        bytes memory data = abi.encodeWithSignature("setMerkleRoot(bytes32)", computedRoot);
        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, data);
        vm.prank(owner2);
        vault.confirmTransaction(0);
        
        vm.warp(block.timestamp + 1 hours);
        vault.executeTransaction(0);
        
        assertEq(vault.merkleRoot(), computedRoot);
        
        // Construct proof for leaf1
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leaf2; // The sibling
        
        uint256 preBalance = user.balance;
        vm.prank(user);
        vault.claim(proof, 5 ether);
        
        assertTrue(vault.claimed(user));
        assertEq(user.balance, preBalance + 5 ether);
    }

    function testEmergencyWithdrawAll() public {
        address emergencyReceiver = address(0x5);
        bytes memory callData = abi.encodeWithSignature("emergencyWithdrawAll(address)", emergencyReceiver);
        
        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, callData);
        vm.prank(owner2);
        vault.confirmTransaction(0);
        
        vm.warp(block.timestamp + 1 hours);
        
        uint256 preVaultBalance = address(vault).balance;
        uint256 preReceiverBalance = emergencyReceiver.balance;
        
        vault.executeTransaction(0);
        
        assertEq(address(vault).balance, 0);
        assertEq(vault.totalVaultValue(), 0);
        assertEq(emergencyReceiver.balance, preReceiverBalance + preVaultBalance);
    }

    function testTimelockBypassFixWithThresholdOne() public {
        address[] memory singleOwner = new address[](1);
        singleOwner[0] = owner1;
        
        Vault singleVault = new Vault{value: 10 ether}(singleOwner, 1);
        
        bytes memory pauseData = abi.encodeWithSignature("pause()");
        vm.prank(owner1);
        singleVault.submitTransaction(address(singleVault), 0, pauseData);
        
        // Cannot execute immediately despite threshold 1
        vm.expectRevert("timelock not expired");
        singleVault.executeTransaction(0);
        
        // Warp bypass
        vm.warp(block.timestamp + 1 hours);
        singleVault.executeTransaction(0);
        assertTrue(singleVault.paused());
    }
}