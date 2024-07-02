// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NounSwapper} from "../src/NounSwapper.sol";
import {IERC721} from "../src/interfaces/IERC721.sol";

contract NounSwapperTest is Test {
    NounSwapper public swapper;

    /// sets up mainnet fork to test against nouns contracts
    string mainnetRPC = vm.envString("MAINNET_RPC_URL");
    uint256 fork = vm.createFork(mainnetRPC);

    /// fake addresses to test giving into the contract
    address public giver = address(1);
    address public nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    address public nounsTreasury = 0xb1a32FC9F9D8b2cf86C068Cae13108809547ef71;


    function setUp() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);
        swapper = new NounSwapper(nounsTreasury);

        // give giver some funding
        vm.deal(giver, 100 ether);

        /// transfer 10 nouns from treasury to "giver" address
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = IERC721(nounsToken).tokenOfOwnerByIndex(nounsTreasury, i);
            IERC721(nounsToken).safeTransferFrom(nounsTreasury, giver, tokenId);
        }

        /// transfer 10 nouns into the swapper contract
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = IERC721(nounsToken).tokenOfOwnerByIndex(nounsTreasury, i);
            IERC721(nounsToken).safeTransferFrom(nounsTreasury, address(swapper), tokenId);
        }
        vm.stopPrank();

        vm.startPrank(giver);
        /// set approval for the swapper contract to transfer the nouns from giver
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = IERC721(nounsToken).tokenOfOwnerByIndex(giver, i);
            IERC721(nounsToken).approve(address(swapper), tokenId);
        }
        vm.stopPrank();
    }

    function test_SwapNoun() public {
        vm.selectFork(fork);
        vm.startPrank(giver);
        uint256 givingTokenId = IERC721(nounsToken).tokenOfOwnerByIndex(giver, 0);
        uint256 receivingTokenId = IERC721(nounsToken).tokenOfOwnerByIndex(address(swapper), 0);

        swapper.swapNoun{value: 1 ether}(givingTokenId, receivingTokenId);
        assertEq(IERC721(nounsToken).ownerOf(givingTokenId), address(swapper));
        assertEq(IERC721(nounsToken).ownerOf(receivingTokenId), giver);
        vm.stopPrank();
    }

    function test_revokeTo() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);
        uint256 tokenId = IERC721(nounsToken).tokenOfOwnerByIndex(address(swapper), 0);
        swapper.revokeTo(giver, tokenId);
        assertEq(IERC721(nounsToken).ownerOf(tokenId), giver);
        vm.stopPrank();
    }

    function test_revoke() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);
        uint256 tokenId = IERC721(nounsToken).tokenOfOwnerByIndex(address(swapper), 0);
        swapper.revokeNoun(tokenId);
        assertEq(IERC721(nounsToken).ownerOf(tokenId), nounsTreasury);
        vm.stopPrank();
    }

    function test_revokeNouns() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenIds[i] = IERC721(nounsToken).tokenOfOwnerByIndex(address(swapper), i);
        }
        swapper.revokeNouns(tokenIds);
        for (uint256 i = 0; i < 10; i++) {
            assertEq(IERC721(nounsToken).ownerOf(tokenIds[i]), nounsTreasury);
        }
        vm.stopPrank();
    }

    function test_revokeNounsAll() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);

        /// get array of tokenIds that should be back to treasury
        uint256 balance = IERC721(nounsToken).balanceOf(address(swapper));
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = IERC721(nounsToken).tokenOfOwnerByIndex(address(swapper), i);
        }

        /// make sure the treasury has it's nouns back
        swapper.revokeNouns();
        for (uint256 i = 0; i < balance; i++) {
            assertEq(IERC721(nounsToken).ownerOf(tokenIds[i]), nounsTreasury);
        }

        /// make sure the swapper has no more nouns
        assertEq(IERC721(nounsToken).balanceOf(address(swapper)), 0);
        vm.stopPrank();
    }

    function test_cashout() public {
        vm.selectFork(fork);
        vm.startPrank(nounsTreasury);
        uint256 balance = address(swapper).balance;
        uint256 preCashoutBalance = address(nounsTreasury).balance;
        swapper.cashout();
        assertEq(address(swapper).balance, 0);
        assertEq(address(nounsTreasury).balance, balance + preCashoutBalance);
        vm.stopPrank();
    }
}
