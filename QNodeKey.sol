// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract QNodeKey is ERC721Drop, ReentrancyGuard {
    using Strings for uint256;
    uint256 public TOTAL_SUPPLY = 88888;
    uint256 public MAX_TIERS = 77;
    uint256 public maxPerWallet = 100;
    uint256 public currentTier = 1;
    uint256 public totalMinted = 0;
    uint256 public tierMinted = 0;
    string public baseURI;
    mapping(uint256 => uint256) public tierPrices;
    mapping(uint256 => uint256) public tierSizes;
    mapping(address => uint256) public walletMints;
    mapping(address => mapping(address => uint256)) public referralRewards; // Referrer => Token => Reward
    mapping(address => string) public userReferralCodes;
    mapping(string => address) public referralCodeToAddress;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => EnumerableSet.AddressSet) private referrerToReferees;
    mapping(address => uint256) public lastPurchaseBlock;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public tierMintCount;

    // Token and Price Feed addresses on ethereum
    address constant usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant wbtcToken = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    AggregatorV3Interface internal ethToUsdPriceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AggregatorV3Interface internal usdtToUsdPriceFeed =
        AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    AggregatorV3Interface internal usdcToUsdPriceFeed =
        AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    AggregatorV3Interface internal wbtcToEthPriceFeed =
        AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8); // WBTC/ETH

    event BaseImageURISet(string newBaseImageURI);
    event MaxPerWalletSet(uint256 newMaxPerWallet);
    event TotalSupplySet(uint256 newTotalSupply);
    event MaxTiersSet(uint256 newMaxTiers);
    event ReferralCodeRegistered(address user, string referralCode);
    event NodePurchased(
        address indexed buyer,
        uint256 quantity,
        address paymentToken,
        string referrerCode
    );
    event Withdrawn(address indexed owner, uint256 amount);
    event TokenWithdrawn(address indexed owner, address token, uint256 amount);

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
    }
    function initializeTiers(uint256[] memory sizes, uint256[] memory prices) external onlyOwner {
        require(sizes.length == prices.length, "Sizes and prices arrays must have the same length");
        for (uint256 i = 0; i < sizes.length; i++) {
            tierSizes[i + 1] = sizes[i];
            tierPrices[i + 1] = prices[i];
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Convert tokenId to a zero-padded string (e.g., 00001)
        string memory paddedTokenId = _toPaddedString(tokenId, 5);

        // Construct the full metadata URI
        return string(abi.encodePacked(baseURI, paddedTokenId, ".json"));
    }

    // Helper function to pad a number to a fixed number of digits (e.g., 5 digits)
    function _toPaddedString(uint256 value, uint256 digits) internal pure returns (string memory) {
        bytes memory buffer = new bytes(digits);
        for (uint256 i = digits; i > 0; --i) {
            buffer[i - 1] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        require(value == 0, "Value exceeds digit length");
        return string(buffer);
    }


    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        maxPerWallet = _newMax;
        emit MaxPerWalletSet(_newMax);
    }

    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        require(
            newTotalSupply >= totalMinted,
            "New total supply cannot be less than minted tokens"
        );
        TOTAL_SUPPLY = newTotalSupply;
        emit TotalSupplySet(newTotalSupply);
    }

    function setMaxTiers(
        uint256 newMaxTiers,
        uint256[] memory newTierPrices,
        uint256[] memory newTierSizes
    ) external onlyOwner {
        require(
            newMaxTiers >= currentTier,
            "New max tiers cannot be less than the current tier"
        );
        require(
            newTierPrices.length == newTierSizes.length,
            "Prices and sizes length mismatch"
        );
        require(
            newTierPrices.length <= newMaxTiers - MAX_TIERS,
            "Exceeds allowed new tiers"
        );

        MAX_TIERS = newMaxTiers;
        uint256 currentSize = MAX_TIERS - newTierPrices.length;
        for (uint256 i = 0; i < newTierPrices.length; i++) {
            uint256 tier = currentSize + i + 1; // New tiers start from the end of current MAX_TIERS
            tierPrices[tier] = newTierPrices[i];
            tierSizes[tier] = newTierSizes[i];
        }
        emit MaxTiersSet(newMaxTiers);
    }

    function generateReferralCode(
        address user
    ) public pure returns (string memory) {
        // A unique hash using keccak256
        bytes32 hash = keccak256(abi.encodePacked(user));
        return toHexString(hash);
    }
    function getTokenId() external view returns (uint256) {
        return totalMinted;
    }
    function getTierMintCount(uint256 tier) external view returns (uint256) {
        require(tier > 0 && tier <= MAX_TIERS, "Invalid tier");
        return tierMintCount[tier];
    }
    function registerReferralCode() public {
        require(
            bytes(userReferralCodes[msg.sender]).length == 0,
            "Referral code already registered"
        );
        string memory code = generateReferralCode(msg.sender);
        require(
            referralCodeToAddress[code] == address(0),
            "Referral code already in use"
        );
        userReferralCodes[msg.sender] = code;
        referralCodeToAddress[code] = msg.sender;
        emit ReferralCodeRegistered(msg.sender, code);
    }

    function toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64); // Bytes32 has 32 bytes, 64 hex characters
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(data[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    function getReferralRewards(
        address user,
        address token
    ) external view returns (uint256) {
        return referralRewards[user][token];
    }
    function buyNode(
        uint256 quantity,
        string memory referrerCode,
        address paymentToken
    ) external payable nonReentrant {
        require(quantity > 0, "Quantity cannot be zero");
        require(
            walletMints[msg.sender] + quantity <= maxPerWallet,
            "Exceeds max per wallet"
        );
        require(totalMinted + quantity <= TOTAL_SUPPLY, "Exceeds total supply");
        require(
            block.number > lastPurchaseBlock[msg.sender] + 6,
            "Double spending protection: Wait for 6 blocks"
        );
        uint256 totalPrice = 0; // Total price the buyer pays
        uint256 remainingQuantity = quantity; // Remaining quantity of nodes to mint
        uint256 totalReward = 0; // Total referral reward to pay the referrer
        address referrer; // Referrer address (if any)
        if (bytes(referrerCode).length > 0) {
            referrer = referralCodeToAddress[referrerCode];
            require(referrer != address(0), "Invalid referral code");
            require(referrer != msg.sender, "Cannot refer yourself");
            referrerToReferees[referrer].add(msg.sender);
            while (remainingQuantity > 0) {
                uint256 pricePerNode = getTokenPrice(paymentToken);
                uint256 rewardPercentage = (currentTier <= 13) ? 20 : 10;
                uint256 discountPerNode = (pricePerNode * 5) / 100; // 5% discount
                uint256 rewardPerNode = (pricePerNode * rewardPercentage) / 100; // Reward based on tier
                uint256 availableInCurrentTier = tierSizes[currentTier] -
                    tierMinted;

                if (remainingQuantity <= availableInCurrentTier) {
                    // Calculate discounted total price
                    totalPrice +=
                        (pricePerNode - discountPerNode) *
                        remainingQuantity;
                    // Calculate referral reward
                    totalReward += rewardPerNode * remainingQuantity;
                    // Update tier
                    tierMinted += remainingQuantity;
                    remainingQuantity = 0;
                } else {
                    // Handle nodes in the current tier
                    totalPrice +=
                        (pricePerNode - discountPerNode) *
                        availableInCurrentTier;
                    totalReward += rewardPerNode * availableInCurrentTier;
                    totalMinted += availableInCurrentTier;
                    remainingQuantity -= availableInCurrentTier;
                    _advanceTier();
                }
            }
        } else {
            // No referral code, no discount or reward
            while (remainingQuantity > 0) {
                uint256 pricePerNode = getTokenPrice(paymentToken);

                uint256 availableInCurrentTier = tierSizes[currentTier] -
                    tierMinted;

                if (remainingQuantity <= availableInCurrentTier) {
                    totalPrice += pricePerNode * remainingQuantity;
                    tierMinted += remainingQuantity;
                    remainingQuantity = 0;
                } else {
                    totalPrice += pricePerNode * availableInCurrentTier;
                    remainingQuantity -= availableInCurrentTier;
                    _advanceTier();
                }
            }
        }
        walletMints[msg.sender] += quantity;
        totalMinted += quantity;
        lastPurchaseBlock[msg.sender] = block.number;

        // Handle payment
        if (paymentToken == address(0)) {
            // ETH Payment
            require(msg.value >= totalPrice, "Insufficient ETH funds");
            // Refund excess ETH
            if (msg.value > totalPrice) {
                (bool refundSuccess, ) = msg.sender.call{
                    value: msg.value - totalPrice
                }("");
                require(refundSuccess, "ETH refund failed");
            }

            // Pay referral reward (if any)
            if (totalReward > 0 && referrer != address(0)) {
                (bool success, ) = referrer.call{value: totalReward}("");
                require(success, "ETH reward transfer failed");
            }
        } else {
            // ERC20 Payment
            IERC20 token = IERC20(paymentToken);
            require(
                token.allowance(msg.sender, address(this)) >= totalPrice,
                "Insufficient token allowance"
            );
            require(
                token.transferFrom(msg.sender, address(this), totalPrice),
                "Token transfer failed"
            );

            // Pay referral reward (if any)
            if (totalReward > 0 && referrer != address(0)) {
                require(
                    token.balanceOf(address(this)) >= totalReward,
                    "Insufficient token balance for reward"
                );
                require(
                    token.transfer(referrer, totalReward),
                    "Token reward transfer failed"
                );
            }
        }

        _transferTokensOnClaim(msg.sender, quantity); // Mint the NFTs
        walletMints[msg.sender] += quantity;
        lastPurchaseBlock[msg.sender] = block.number;
        emit NodePurchased(msg.sender, quantity, paymentToken, referrerCode);
    }

    function getReferees(
        address referrer
    ) external view returns (address[] memory) {
        return referrerToReferees[referrer].values();
    }

    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal virtual override returns (uint256 startTokenId) {
        startTokenId = totalMinted; // Starting token ID for this batch
        totalMinted += _quantityBeingClaimed; // Update total minted count

        // Mint the NFTs
        _safeMint(_to, _quantityBeingClaimed);
        tierMintCount[currentTier] += _quantityBeingClaimed;
    }


    function getTokenPrice(
        address token
    ) public view returns (uint256 pricePerNodeInToken) {
        uint256 pricePerNodeInEth = tierPrices[currentTier];

        (, int256 ethToUsd, , , ) = ethToUsdPriceFeed.latestRoundData();
        require(ethToUsd > 0, "Invalid ETH/USD price");

        uint256 pricePerNodeInUsd = (uint256(ethToUsd) * pricePerNodeInEth) /
            1e8;

        if (token == address(0)) {
            return pricePerNodeInEth;
        } else if (token == usdtToken) {
            (, int256 usdtToUsd, , , ) = usdtToUsdPriceFeed.latestRoundData();
            require(usdtToUsd > 0, "Invalid USDT/USD price");
            pricePerNodeInToken =
                (pricePerNodeInUsd * 1e6) /
                uint256(usdtToUsd);
            pricePerNodeInToken = pricePerNodeInToken / 1e10;
        } else if (token == usdcToken) {
            (, int256 usdcToUsd, , , ) = usdcToUsdPriceFeed.latestRoundData();
            require(usdcToUsd > 0, "Invalid USDC/USD price");
            pricePerNodeInToken =
                (pricePerNodeInUsd * 1e6) /
                uint256(usdcToUsd);
            pricePerNodeInToken = pricePerNodeInToken / 1e10;
        } else if (token == wbtcToken) {
            // WBTC Payment
            (, int256 wbtcEth, , , ) = wbtcToEthPriceFeed.latestRoundData();
            require(wbtcEth > 0, "Invalid WBTC/ETH price");

            uint256 pricePerNodeInEth = tierPrices[currentTier];
            pricePerNodeInToken = (pricePerNodeInEth * 1e8) / uint256(wbtcEth);
            pricePerNodeInToken=pricePerNodeInToken * 1e18;
        } else {
            revert("Unsupported token");
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(msg.sender, balance);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "No token balance to withdraw");
        require(balance > 0, "No token balance to withdraw");
        require(erc20.transfer(msg.sender, balance), "Token transfer failed");
        emit TokenWithdrawn(msg.sender, token, balance);
    }

    function _advanceTier() internal {
        require(currentTier < MAX_TIERS, "All tiers completed");
        currentTier += 1;
        tierMinted = 0;
    }
}