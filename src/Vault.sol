// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Multisig.sol";
import "./Admin.sol";

contract Vault is Multisig, Admin {
    
    constructor(address[] memory _owners, uint256 _threshold) payable {
        require(_owners.length > 0, "no owners");
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "zero address");
            isOwner[o] = true;
            owners.push(o);
        }
        totalVaultValue = msg.value;
    }

    receive() external payable {
        balances[msg.sender] += msg.value; // FIX: receive() uses tx.origin
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(!paused, "paused");
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        (bool success, ) = msg.sender.call{value: amount}(""); // FIX: withdraw uses .transfer
        require(success, "transfer failed");
        emit Withdrawal(msg.sender, amount);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external {
        require(!paused, "paused");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        require(computed == merkleRoot, "invalid proof");
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;
        totalVaultValue -= amount;
        (bool success, ) = msg.sender.call{value: amount}(""); // FIX: claim uses .transfer
        require(success, "transfer failed");
        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        // FIX: The original code used MerkleProof.recover, but recovery is done via ECDSA.
        return ECDSA.recover(messageHash, signature) == signer;
    }

    function emergencyWithdrawAll(address to) external { // FIX: emergencyWithdrawAll public drain
        require(msg.sender == address(this), "Only multisig");
        require(to != address(0), "zero address");
        uint256 amount = address(this).balance;
        totalVaultValue = 0;
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");
    }
}
