// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SolarNFT1 is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TokenMetadata {
        string imageUrl;
        uint256 kilowattAmount;
    }

    EnumerableSet.AddressSet private frozenAccounts;
    mapping(uint256 => bool) private frozenTokens;
    mapping(uint256 => TokenMetadata) private tokenMetadata;
    mapping(address => uint256[]) private userOwnedTokenIds; // Mapping to store token IDs owned by each address
    mapping(address => uint256) private userKilowattBalance; // Mapping to store kilowatts owned by each address
    uint256 private _tokenIdCounter;
    uint256 public projectStartTime;
    uint256 public maxKilowatts;
    uint256 public burnPeriod; // The burn period duration
    uint256 public burnPeriodStartTime; // When the burn period starts
    bool public burnPeriodStarted = false;

    event Mint(address indexed to, uint256 indexed tokenId, string imageUrl, uint256 kilowattAmount);
    event Burn(address indexed from, uint256 indexed tokenId);
    event FreezeAccount(address indexed account);
    event UnfreezeAccount(address indexed account);
    event FreezeToken(uint256 indexed tokenId);
    event UnfreezeToken(uint256 indexed tokenId);
    event BurnPeriodStarted(uint256 startTime);

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 totalKilowatts,
        uint256 burnPeriodInYears
    ) ERC721(name, symbol) Ownable(initialOwner) {
        projectStartTime = block.timestamp;
        maxKilowatts = totalKilowatts;
        burnPeriod = burnPeriodInYears * 365 days;
    }

    // Allows the owner to start the burn period manually
    function startBurnPeriod() external onlyOwner {
        require(!burnPeriodStarted, "Burn period already started");
        burnPeriodStartTime = block.timestamp;
        burnPeriodStarted = true;
        emit BurnPeriodStarted(burnPeriodStartTime);
    }

    function mint(address to, uint256 kilowatts, string memory imageUrl) external onlyOwner {
        require(kilowatts > 0 && kilowatts <= maxKilowatts - _tokenIdCounter, "Invalid kilowatt amount or exceeds project limit");
        for (uint256 i = 0; i < kilowatts; i++) {
            uint256 tokenId = _tokenIdCounter++;
            tokenMetadata[tokenId] = TokenMetadata(imageUrl, kilowatts);
            _mint(to, tokenId);
            emit Mint(to, tokenId, imageUrl, kilowatts);

            // Automatically freeze the token
            freezeToken(tokenId);

            // Store user-owned token IDs and kilowatts
            userOwnedTokenIds[to].push(tokenId);
            userKilowattBalance[to] += 1; // Each token represents 1 kilowatt
        }
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        address tokenOwner = ownerOf(tokenId);
        _burn(tokenId);

        // Update the metadata and remove the kilowatt from the user's balance
        delete tokenMetadata[tokenId];
        removeUserTokenId(tokenOwner, tokenId);
        userKilowattBalance[tokenOwner] -= 1;

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

    function getImageUrl(uint256 tokenId) external view returns (string memory) {
        return tokenMetadata[tokenId].imageUrl;
    }

    // Burn all NFTs after the burn period has elapsed
    function burnAllNFTs() external onlyOwner {
        require(burnPeriodStarted, "Burn period has not started");
        require(block.timestamp >= burnPeriodStartTime + burnPeriod, "Burn period has not yet elapsed");

        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (_exists(i)) {
                _burn(i);
                delete tokenMetadata[i];
                emit Burn(ownerOf(i), i);
            }
        }
    }

    // Function to return the information about users that hold NFTs
    function getUserNFTInfo(address user) external view returns (uint256[] memory tokenIds, uint256 totalKilowatts) {
        return (userOwnedTokenIds[user], userKilowattBalance[user]);
    }

    // Internal helper function to remove a token ID from the user's list when burned
    function removeUserTokenId(address user, uint256 tokenId) internal {
        uint256[] storage tokens = userOwnedTokenIds[user];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }
}
