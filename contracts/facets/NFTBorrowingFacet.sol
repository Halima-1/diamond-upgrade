// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage, BorrowInfo, StakingInfo} from "../libraries/LibAppStorage.sol";
import {ERC721Facet} from "./ERC721Facet.sol";

contract NFTBorrowingFacet {
    event NFTBorrowed(uint256 indexed tokenId, address indexed borrower, uint256 dueDate);
    event NFTReturned(uint256 indexed tokenId, address indexed borrower);

    // Custom Errors
    error STAKING_POOL_EMPTY();
    error ALREADY_BORROWED();
    error NOT_BORROWER();
    error NO_ACTIVE_BORROW();

    function borrowNFT(uint256 _tokenId, uint256 _duration) external {
        AppStorage storage s = LibAppStorage.appStorage();
        ERC721Facet nft = ERC721Facet(address(this));
        
        StakingInfo storage info = s.stakings[_tokenId];
        if(!info.active) revert STAKING_POOL_EMPTY();
        if(s.borrowings[_tokenId].active) revert ALREADY_BORROWED();

        uint256 dueDate = block.timestamp + _duration;
        s.borrowings[_tokenId] = BorrowInfo({
            borrower: msg.sender,
            dueDate: dueDate,
            active: true
        });

        nft.transferFrom(address(this), msg.sender, _tokenId);

        emit NFTBorrowed(_tokenId, msg.sender, dueDate);
    }

    function returnNFT(uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        BorrowInfo storage bInfo = s.borrowings[_tokenId];
        
        if(bInfo.borrower != msg.sender) revert NOT_BORROWER();
        if(!bInfo.active) revert NO_ACTIVE_BORROW();

        ERC721Facet nft = ERC721Facet(address(this));
        
        bInfo.active = false;
        nft.transferFrom(msg.sender, address(this), _tokenId);

        emit NFTReturned(_tokenId, msg.sender);
    }

    function getBorrowInfo(uint256 _tokenId) external view returns (BorrowInfo memory) {
        return LibAppStorage.appStorage().borrowings[_tokenId];
    }
}