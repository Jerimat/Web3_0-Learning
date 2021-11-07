// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    //URIs mapping
    mapping(uint256 => string) private _URIs;

    constructor(string memory name, string memory symbol)  ERC721(name, symbol) {

    }

    function safeMint(address to, string memory uri) public returns (uint256) {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());

        // Base URI for NFTs must end with /
        _URIs[_tokenIdCounter.current()] = uri;

        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return _URIs[tokenID];
    }

}
