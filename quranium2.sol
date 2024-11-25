// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QNodeKey is ERC721Drop {
    uint256 public TOTAL_SUPPLY = 88888; // Total NFTs across all tiers
    uint256 public MAX_TIERS = 77;
    uint256 public maxPerWallet = 10;
    uint256 public currentTier = 1;
    uint256 public totalMinted = 0;
    uint256 public tierMinted = 0;

    string public baseURI;
    mapping(uint256 => uint256) public tierPrices;
    mapping(uint256 => uint256) public tierSizes;
    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public referralRewards;
    mapping(address => string) public userReferralCodes;
    mapping(string => address) public referralCodeToAddress;

    // Token and Price Feed addresses on Arbitrum
    address constant usdtToken = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant usdcToken = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant wbtcToken = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    AggregatorV3Interface internal ethToUsdPriceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    AggregatorV3Interface internal usdtToUsdPriceFeed = AggregatorV3Interface(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    AggregatorV3Interface internal usdcToUsdPriceFeed = AggregatorV3Interface(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    AggregatorV3Interface internal wbtcToUsdPriceFeed = AggregatorV3Interface(0xd0C7101eACbB49F3deCcCc166d238410D6D46d57);

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

        // Initialize tier prices and sizes
    tierSizes[1] = 5000; tierPrices[1] = 0.07 ether;
    tierSizes[2] = 5000; tierPrices[2] = 0.0875 ether;
    tierSizes[3] = 4750; tierPrices[3] = 0.1094 ether;
    tierSizes[4] = 4500; tierPrices[4] = 0.1367 ether;
    tierSizes[5] = 4250; tierPrices[5] = 0.1708 ether;
    tierSizes[6] = 4000; tierPrices[6] = 0.2 ether; // Random size and price for Tier 6
    tierSizes[7] = 3750; tierPrices[7] = 0.2669 ether;
    tierSizes[8] = 3500; tierPrices[8] = 0.3337 ether;
    tierSizes[9] = 3250; tierPrices[9] = 0.4171 ether;
    tierSizes[10] = 3000; tierPrices[10] = 0.5214 ether;
    tierSizes[11] = 2800; tierPrices[11] = 0.6518 ether;
    tierSizes[12] = 2600; tierPrices[12] = 0.8148 ether;
    tierSizes[13] = 2400; tierPrices[13] = 1.0185 ether;
    tierSizes[14] = 2200; tierPrices[14] = 1.0317 ether;
    tierSizes[15] = 2000; tierPrices[15] = 1.0445 ether;
    tierSizes[16] = 1800; tierPrices[16] = 1.0575 ether;
    tierSizes[17] = 1600; tierPrices[17] = 1.0707 ether;
    tierSizes[18] = 1500; tierPrices[18] = 1.0841 ether;
    tierSizes[19] = 1400; tierPrices[19] = 1.0976 ether;
    tierSizes[20] = 1300; tierPrices[20] = 1.1113 ether;
    tierSizes[21] = 1200; tierPrices[21] = 1.1252 ether;
    tierSizes[22] = 1100; tierPrices[22] = 1.1391 ether;
    tierSizes[23] = 1000; tierPrices[23] = 1.1533 ether;
    tierSizes[24] = 950; tierPrices[24] = 1.1677 ether;
    tierSizes[25] = 900; tierPrices[25] = 1.1822 ether;
    tierSizes[26] = 850; tierPrices[26] = 1.197 ether;
    tierSizes[27] = 825; tierPrices[27] = 1.2119 ether;
    tierSizes[28] = 800; tierPrices[28] = 1.2271 ether;
    tierSizes[29] = 775; tierPrices[29] = 1.2424 ether;
    tierSizes[30] = 750; tierPrices[30] = 1.2579 ether;
    tierSizes[31] = 725; tierPrices[31] = 1.2736 ether;
    tierSizes[32] = 700; tierPrices[32] = 1.2895 ether;
    tierSizes[33] = 675; tierPrices[33] = 1.3056 ether;
    tierSizes[34] = 650; tierPrices[34] = 1.3218 ether;
    tierSizes[35] = 625; tierPrices[35] = 1.3383 ether;
    tierSizes[36] = 600; tierPrices[36] = 1.3549 ether;
    tierSizes[37] = 575; tierPrices[37] = 1.3717 ether;
    tierSizes[38] = 550; tierPrices[38] = 1.3886 ether;
    tierSizes[39] = 525; tierPrices[39] = 1.4058 ether;
    tierSizes[40] = 500; tierPrices[40] = 1.4231 ether;
    tierSizes[41] = 475; tierPrices[41] = 1.4406 ether;
    tierSizes[42] = 450; tierPrices[42] = 1.4583 ether;
    tierSizes[43] = 350; tierPrices[43] = 1.4761 ether;
    tierSizes[44] = 350; tierPrices[44] = 1.4941 ether;
    tierSizes[45] = 350; tierPrices[45] = 1.5123 ether;
    tierSizes[46] = 350; tierPrices[46] = 1.5307 ether;
    tierSizes[47] = 350; tierPrices[47] = 1.5493 ether;
    tierSizes[48] = 350; tierPrices[48] = 1.568 ether;
    tierSizes[49] = 350; tierPrices[49] = 1.5869 ether;
    tierSizes[50] = 350; tierPrices[50] = 1.6061 ether;
    tierSizes[51] = 350; tierPrices[51] = 1.6253 ether;
    tierSizes[52] = 350; tierPrices[52] = 1.6448 ether;
    tierSizes[53] = 350; tierPrices[53] = 1.6644 ether;
    tierSizes[54] = 350; tierPrices[54] = 1.6842 ether;
    tierSizes[55] = 350; tierPrices[55] = 1.7043 ether;
    tierSizes[56] = 350; tierPrices[56] = 1.7244 ether;
    tierSizes[57] = 350; tierPrices[57] = 1.7448 ether;
    tierSizes[58] = 350; tierPrices[58] = 1.7653 ether;
    tierSizes[59] = 350; tierPrices[59] = 1.786 ether;
    tierSizes[60] = 350; tierPrices[60] = 1.8069 ether;
    tierSizes[61] = 350; tierPrices[61] = 1.828 ether;
    tierSizes[62] = 350; tierPrices[62] = 1.8493 ether;
    tierSizes[63] = 350; tierPrices[63] = 1.8707 ether;
    tierSizes[64] = 350; tierPrices[64] = 1.8923 ether;
    tierSizes[65] = 350; tierPrices[65] = 1.9142 ether;
    tierSizes[66] = 350; tierPrices[66] = 1.9362 ether;
    tierSizes[67] = 350; tierPrices[67] = 1.9584 ether;
    tierSizes[68] = 350; tierPrices[68] = 1.9809 ether;
    tierSizes[69] = 350; tierPrices[69] = 2.0034 ether;
    tierSizes[70] = 350; tierPrices[70] = 2.0264 ether;
    tierSizes[71] = 350; tierPrices[71] = 2.0494 ether;
    tierSizes[72] = 350; tierPrices[72] = 2.0727 ether;
    tierSizes[73] = 350; tierPrices[73] = 2.0966 ether;
    tierSizes[74] = 350; tierPrices[74] = 2.12 ether;
    tierSizes[75] = 350; tierPrices[75] = 2.1442 ether;
    tierSizes[76] = 350; tierPrices[76] = 2.1684 ether;
    tierSizes[77] = 188; tierPrices[77] = 2.1926 ether;

    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        maxPerWallet = _newMax;
    }

    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        require(newTotalSupply >= totalMinted, "New total supply cannot be less than minted tokens");
        TOTAL_SUPPLY = newTotalSupply;
    }

    function setMaxTiers(uint256 newMaxTiers) external onlyOwner {
        require(newMaxTiers >= currentTier, "New max tiers cannot be less than the current tier");
        MAX_TIERS = newMaxTiers;

        for (uint256 i = 1; i <= MAX_TIERS; i++) {
            tierPrices[i] = 0.01 ether * i;
        }
    }

    function generateReferralCode(address user) public pure returns (string memory) {
        uint256 code = uint256(uint160(user)) % 1000000000;
        bytes memory codeStr = abi.encodePacked(uintToString(code));
        return string(codeStr);
    }

    function registerReferralCode() public {
        require(bytes(userReferralCodes[msg.sender]).length == 0, "Referral code already registered");

        string memory code = generateReferralCode(msg.sender);
        require(referralCodeToAddress[code] == address(0), "Referral code already in use");

        userReferralCodes[msg.sender] = code;
        referralCodeToAddress[code] = msg.sender;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function getReferralRewards(address user) external view returns (uint256) {
        return referralRewards[user];
    }

    function approveToken(address token, uint256 amount) external {
        require(token == usdtToken || token == usdcToken || token == wbtcToken, "Unsupported token");
        IERC20(token).approve(address(this), amount);
    }

    function buyNode(uint256 quantity, string memory referrerCode, address paymentToken) external payable {
        require(quantity > 0, "Quantity cannot be zero");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "Exceeds max per wallet");
        require(totalMinted + quantity <= TOTAL_SUPPLY, "Exceeds total supply");

        uint256 totalPrice = 0;
        uint256 remainingQuantity = quantity;
        uint256 referrerReward = 0;
        uint256 pricePerNode = getTokenPrice(paymentToken);

        if (bytes(referrerCode).length > 0) {
            address referrer = referralCodeToAddress[referrerCode];
            require(referrer != address(0), "Invalid referral code");
            require(referrer != msg.sender, "Cannot refer yourself");

            while (remainingQuantity > 0) {
                uint256 discountPerNode = (pricePerNode * 5) / 100;
                uint256 rewardPerNode = (pricePerNode * 20) / 100;
                // uint256 availableInCurrentTier = tierSize - tierMinted;
                uint256 availableInCurrentTier = tierSizes[currentTier] - tierMinted;


                if (remainingQuantity <= availableInCurrentTier) {
                    totalPrice += (pricePerNode - discountPerNode) * remainingQuantity;
                    referrerReward += rewardPerNode * remainingQuantity;
                    tierMinted += remainingQuantity;
                    remainingQuantity = 0;
                } else {
                    totalPrice += (pricePerNode - discountPerNode) * availableInCurrentTier;
                    referrerReward += rewardPerNode * availableInCurrentTier;
                    remainingQuantity -= availableInCurrentTier;
                    _advanceTier();
                }
            }

            referralRewards[referrer] += referrerReward;

        } else {
            while (remainingQuantity > 0) {
                uint256 availableInCurrentTier = tierSizes[currentTier] - tierMinted;

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

        if (paymentToken == address(0)) {
            require(msg.value >= totalPrice, "Insufficient ETH funds");
        } else {
            IERC20 token = IERC20(paymentToken);
            require(token.allowance(msg.sender, address(this)) >= totalPrice, "Insufficient token allowance");
            require(token.transferFrom(msg.sender, address(this), totalPrice), "Token transfer failed");
        }

        _transferTokensOnClaim(msg.sender, quantity);
        walletMints[msg.sender] += quantity;
    }

    function _advanceTier() internal {
        require(currentTier < MAX_TIERS, "All tiers completed");
        currentTier += 1;
        tierMinted = 0;
    }

    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        startTokenId = totalMinted;
        _safeMint(_to, _quantityBeingClaimed);
        totalMinted += _quantityBeingClaimed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function getTokenPrice(address token) public view returns (uint256 pricePerNodeInToken) {
        uint256 pricePerNodeInEth = tierPrices[currentTier];

        (, int256 ethToUsd, , , ) = ethToUsdPriceFeed.latestRoundData();
        require(ethToUsd > 0, "Invalid ETH/USD price");

        uint256 pricePerNodeInUsd = (uint256(ethToUsd) * pricePerNodeInEth) / 1e8;

        if (token == address(0)) {
            return pricePerNodeInEth;
        } else if (token == usdtToken) {
            (, int256 usdtToUsd, , , ) = usdtToUsdPriceFeed.latestRoundData();
            require(usdtToUsd > 0, "Invalid USDT/USD price");
            pricePerNodeInToken = (pricePerNodeInUsd * 1e6) / uint256(usdtToUsd);
            pricePerNodeInToken= pricePerNodeInToken / 1e10;
            
        } else if (token == usdcToken) {
            (, int256 usdcToUsd, , , ) = usdcToUsdPriceFeed.latestRoundData();
            require(usdcToUsd > 0, "Invalid USDC/USD price");
            pricePerNodeInToken = (pricePerNodeInUsd * 1e6) / uint256(usdcToUsd);
            pricePerNodeInToken= pricePerNodeInToken / 1e10;
        } else if (token == wbtcToken) {
            (, int256 wbtcToUsd, , , ) = wbtcToUsdPriceFeed.latestRoundData();
            require(wbtcToUsd > 0, "Invalid WBTC/USD price");
            pricePerNodeInToken = (pricePerNodeInUsd * 1e8) / uint256(wbtcToUsd);
            pricePerNodeInToken= pricePerNodeInToken / 1e10;
        } else {
            revert("Unsupported token");
        }
    }
}