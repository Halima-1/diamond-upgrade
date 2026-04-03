// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC721StakingFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract NFTStakingTest is Test, DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    ERC721Facet erc721F;
    ERC721StakingFacet stakingF;

    address owner = address(0xABC);
    address staker = address(0x1);

    function setUp() public {
        vm.startPrank(owner);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        
        erc721F = new ERC721Facet();
        stakingF = new ERC721StakingFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        
        bytes4[] memory nftSelectors = new bytes4[](5);
        nftSelectors[0] = ERC721Facet.mint.selector;
        nftSelectors[1] = ERC721Facet.ownerOf.selector;
        nftSelectors[2] = ERC721Facet.initializeNFT.selector;
        nftSelectors[3] = ERC721Facet.transferFrom.selector;
        nftSelectors[4] = ERC721Facet.approve.selector;

        bytes4[] memory stakingSelectors = new bytes4[](3);
        stakingSelectors[0] = ERC721StakingFacet.stakeNFT.selector;
        stakingSelectors[1] = ERC721StakingFacet.unstakeNFT.selector;
        stakingSelectors[2] = ERC721StakingFacet.getStakingInfo.selector;

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

        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");
        ERC721Facet(address(diamond)).initializeNFT("Staking NFT", "SNFT");
        vm.stopPrank();
    }

    function testStakeAndUnstake() public {
        ERC721Facet nft = ERC721Facet(address(diamond));
        ERC721StakingFacet staking = ERC721StakingFacet(address(diamond));

        vm.prank(owner);
        uint256 tokenId = nft.mint(staker);

        // --- IMPORTANT: User must approve the Diamond before staking! ---
        vm.startPrank(staker);
        nft.approve(address(diamond), tokenId);
        staking.stakeNFT(tokenId);
        
        assertEq(nft.ownerOf(tokenId), address(diamond));
        assertTrue(staking.getStakingInfo(tokenId).active);

        staking.unstakeNFT(tokenId);
        assertEq(nft.ownerOf(tokenId), staker);
        vm.stopPrank();
    }
}
