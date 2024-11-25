// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SolarNFT is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TokenMetadata {
        uint256 stakePercentage;
        string imageUrl;
    }

    EnumerableSet.AddressSet private frozenAccounts;
    mapping(uint256 => bool) private frozenTokens;
    mapping(uint256 => TokenMetadata) private tokenMetadata;
    uint256 private _tokenIdCounter;
    uint256 public projectStartTime;
    uint256 public burnPeriod;

    event Mint(address indexed to, uint256 indexed tokenId, uint256 stakePercentage, string imageUrl);
    event Burn(address indexed from, uint256 indexed tokenId);
    event FreezeAccount(address indexed account);
    event UnfreezeAccount(address indexed account);
    event FreezeToken(uint256 indexed tokenId);
    event UnfreezeToken(uint256 indexed tokenId);

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 burnPeriodInYears
    ) ERC721(name, symbol) Ownable(initialOwner) {
        projectStartTime = block.timestamp;
        burnPeriod = burnPeriodInYears * 365 days;
    }

    function mint(address to, uint256 stakePercentage, string memory imageUrl) external onlyOwner {
        require(stakePercentage > 0 && stakePercentage <= 100, "Invalid stake percentage");
        uint256 tokenId = _tokenIdCounter++;
        tokenMetadata[tokenId] = TokenMetadata(stakePercentage, imageUrl);
        _mint(to, tokenId);
        emit Mint(to, tokenId, stakePercentage, imageUrl);

        // Automatically freeze the token
        freezeToken(tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
        delete tokenMetadata[tokenId];
        emit Burn(_msgSender(), tokenId);
    }

    function freezeAccount(address account) public onlyOwner {
        frozenAccounts.add(account);
        emit FreezeAccount(account);
    }

    function unfreezeAccount(address account) public onlyOwner {
        frozenAccounts.remove(account);
        emit UnfreezeAccount(account);
    }

    function freezeToken(uint256 tokenId) public onlyOwner {
        frozenTokens[tokenId] = true;
        emit FreezeToken(tokenId);
    }

    function unfreezeToken(uint256 tokenId) public onlyOwner {
        frozenTokens[tokenId] = false;
        emit UnfreezeToken(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(!frozenAccounts.contains(from), "Sender account is frozen");
        require(!frozenAccounts.contains(to), "Receiver account is frozen");
        require(!frozenTokens[tokenId], "Token is frozen");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(!frozenAccounts.contains(from), "Sender account is frozen");
        require(!frozenAccounts.contains(to), "Receiver account is frozen");
        require(!frozenTokens[tokenId], "Token is frozen");
        require(from == address(0), "NFTs are non-transferable"); // Ensures NFTs are non-transferable post-minting
        super.transferFrom(from, to, tokenId);
    }

    function getStakePercentage(uint256 tokenId) external view returns (uint256) {
        return tokenMetadata[tokenId].stakePercentage;
    }

    function getImageUrl(uint256 tokenId) external view returns (string memory) {
        return tokenMetadata[tokenId].imageUrl;
    }

    function burnAllNFTs() external onlyOwner {
        require(block.timestamp >= projectStartTime + burnPeriod, "Burn period has not yet elapsed");
        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (_exists(i)) {
                _burn(i);
                delete tokenMetadata[i];
                emit Burn(ownerOf(i), i);
            }
        }
    }
}
