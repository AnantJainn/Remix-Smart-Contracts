// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";

contract PoolContract {
    struct Deposit {
        uint256 tokenId;
        uint256 timestamp;
    }

    NFTContract public nft;
    mapping(address => Deposit) public deposits;
    uint256 public constant LOCK_TIME = 30 days;
    uint256 public constant ANNUAL_REWARD_PERCENTAGE = 15;

    event Deposited(address indexed user, uint256 tokenId, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 tokenId);

    constructor(address nftAddress) {
        nft = NFTContract(nftAddress);
    }

    function deposit(uint256 tokenId) external {
        nft.transferFrom(msg.sender, address(this), tokenId);
        deposits[msg.sender] = Deposit(tokenId, block.timestamp);
        emit Deposited(msg.sender, tokenId, block.timestamp);
    }

    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(
            block.timestamp >= userDeposit.timestamp + LOCK_TIME,
            "lock time not finished"
        );

        // uint256 reward = calculateReward(userDeposit.tokenId);
        // Send reward to the user (implement this)

        nft.transferFrom(address(this), msg.sender, userDeposit.tokenId);
        emit Withdrawn(msg.sender, userDeposit.tokenId);
        delete deposits[msg.sender];
    }

    function calculateReward(uint256 tokenId) public view returns (uint256) {
        uint256 price = nft.getPrice(tokenId);
        uint256 timeStaked = block.timestamp - deposits[msg.sender].timestamp;
        uint256 reward = (((price * ANNUAL_REWARD_PERCENTAGE) / 100) *
            timeStaked) / 365 days;
        return reward;
    }
}
