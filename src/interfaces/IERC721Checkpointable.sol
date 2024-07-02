// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Interface for interacting with the Nouns ERC721 governance token with minimal deployment bytecode overhead
interface IERC721Checkpointable {
    /// @notice The address owning a given tokenId
    function ownerOf(uint256 tokenId) external view returns (address);
}
