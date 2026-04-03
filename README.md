# Decentralized Diamond Ecosystem

This project implements a comprehensive NFT ecosystem using the EIP-2535 Diamond Pattern. It transitions from a centralized ownership model to a fully decentralized, DAO-governed protocol where all upgrades are managed by a Multi-Signature governance system.

## Core Architecture

### Diamond Pattern (EIP-2535)
The protocol uses a single proxy (the Diamond) that delegatecalls to multiple facets. This allows the system to bypass the 24KB contract size limit and remain modular and upgradeable.

### Unified AppStorage
All facets share a central storage state through `LibAppStorage.sol`. This prevents storage collisions and allows different facets (like the Marketplace and Staking pool) to interact with the same underlying data efficiently.

### DAO MultiSig Governance
The protocol is governed by a Multi-Sig facet (`DiamondMultisig.sol`). No single owner has control over the system. 
- **Proposals**: Any signer can propose a `diamondCut` upgrade.
- **Quorum**: A required number of signers must approve the proposal.
- **Execution**: Once quorum is met, the Diamond automatically executes the upgrade and updates its internal function selectors.

## Facet Overview

### 1. ERC721 Luxury NFT Facet
A custom implementation of the ERC721 standard written from scratch. 
- **On-Chain Metadata**: Generates a high-end SVG card directly on-chain.
- **Ownership Logic**: Custom transfer and approval mechanisms optimized for Diamond storage.

### 2. ERC20 Payment Facet
A custom ERC20 implementation used as the primary currency within the marketplace. It manages balances and allowances for P2P trading.

### 3. NFT Marketplace Facet
Allows users to list and buy NFTs using the custom ERC20 token. 
- **Escrowless Listing**: NFTs remain in the user's wallet until bought (requires approval).
- **Consensus-Based Trading**: Ensures atomicity between payment and transfer.

### 4. Staking & Borrowing Facets
A peer-to-peer lending economy.
- **Staking**: Users lock NFTs into the Diamond escrow.
- **Borrowing**: Other users can borrow staked NFTs for a set duration.
- **Escrow Management**: The system automatically tracks due dates and ownership status.

## Getting Started

### Prerequisites
- Foundry (Forge & Cast)

### Installation
```bash
git clone <repository-url>
cd Foundry-Hardhat-Diamonds
forge install
```

### Testing
The project includes a robust test suite that simulates the entire lifecycle, including Multi-Sig upgrades and DeFi interactions.

Run all tests:
```bash
forge test -vv
```

Run specific ecosystem tests:
```bash
forge test --match-path "test/NFT*.t.sol" -vv
```

## Security
- All sensitive functions are protected by the `onlySigner` modifier.
- State management is strictly controlled via the `AppStorage` struct to ensure consistency across upgrades.
- Error handling uses gas-efficient custom errors (`if (...) revert ERROR()`).
