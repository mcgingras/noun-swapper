// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/// this contract will custody nouns.
/// the owner of the contract can send the nouns out and do whatever else on the nouns.
/// everyone else can send in a noun, and get back out a noun that is custodied by this contract.
contract NounSwapper is Ownable {
    constructor(address _initialOwner) Ownable(_initialOwner) {
        // nothing else?
    }

    function swapNoun() public {
        // do something
    }
}
