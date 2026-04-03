// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage, Listing} from "../libraries/LibAppStorage.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {ERC20Facet} from "./ERC20Facet.sol";

contract NFTMarketplaceFacet {
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);

    // Custom Errors
    error NOT_NFT_OWNER();
    error INVALID_PRICE();
    error LISTING_NOT_ACTIVE();
    error NOT_SELLER();
    error PAYMENT_FAILED();

    function listNFT(uint256 _tokenId, uint256 _price) external {
        AppStorage storage s = LibAppStorage.appStorage();
        ERC721Facet nft = ERC721Facet(address(this));
        
        if(nft.ownerOf(_tokenId) != msg.sender) revert NOT_NFT_OWNER();
        if(_price == 0) revert INVALID_PRICE();

        s.listings[_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            active: true
        });

        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        Listing storage listing = s.listings[_tokenId];
        if(!listing.active) revert LISTING_NOT_ACTIVE();

        ERC20Facet token = ERC20Facet(address(this));
        ERC721Facet nft = ERC721Facet(address(this));

        // Transfer payment
        if(!token.transferFromERC20(msg.sender, listing.seller, listing.price)) revert PAYMENT_FAILED();

        // Transfer NFT
        nft.transferFrom(listing.seller, msg.sender, _tokenId);

        listing.active = false;
        emit NFTSold(_tokenId, msg.sender, listing.price);
    }

    function cancelListing(uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        Listing storage listing = s.listings[_tokenId];
        if(listing.seller != msg.sender) revert NOT_SELLER();
        if(!listing.active) revert LISTING_NOT_ACTIVE();

        listing.active = false;
        emit ListingCancelled(_tokenId);
    }

    function getListing(uint256 _tokenId) external view returns (Listing memory) {
        return LibAppStorage.appStorage().listings[_tokenId];
    }
}