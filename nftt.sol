// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract nftt is ERC721, Ownable {
    
    uint256 public maxSupply = 88888;
    uint256 public totalTiers = 77;
    uint256 public maxPerWallet = 10;
    uint256 public currentTier = 1;
    uint256 public totalMinted = 0;
    uint256 public tierMinted = 0;
    uint256 public tierSize = 1000;

    string private baseURI;
    mapping(uint256 => uint256) public tierPrices;
    mapping(address => uint256) public walletMints;

    constructor(string memory _baseURI, address initialOwner) ERC721("MyTieredNFT", "MTNFT") Ownable(initialOwner) {
        baseURI = _baseURI;
        transferOwnership(initialOwner);
        for (uint256 i = 1; i <= totalTiers; i++) {
            tierPrices[i] = i * 0.01 ether;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxPerWallet(uint256 newLimit) external onlyOwner {
        maxPerWallet = newLimit;
    }

    function updateTier(uint256 tier, uint256 newTierSize, uint256 newPrice) external onlyOwner {
        require(tier > 0 && tier <= totalTiers, "Invalid tier");
        tierSize = newTierSize;
        tierPrices[tier] = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalMinted, "New supply must be >= total minted");
        maxSupply = newMaxSupply;
    }

    function setTotalTiers(uint256 newTotalTiers) external onlyOwner {
        require(newTotalTiers >= currentTier, "New tier count must be >= current tier");
        totalTiers = newTotalTiers;
    }

    function claim(uint256 quantity, uint256[] memory tokenIds) public payable {
        require(quantity == tokenIds.length, "Quantity and tokenIds length mismatch");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "Exceeds max NFTs per wallet");
        require(totalMinted + quantity <= maxSupply, "Exceeds max supply");
        require(msg.value >= tierPrices[currentTier] * quantity, "Insufficient ETH for current tier");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_exists(tokenId), "Token already minted");
            _mint(msg.sender, tokenId);
            totalMinted++;
            tierMinted++;
        }

        walletMints[msg.sender] += quantity;

        if (tierMinted >= tierSize) {
            currentTier++;
            tierMinted = 0;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
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
