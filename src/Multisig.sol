// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Storage.sol";

abstract contract Multisig is Storage {

    function submitTransaction(address to, uint256 value, bytes calldata data) external {
        // Only valid owners can submit transactions
        require(isOwner[msg.sender], "not owner");

        uint256 id = txCount++;

        // Store the new transaction in state
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: threshold == 1 ? block.timestamp + TIMELOCK_DURATION : 0 
        });

        confirmed[id][msg.sender] = true;

        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external {
        require(isOwner[msg.sender], "not owner");

        Transaction storage txn = transactions[txId];

        require(!txn.executed, "already executed");

        require(!confirmed[txId][msg.sender], "already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "threshold not met");

        require(!txn.executed, "already executed");

        require(block.timestamp >= txn.executionTime, "timelock not expired");

        txn.executed = true;

        (bool s,) = txn.to.call{value: txn.value}(txn.data);
        require(s, "tx failed");

        emit Execution(txId);
    }
}
