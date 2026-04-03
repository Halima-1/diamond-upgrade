# Diamond Ecosystem: Architecture & Security

This document provides a technical breakdown of the protocol's architectural decisions and the security measures implemented to ensure its integrity and decentralization.

## 1. Architectural Structure

### EIP-2535 Diamond Proxy Model
The protocol uses a Diamond Proxy (EIP-2535) to manage multiple logic contracts (facets) through a single entry point (the Diamond). This architecture provides:
- **Modular Scalability**: Logic is separated into distinct facets, preventing contract size limit issues.
- **Atomic Upgradability**: Function selectors can be added, replaced, or removed without redeploying the entire system.
- **Shared Storage**: All facets interact with the same underlying storage of the proxy.

### Unified Storage Strategy (AppStorage)
Instead of using standard isolated storage per contract, the protocol implements a **Shared Storage** pattern through `LibAppStorage.sol`. This ensures:
- **Zero Collisions**: All state variables are defined within a single `AppStorage` struct, guaranteeing that no two facets overwrite the same slot.
- **Seamless Communication**: Facets can read and write to the same variables (e.g., the Marketplace can check a user's ERC20 balance managed by the Token facet).
- **Slot Consistency**: The struct is always at the same slot (`0x0`) for all delegatecalls.

## 2. Facet Interaction Layer

Facets communicate with each other through internal `delegatecall` redirects via the Diamond's address.
- **Example**: The `NFTBorrowingFacet` interacts with the `ERC721Facet` by casting `address(this)` to the target interface.
- **Escrow Persistence**: Staked NFTs live in the Diamond address, allowing multiple facets to share the collateral pool without needing complex external approvals.

## 3. Governance & Control

### DAO Multi-Signature Upgrade Model
Upgradability is strictly controlled by the `DiamondMultisigFacet`.
- **Proposals**: Upgrades are submitted as `FacetCut` structs containing function selectors and implementation addresses.
- **Signer Quorum**: A majority consensus is required to authorize an upgrade.
- **Internal Execution**: Once authorized, the code executes an internal call to the Diamond's "cut" function, updating the selector mapping in real-time.

## 4. Security Measures

### Access Control
- **Quorum Restriction**: No individual address can upgrade the Diamond. 
- **OnlySigner Modifier**: Critical governance and initialization functions are strictly guarded.
- **Replay Protection**: Proposal IDs are unique and incremental, preventing the re-execution of old upgrade payloads.

### Storage Integrity
- **State Isolation**: New variables are never added to individual facets; they must always be appended to the global `AppStorage` struct in `LibAppStorage.sol`.
- **Inheritance Safety**: Facets do not inherit from logic contracts that have their own storage variables, which prevents slot shadowing.

### Gas-Efficient Error Handling
- **Custom Errors**: The protocol replaced legacy `require` strings with `error` definitions and `if (...) revert` patterns. This significantly reduces gas costs during execution and reverts.

### Ownership Safety
- **Zero Address Checks**: All core functions (minting, transfers, governance setup) revert if an interaction with the `address(0)` is attempted.
- **Transfer Guards**: The logic explicitly verifies caller ownership and approval status before moving any ERC20 or ERC721 assets, following the underlying security principles of the standard.

## 5. Deployment & Lifecycle

The system is deployed in a multi-stage process:
1.  **Deployment**: Diamond Proxy and core facets are put on-chain.
2.  **Initial Cut**: The `DiamondCutFacet` is used to bootstrap the system.
3.  **Governance Handover**: The `OwnershipFacet` is replaced by the `DiamondMultisigFacet`, transferring control from a single owner to the community signers.
4.  **Modular Upgrades**: Future features (e.g., adding a reward pool) are proposed and voted on through the governance facet.
