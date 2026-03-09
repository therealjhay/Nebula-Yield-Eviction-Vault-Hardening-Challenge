// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


abstract contract Storage {

    // Represents a multisig transaction proposed by an owner
    struct Transaction {
        address to;             
        uint256 value;           
        bytes data;              
        bool executed;           
        uint256 confirmations;   
        uint256 submissionTime;  
        uint256 executionTime;   
    }

    // List of multisig owner addresses
    address[] public owners;

    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    
    mapping(uint256 => Transaction) public transactions;

    uint256 public txCount;
    mapping(address => uint256) public balances;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    mapping(bytes32 => bool) public usedHashes;

    uint256 public constant TIMELOCK_DURATION = 1 hours;
    uint256 public totalVaultValue;
    bool public paused;


    // --- Events --- //
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);
}
