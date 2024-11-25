// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract QNFTDrop is ERC721Drop {
    uint256 public constant TOTAL_SUPPLY = 10;
    uint256 public constant MAX_TIERS = 4;
    uint256 public tierSize = 3;
    uint256 public maxPerWallet = 2;
    uint256 public currentTier = 1;
    uint256 public totalMinted = 0;
    uint256 public tierMinted = 0;

    string private baseURI;
    mapping(uint256 => uint256) public tierPrices;
    mapping(address => uint256) public walletMints;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        string memory _baseURI
    ) 
        ERC721Drop(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        ) 
    {
        baseURI = _baseURI;

        for (uint256 i = 1; i <= MAX_TIERS; i++) {
            tierPrices[i] = i * 0.01 ether;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        maxPerWallet = _newMax;
    }

    function setTierPrice(uint256 tier, uint256 price) external onlyOwner {
        require(tier > 0 && tier <= MAX_TIERS, "Invalid tier");
        tierPrices[tier] = price;
    }

    function claim(uint256 quantity) public payable {
        require(quantity > 0, "Quantity cannot be zero");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "Exceeds max per wallet");
        require(totalMinted + quantity <= TOTAL_SUPPLY, "Exceeds total supply");
        require(msg.value >= tierPrices[currentTier] * quantity, "Insufficient ETH sent");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalMinted + 1;
            _mint(msg.sender, tokenId);
            totalMinted++;
            tierMinted++;
        }

        walletMints[msg.sender] += quantity;

        if (tierMinted >= tierSize) {
            tierMinted = 0;
            if (currentTier < MAX_TIERS) {
                currentTier++;
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}