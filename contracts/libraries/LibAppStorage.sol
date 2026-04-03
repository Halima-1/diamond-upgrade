// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

struct Listing {
    address seller;
    uint256 price;
    bool active;
}

struct StakingInfo {
    address staker;
    uint256 startTime;
    bool active;
}

struct BorrowInfo {
    address borrower;
    uint256 dueDate;
    bool active;
}

struct UpgradeProposal {
    IDiamondCut.FacetCut[] cuts;
    address init;
    bytes calldata_;
    uint256 approvals;
    bool executed;
    mapping(address => bool) hasVoted;
}

struct AppStorage {
    // --- NFT (ERC721 Scratch) ---
    uint256 nextTokenId;
    string nftName;
    string nftSymbol;
    mapping(uint256 => address) nftOwners;
    mapping(address => uint256) nftBalances;
    mapping(uint256 => address) nftTokenApprovals;
    mapping(address => mapping(address => bool)) nftOperatorApprovals;

    // --- ERC20 Scratch ---
    string tokenName;
    string tokenSymbol;
    mapping(address => uint256) tokenBalances;
    mapping(address => mapping(address => uint256)) tokenAllowances;
    uint256 tokenTotalSupply;

    // --- Marketplace & Lending pool ---
    mapping(uint256 => Listing) listings;
    mapping(uint256 => StakingInfo) stakings;
    mapping(uint256 => BorrowInfo) borrowings;

    // --- MultiSig / Governance ---
    address[] signers;
    uint256 requiredQuorum;
    mapping(address => bool) isSigner;
    uint256 proposalCount;
    mapping(uint256 => UpgradeProposal) proposals;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}
