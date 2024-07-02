// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Interface for interacting with the Nouns ERC721 governance token with minimal deployment bytecode overhead
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function approve(address to, uint256 tokenId) external;
}
