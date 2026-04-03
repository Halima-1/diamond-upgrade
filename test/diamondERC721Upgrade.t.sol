// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract DiamondERC721Test is Test, DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;

    address owner = address(0xABC);
    address user1 = address(0x123);
    address user2 = address(0x456);

    function setUp() public {
        vm.startPrank(owner);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        
        address[] memory addAddrs = new address[](2);
        addAddrs[0] = address(dLoupe);
        addAddrs[1] = address(ownerF);
        
        string[] memory names = new string[](2);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        
        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addAddrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        erc721F = new ERC721Facet();
        
        // Back to 8 selectors
        bytes4[] memory erc721Selectors = new bytes4[](8);
        erc721Selectors[0] = bytes4(keccak256("initializeNFT(string,string)"));
        erc721Selectors[1] = bytes4(keccak256("mint(address)"));
        erc721Selectors[2] = bytes4(keccak256("name()"));
        erc721Selectors[3] = bytes4(keccak256("symbol()"));
        erc721Selectors[4] = bytes4(keccak256("balanceOf(address)"));
        erc721Selectors[5] = bytes4(keccak256("ownerOf(uint256)"));
        erc721Selectors[6] = bytes4(keccak256("tokenURI(uint256)"));
        erc721Selectors[7] = bytes4(keccak256("transferNFT(address,address,uint256)"));

        IDiamondCut.FacetCut[] memory erc721Cuts = new IDiamondCut.FacetCut[](1);
        erc721Cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721F),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: erc721Selectors
        });
        
        executeDiamondCut(IDiamondCut(address(diamond)), erc721Cuts, address(0), "");
        
        ERC721Facet(address(diamond)).initializeNFT("LYMARH NFT", "LNFT");
        vm.stopPrank();
    }

    function testTransferNFT() public {
        ERC721Facet nft = ERC721Facet(address(diamond));
        vm.prank(owner);
        uint256 id = nft.mint(user1);

        vm.prank(user1);
        nft.transferNFT(user1, user2, id);
        
        assertEq(nft.ownerOf(id), user2);
    }
}
