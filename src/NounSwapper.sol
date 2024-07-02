// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Checkpointable.sol";

contract NounSwapper is Ownable {
    /// Nouns contract addresses
    address public nounsTreasury = 0xb1a32FC9F9D8b2cf86C068Cae13108809547ef71;
    address public nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    uint256 public payment = 1 ether;

    constructor(address _initialOwner) Ownable(_initialOwner) {
        // nothing else?
    }

    function swapNoun(uint256 givingTokenId, uint256 receivingTokenId) payable public {
        /// require that the noun is in custody
        require (IERC721Checkpointable(nounsToken).ownerOf(receivingTokenId) == address(this), "NounSwapper: Noun not in custody");
        /// this might fail on transfer anyways?
        require (IERC721Checkpointable(nounsToken).ownerOf(givingTokenId) == msg.sender, "NounSwapper: Noun not owned by sender");
        /// require payment
        require (msg.value >= payment, "NounSwapper: Payment not enough");

        /// transfer the noun
        IERC721Checkpointable(nounsToken).transferFrom(msg.sender, address(this), givingTokenId);
        IERC721Checkpointable(nounsToken).transferFrom(address(this), msg.sender, receivingTokenId);
    }

    // ------------------------------------
    // revoking functions
    // ------------------------------------

    function revokeTo(address receiver, uint256 tokenId) public onlyOwner {
        IERC721Checkpointable(nounsToken).transferFrom(address(this), receiver, tokenId);
    }

    function revokeNoun(uint256 tokenId) public onlyOwner {
        // lets the owner send a noun back to the treasury
        revokeTo(nounsTreasury, tokenId);
    }

    function revokeNouns(uint256[] calldata tokenIds) public onlyOwner {
        // lets the owner send a list of nouns back to the treasury
        for (uint256 i = 0; i < tokenIds.length; i++) {
            revokeTo(nounsTreasury, tokenIds[i]);
        }
    }

    function revokeNouns() public onlyOwner {
        // lets the owner send all nouns back to the treasury
        uint256 balance = IERC721Checkpointable(nounsToken).balanceOf(address(this));
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = IERC721Checkpointable(nounsToken).tokenOfOwnerByIndex(address(this), i);
        }
        revokeNouns(tokenIds);
    }

    // ------------------------------------
    // cashout
    // ------------------------------------

    function cashout() public {
        // lets anyone cashout the contract's balance to the treasury
        payable(nounsTreasury).transfer(address(this).balance);
    }
}
