// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTContract is ERC721 {
    uint256 public nextTokenId;
    address public admin;
    mapping(uint256 => uint256) public prices;

    constructor() ERC721('NFTContract', 'NFTC') Ownable(initialOwner) {
        admin = msg.sender;
    }

    function mint(address to, uint256 price) external {
        require(msg.sender == admin, "only admin");
        prices[nextTokenId] = price;
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }

    function getPrice(uint256 tokenId) external view returns (uint256) {
        return prices[tokenId];
    }
}
