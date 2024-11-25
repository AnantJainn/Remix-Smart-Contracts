// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QNFTDrop is ERC721, Ownable {
    uint256 public constant TOTAL_SUPPLY = 10;        // Total NFT supply
    uint256 public constant MAX_PER_WALLET = 2;         // Max NFTs per wallet
    uint256 public constant TIER_SIZE = 4;            // NFTs per tier
    uint256 public currentTier = 1;                      // Current tier, starts at 1
    uint256 public totalMinted = 0;                      // Total NFTs minted so far
    uint256 public tierMinted = 0;                       // NFTs minted in the current tier

    string private baseURI;                              // Base URI for metadata storage
    mapping(uint256 => uint256) public tierPrices;       // Mapping of tier to its price
    mapping(address => uint256) public walletMints;      // Tracking wallet mints to enforce MAX_PER_WALLET

    constructor(string memory _baseURI, address initialOwner) ERC721("QuraniumNFT", "QNFT") Ownable(initialOwner)  {
        baseURI = _baseURI;                              // Set the IPFS base URI

        // Initialize prices per tier (e.g., 0.01 ETH for Tier 1, 0.02 ETH for Tier 2)
        for (uint256 i = 1; i <= 77; i++) {
            tierPrices[i] = i * 0.01 ether;
        }
    }

    // Function to update the base URI in case metadata location changes (onlyOwner)
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // Override _baseURI to return our stored baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Function to claim NFTs by specifying quantity and token IDs
    function claim(uint256 quantity, uint256[] memory tokenIds) public payable {
        require(quantity == tokenIds.length, "Quantity and tokenIds length mismatch");
        require(walletMints[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds max NFTs per wallet");
        require(totalMinted + quantity <= TOTAL_SUPPLY, "Exceeds total supply");
        require(msg.value >= tierPrices[currentTier] * quantity, "Insufficient ETH for current tier");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];
            require(!ERC721._exists(tokenId), "Token already minted"); // Check if token ID is already minted
            _mint(msg.sender, tokenId);                          // Mint the NFT to the caller
            totalMinted++;                                       // Increment total minted
            tierMinted++;                                        // Increment current tier minted
        }

        walletMints[msg.sender] += quantity; // Track the number of NFTs claimed by wallet

        // Check if current tier is complete and needs progression
        if (tierMinted >= TIER_SIZE) {
            currentTier++;
            tierMinted = 0;
        }
    }

    // Override tokenURI to use base URI + token ID for metadata location
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ERC721._exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    // Helper function to convert uint to string (for constructing token URI)
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}