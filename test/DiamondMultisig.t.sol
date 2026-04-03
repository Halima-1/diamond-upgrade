// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/DiamondMultisig.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract DiamondMultisigTest is Test, DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    DiamondMultisigFacet dMultisig;
    ERC721Facet erc721F;

    address owner = address(0xABC);
    address signer1 = address(0x1);
    address signer2 = address(0x2);
    address user1 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));
        
        dMultisig = new DiamondMultisigFacet();
        dLoupe = new DiamondLoupeFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        
        bytes4[] memory multisigSelectors = new bytes4[](5);
        multisigSelectors[0] = DiamondMultisigFacet.initializeGov.selector;
        multisigSelectors[1] = DiamondMultisigFacet.proposeUpgrade.selector;
        multisigSelectors[2] = DiamondMultisigFacet.approveUpgrade.selector;
        multisigSelectors[3] = DiamondMultisigFacet.getSigners.selector;
        multisigSelectors[4] = DiamondMultisigFacet.getProposalStatus.selector;
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(dMultisig),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: multisigSelectors
        });

        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(dLoupe),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;
        DiamondMultisigFacet(address(diamond)).initializeGov(signers, 2);
        
        vm.stopPrank();
    }

    function testGovernanceUpgrade() public {
        erc721F = new ERC721Facet();
        
        bytes4[] memory erc721Selectors = new bytes4[](8);
        erc721Selectors[0] = bytes4(keccak256("initializeNFT(string,string)"));
        erc721Selectors[1] = bytes4(keccak256("mint(address)"));
        erc721Selectors[2] = erc721F.name.selector;
        erc721Selectors[3] = erc721F.symbol.selector;
        erc721Selectors[4] = erc721F.balanceOf.selector;
        erc721Selectors[5] = erc721F.ownerOf.selector;
        erc721Selectors[6] = erc721F.tokenURI.selector;
        erc721Selectors[7] = erc721F.transferNFT.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721F),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: erc721Selectors
        });

        vm.prank(signer1);
        uint256 pId = DiamondMultisigFacet(address(diamond)).proposeUpgrade(cuts, address(0), "");

        (uint256 approvals, bool executed, ) = DiamondMultisigFacet(address(diamond)).getProposalStatus(pId);
        assertEq(approvals, 1);
        assertFalse(executed);

        vm.prank(signer2);
        DiamondMultisigFacet(address(diamond)).approveUpgrade(pId);

        ERC721Facet nft = ERC721Facet(address(diamond));
        vm.prank(signer1);
        nft.initializeNFT("DAO NFT", "DNFT");
        
        uint256 id = nft.mint(user1);
        assertEq(nft.ownerOf(id), user1);
        console.log("Upgrade Executed via MultiSig Successfully!");
        console.log("NFT Metadata URL:");
        console.log(nft.tokenURI(id));
    }
}
