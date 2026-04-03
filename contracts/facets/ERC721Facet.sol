// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract ERC721Facet {
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId);

    error BalanceQueryZeroAddress();
    error OwnerQueryNonexistentToken();
    error ApproveCallerNotOwnerNorApproved();
    error ApprovedQueryNonexistentToken();
    error TransferNotOwner();
    error TransferToZeroAddress();
    error TransferCallerNotOwnerNorApproved();

    function initializeNFT(string memory _name, string memory _symbol) external {
        AppStorage storage s = LibAppStorage.appStorage();
        s.nftName = _name;
        s.nftSymbol = _symbol;
    }

    function mint(address _to) external returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 tokenId = s.nextTokenId++;
        
        s.nftOwners[tokenId] = _to;
        s.nftBalances[_to] += 1;

        emit Transfer(address(0), _to, tokenId);
        emit NFTMinted(_to, tokenId);
        return tokenId;
    }

    function name() public view returns (string memory) {
        return LibAppStorage.appStorage().nftName;
    }

    function symbol() public view returns (string memory) {
        return LibAppStorage.appStorage().nftSymbol;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert BalanceQueryZeroAddress();
        return LibAppStorage.appStorage().nftBalances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = LibAppStorage.appStorage().nftOwners[_tokenId];
        if (owner == address(0)) revert OwnerQueryNonexistentToken();
        return owner;
    }

    function approve(address _to, uint256 _tokenId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.nftOwners[_tokenId];

        if (!(msg.sender == owner || s.nftOperatorApprovals[owner][msg.sender])) {
            revert ApproveCallerNotOwnerNorApproved();
        }
        
        s.nftTokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        if (LibAppStorage.appStorage().nftOwners[_tokenId] == address(0)) {
            revert ApprovedQueryNonexistentToken();
        }
        return LibAppStorage.appStorage().nftTokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        AppStorage storage s = LibAppStorage.appStorage();
        s.nftOperatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return LibAppStorage.appStorage().nftOperatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _transfer(_from, _to, _tokenId);
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) external {
        _transfer(_from, _to, _tokenId);
        emit NFTTransferred(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.nftOwners[_tokenId];

        if (owner != _from) revert TransferNotOwner();
        if (_to == address(0)) revert TransferToZeroAddress();
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert TransferCallerNotOwnerNorApproved();
        }

        delete s.nftTokenApprovals[_tokenId];

        s.nftBalances[_from] -= 1;
        s.nftBalances[_to] += 1;
        s.nftOwners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.nftOwners[tokenId];
        return (spender == owner || s.nftTokenApprovals[tokenId] == spender || s.nftOperatorApprovals[owner][spender]);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        address owner = ownerOf(tokenId);
        string memory ownerAddr = Strings.toHexString(uint160(owner), 20);
        string memory shortOwner = string(abi.encodePacked(
            _substring(ownerAddr, 0, 6), "...", _substring(ownerAddr, 38, 42)
        ));

        string memory nftName = LibAppStorage.appStorage().nftName;
        string memory nftSymbol = LibAppStorage.appStorage().nftSymbol;

        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">',
            '<defs>',
            '<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0f172a"/><stop offset="1" stop-color="#020617"/></linearGradient>',
            '<linearGradient id="d" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22d3ee"/><stop offset="1" stop-color="#0891b2"/></linearGradient>',
            '</defs>',
            '<rect width="300" height="300" fill="url(#g)" rx="10"/>',
            '<rect x="10" y="10" width="280" height="280" fill="none" stroke="#22d3ee" stroke-width="1" stroke-opacity="0.2" rx="8"/>',
            '<text x="50%" y="40" text-anchor="middle" fill="#22d3ee" font-family="Arial" font-size="20" font-weight="900" style="text-transform:uppercase; letter-spacing: 2px;">', nftName, '</text>',
            '<text x="50%" y="60" text-anchor="middle" fill="white" font-family="Arial" font-size="12" font-weight="200" font-style="italic">My first diamond contract NFT</text>',
            '<g transform="translate(150, 145) scale(0.55)">',
            '<path d="M0 -150 L100 -50 L0 150 L-100 -50 Z" fill="url(#d)" fill-opacity="0.8" stroke="white" stroke-width="2">',
            '<animate attributeName="fill-opacity" values="0.6;0.9;0.6" dur="3s" repeatCount="indefinite"/>',
            '</path>',
            '<path d="M0 -150 L-100 -50 L100 -50 Z" fill="white" fill-opacity="0.3"/>',
            '</g>',
            '<text x="25" y="270" text-anchor="start" fill="white" font-family="Arial" font-size="14" font-weight="bold">', nftSymbol, ' #', tokenId.toString(), '</text>',
            '<text x="275" y="270" text-anchor="end" fill="#94a3b8" font-family="monospace" font-size="10">Owned by: ', shortOwner, '</text>',
            '</svg>'
        ));

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "', nftName, ' #', tokenId.toString(), '", "description": "My first diamond contract NFT", "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(svg)), '"}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}