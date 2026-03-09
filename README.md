# Nebula Yield – Eviction Vault Hardening Challenge

This project represents the completion of the Phase 1 - Day 1 Milestone for the Nebula Yield – Eviction Vault Hardening Challenge. 

The monolithic `EvictionVault.sol` contract has been successfully refactored into a modular architecture to improve maintainability, separation of concerns, and most importantly, security.

## Modular Architecture

The monolithic smart contract has been decomposed into the following files:

- **`src/Storage.sol`**: Contains the state variables, `Transaction` struct, and events for the protocol.
- **`src/Multisig.sol`**: Contains the multisig functionality (`submitTransaction`, `confirmTransaction`, `executeTransaction`), inheriting from `Storage`.
- **`src/Admin.sol`**: Contains the administrative controls for the vault (`setMerkleRoot`, `pause`, `unpause`), inheriting from `Storage`.
- **`src/Vault.sol`**: The core user-facing contract containing deposit, withdrawal, and claim logic, inheriting from both `Multisig` and `Admin`.

## Addressed Critical Vulnerabilities

During the refactoring, the following critical vulnerabilities were fixed:

1. **`setMerkleRoot` Callable by Anyone**: Restricted to `require(msg.sender == address(this), "Only multisig")` so that only a threshold of owners can update the root.
2. **`emergencyWithdrawAll` Public Drain**: Added a `to` parameter and restricted the caller to `msg.sender == address(this)`.
3. **`pause`/`unpause` Single Owner Control**: Restrict `pause` and `unpause` to be executable only via the multisig flow (require `msg.sender == address(this)`).
4. **`receive()` Uses `tx.origin`**: Replaced `tx.origin` with `msg.sender` to prevent potential phishing attacks.
5. **`withdraw` & `claim` Uses `.transfer`**: `.transfer` (which is capped at 2300 gas and can break with smart contract receivers) was replaced with `.call{value: amount}("")`.
6. **Timelock Execution Bypass on Threshold=1**: Fixed the timelock bypass when `threshold == 1`. The `executionTime` is now correctly set to `block.timestamp + TIMELOCK_DURATION` immediately upon submission if `threshold == 1`.

## Testing

A comprehensive test suite was added in `test/Vault.t.sol` which includes tests for:
- Successful deposit and withdrawal.
- Complete multisig flow (Submission, Confirmation, Timelock, and Execution).
- Merkle root setting via multisig and subsequent successful user claims.
- Emergency multisig withdrawal and pausing functionally.
- Explicit verification of the Timelock Execution Bypass fix.

Run tests using:
```bash
forge test -vvv
```
