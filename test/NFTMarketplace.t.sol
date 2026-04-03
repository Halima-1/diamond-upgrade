// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/NFTMarketplaceFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract NFTMarketplaceTest is Test, DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    ERC721Facet erc721F;
    ERC20Facet erc20F;
    NFTMarketplaceFacet marketplaceF;

    address owner = address(0xABC);
    address seller = address(0x1);
    address buyer = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        
        erc721F = new ERC721Facet();
        erc20F = new ERC20Facet();
        marketplaceF = new NFTMarketplaceFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        bytes4[] memory nftSelectors = new bytes4[](5);
        nftSelectors[0] = ERC721Facet.mint.selector;
        nftSelectors[1] = ERC721Facet.ownerOf.selector;
        nftSelectors[2] = ERC721Facet.initializeNFT.selector;
        nftSelectors[3] = ERC721Facet.transferFrom.selector;
        nftSelectors[4] = ERC721Facet.approve.selector;

        bytes4[] memory tokenSelectors = new bytes4[](5);
        tokenSelectors[0] = ERC20Facet.initializeERC20.selector;
        tokenSelectors[1] = ERC20Facet.balanceOfERC20.selector;
        tokenSelectors[2] = ERC20Facet.approveERC20.selector;
        tokenSelectors[3] = ERC20Facet.transfer.selector;
        tokenSelectors[4] = ERC20Facet.transferFromERC20.selector;

        bytes4[] memory marketSelectors = new bytes4[](3);
        marketSelectors[0] = NFTMarketplaceFacet.listNFT.selector;
        marketSelectors[1] = NFTMarketplaceFacet.buyNFT.selector;
        marketSelectors[2] = NFTMarketplaceFacet.getListing.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721F),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftSelectors
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(erc20F),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: tokenSelectors
        });
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(marketplaceF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: marketSelectors
        });

        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");
        ERC721Facet(address(diamond)).initializeNFT("Market NFT", "MNFT");
        vm.stopPrank();

        vm.prank(buyer);
        ERC20Facet(address(diamond)).initializeERC20("Diamond Dollar", "DUSD", 1000 * 10**18);
    }

    function testListAndBuy() public {
        ERC721Facet nft = ERC721Facet(address(diamond));
        ERC20Facet token = ERC20Facet(address(diamond));
        NFTMarketplaceFacet market = NFTMarketplaceFacet(address(diamond));

        vm.prank(owner);
        uint256 tokenId = nft.mint(seller);

        uint256 price = 100 * 10**18;
        
        // --- IMPORTANT: Seller must list AND approve Diamond to move the NFT! ---
        vm.startPrank(seller);
        nft.approve(address(diamond), tokenId);
        market.listNFT(tokenId, price);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        token.approveERC20(address(diamond), price);
        market.buyNFT(tokenId);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should own the NFT");
        assertEq(token.balanceOfERC20(seller), price);
    }
}
