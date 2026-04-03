// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage, StakingInfo} from "../libraries/LibAppStorage.sol";
import {ERC721Facet} from "./ERC721Facet.sol";

contract ERC721StakingFacet {
    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId);

    function stakeNFT(uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        ERC721Facet nft = ERC721Facet(address(this));
        
        if (nft.ownerOf(_tokenId) != msg.sender) revert("not the owner");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        s.stakings[_tokenId] = StakingInfo({
            staker: msg.sender,
            startTime: block.timestamp,
            active: true
        });

        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        StakingInfo storage info = s.stakings[_tokenId];
        
        require(info.staker == msg.sender, " not the staker");
        require(info.active, "not active");

        ERC721Facet nft = ERC721Facet(address(this));
        
        info.active = false;
        nft.transferFrom(address(this), msg.sender, _tokenId);

        emit NFTUnstaked(_tokenId);
    }

    function getStakingInfo(uint256 _tokenId) external view returns (StakingInfo memory) {
        return LibAppStorage.appStorage().stakings[_tokenId];
    }
}
