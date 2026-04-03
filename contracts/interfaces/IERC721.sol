// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    function initializeNFT(string memory _name, string memory _symbol) external;
    function mint(address _to) external returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function approve(address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferNFT(address _from, address _to, uint256 _tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
