// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IERC721.sol";

contract NounSwapper is Ownable, IERC721Receiver {
    // ------------------------------------
    // configs
    // ------------------------------------

    address public constant nounsTreasury = 0xb1a32FC9F9D8b2cf86C068Cae13108809547ef71;
    address public constant nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    uint256 public payment = 1 ether;

    event NounSwapped(uint256 givingTokenId, uint256 receivingTokenId);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    // ------------------------------------
    // swap function
    // ------------------------------------

    function swapNoun(uint256 givingTokenId, uint256 receivingTokenId) payable public {
        /// require that the noun is in custody
        require (IERC721(nounsToken).ownerOf(receivingTokenId) == address(this), "NounSwapper: Noun requested not custodied by swapper.");
        /// require owner owns the noun they are giving
        require (IERC721(nounsToken).ownerOf(givingTokenId) == msg.sender, "NounSwapper: Noun not owned by sender.");
        /// require that the owner has set approval on the noun they are giving
        require (IERC721(nounsToken).getApproved(givingTokenId) == address(this), "NounSwapper: Noun not approved for transfer.");
        /// require payment
        require (msg.value == payment, "NounSwapper: Payment not enough");

        /// transfer the noun
        IERC721(nounsToken).safeTransferFrom(msg.sender, address(this), givingTokenId);
        IERC721(nounsToken).safeTransferFrom(address(this), msg.sender, receivingTokenId);

        emit NounSwapped(givingTokenId, receivingTokenId);
    }

    // ------------------------------------
    // revoking functions
    // ------------------------------------

    function revokeTo(address receiver, uint256 tokenId) public onlyOwner {
        IERC721(nounsToken).safeTransferFrom(address(this), receiver, tokenId);
    }

    /// @dev treasury does not support safeTransferFrom
    function revokeToTreasury(uint256 tokenId) public onlyOwner {
        IERC721(nounsToken).transferFrom(address(this), nounsTreasury, tokenId);
    }

    function revokeNoun(uint256 tokenId) public onlyOwner {
        // lets the owner send a noun back to the treasury
        revokeToTreasury(tokenId);
    }

    function revokeNouns(uint256[] memory tokenIds) public onlyOwner {
        // lets the owner send a list of nouns back to the treasury
        for (uint256 i = 0; i < tokenIds.length; i++) {
            revokeToTreasury(tokenIds[i]);
        }
    }

    function revokeNouns() public onlyOwner {
        // lets the owner send all nouns back to the treasury
        uint256 balance = IERC721(nounsToken).balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = IERC721(nounsToken).tokenOfOwnerByIndex(address(this), i);
        }
        revokeNouns(tokenIds);
    }

    // ------------------------------------
    // cashout
    // ------------------------------------

    function cashout() public {
        // lets anyone cashout the contract's balance to the treasury
        nounsTreasury.call{ value: address(this).balance }('');
    }


    // ------------------------------------
    // receiver
    // ------------------------------------

    function onERC721Received(address, address, uint256, bytes memory) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
