// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeepFakeVerification {

    // Structure to store video details and AI verification results
    struct VideoDetails {
        bytes32 ipfsHash;
        bool aiVerificationResult;
        uint256 timestamp;
    }

    // Mapping to store video details by video ID
    mapping (uint256 => VideoDetails) public videos;

    // Event to log successful video verification
    event VideoVerified(uint256 indexed videoId, bytes32 ipfsHash, bool aiVerificationResult, uint256 timestamp);

    // Modifier to ensure only the system can perform certain actions
    modifier onlySystem() {
        require(msg.sender == systemAddress, "Permission denied");
        _;
    }

    // Address of the system contract (set during deployment)
    address public systemAddress;

    // Constructor to set the system contract address
    constructor() {
        systemAddress = msg.sender;
    }

    // Function to timestamp the original video on the blockchain
    function timestampVideo(uint256 videoId, bytes32 _ipfsHash, bool _aiVerificationResult) external onlySystem {
        // Ensure the video ID is unique
        require(videos[videoId].timestamp == 0, "Duplicate video ID");

        // Store video details and AI verification results
        videos[videoId] = VideoDetails({
            ipfsHash: _ipfsHash,
            aiVerificationResult: _aiVerificationResult,
            timestamp: block.timestamp
        });

        // Emit an event to log the video verification
        emit VideoVerified(videoId, _ipfsHash, _aiVerificationResult, block.timestamp);
    }

    // Function to query AI verification result for a video
    function getAIVerificationResult(uint256 videoId) external view returns (bool) {
        return videos[videoId].aiVerificationResult;
    }

    // Function to query timestamp and other details for a video
    function getVideoDetails(uint256 videoId) external view returns (bytes32, bool, uint256) {
        return (videos[videoId].ipfsHash, videos[videoId].aiVerificationResult, videos[videoId].timestamp);
    }
}