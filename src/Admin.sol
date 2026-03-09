// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Storage.sol";

abstract contract Admin is Storage {

    function setMerkleRoot(bytes32 root) external {

        require(msg.sender == address(this), "Only multisig"); // setMerkleRoot callable by anyone

        merkleRoot = root;

        emit MerkleRootSet(root);
    }


    function pause() external {

        require(msg.sender == address(this), "Only multisig"); // pause single owner control

        paused = true;
    }


    function unpause() external {

        require(msg.sender == address(this), "Only multisig"); // unpause single owner control

        paused = false;
    }
}
