// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Storage.sol";

abstract contract Admin is Storage {

    // sets MerkleRoot callable by anyone
    function setMerkleRoot(bytes32 root) external {
        // Enforce that only a successfully executed multisig transaction can call this
        require(msg.sender == address(this), "Only multisig");
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

   // Pause single Owner control
    function pauseControl() external {
        // Enforce that only the multisig can trigger an emergency pause
        require(msg.sender == address(this), "Only multisig"); 

        paused = true;
    }

    // Unpauses the vault, restoring normal operations.
    function unpauseControl() external {
        // Enforce that only the multisig can unpause the contract once resolved
        require(msg.sender == address(this), "Only multisig");

        paused = false;
    }
}
