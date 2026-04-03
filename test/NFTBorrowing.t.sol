// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC721StakingFacet.sol";
import "../contracts/facets/NFTBorrowingFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract NFTBorrowingTest is Test, DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    ERC721Facet erc721F;
    ERC721StakingFacet stakingF;
    NFTBorrowingFacet borrowingF;

    address owner = address(0xABC);
    address lender = address(0x1);
    address borrower = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        
        erc721F = new ERC721Facet();
        stakingF = new ERC721StakingFacet();
        borrowingF = new NFTBorrowingFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        bytes4[] memory nftSelectors = new bytes4[](5);
        nftSelectors[0] = ERC721Facet.mint.selector;
        nftSelectors[1] = ERC721Facet.ownerOf.selector;
        nftSelectors[2] = ERC721Facet.initializeNFT.selector;
        nftSelectors[3] = ERC721Facet.transferFrom.selector;
        nftSelectors[4] = ERC721Facet.approve.selector;

        bytes4[] memory stakingSelectors = new bytes4[](2);
        stakingSelectors[0] = ERC721StakingFacet.stakeNFT.selector;
        stakingSelectors[1] = ERC721StakingFacet.getStakingInfo.selector;

        bytes4[] memory borrowingSelectors = new bytes4[](3);
        borrowingSelectors[0] = NFTBorrowingFacet.borrowNFT.selector;
        borrowingSelectors[1] = NFTBorrowingFacet.returnNFT.selector;
        borrowingSelectors[2] = NFTBorrowingFacet.getBorrowInfo.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721F),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftSelectors
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(stakingF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: stakingSelectors
        });
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(borrowingF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: borrowingSelectors
        });

        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");
        ERC721Facet(address(diamond)).initializeNFT("Borrow NFT", "BNFT");
        vm.stopPrank();
    }

    function testBorrowAndReturn() public {
        ERC721Facet nft = ERC721Facet(address(diamond));
        ERC721StakingFacet staking = ERC721StakingFacet(address(diamond));
        NFTBorrowingFacet borrowing = NFTBorrowingFacet(address(diamond));

        vm.prank(owner);
        uint256 tokenId = nft.mint(lender);

        vm.startPrank(lender);
        nft.approve(address(diamond), tokenId);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        uint256 duration = 1 days;
        vm.prank(borrower);
        borrowing.borrowNFT(tokenId, duration);
        
        assertEq(nft.ownerOf(tokenId), borrower, "NFT should be with the borrower now");
        assertTrue(borrowing.getBorrowInfo(tokenId).active, "Borrowing should be active");

        // --- IMPORTANT: Borrower must approve Diamond before returning it to the pool! ---
        vm.startPrank(borrower);
        nft.approve(address(diamond), tokenId);
        borrowing.returnNFT(tokenId);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(tokenId), address(diamond));
        assertFalse(borrowing.getBorrowInfo(tokenId).active);
    }
}
