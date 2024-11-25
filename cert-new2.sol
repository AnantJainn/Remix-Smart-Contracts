// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateValidation {
    // Data Structures
    struct Certificate {
        uint256 id;
        string candidateName;
        string course;
        string issueDate;
        bool valid;
        bytes32 aiValidationHash;
    }

    // State Variables
    address public admin;
    mapping(uint256 => Certificate) public certificates;
    uint256 public nextCertificateId;
    mapping(address => bool) public issuers;

    // Events
    event CertificateIssued(uint256 id);
    event CertificateVerified(uint256 id, bool valid);
    event IssuerAdded(address issuer);
    event IssuerRemoved(address issuer);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyIssuer() {
        require(issuers[msg.sender], "Only authorized issuer can call this function");
        _;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
    }

    // Functions
    function addIssuer(address issuer) external onlyAdmin {
        issuers[issuer] = true;
        emit IssuerAdded(issuer);
    }

    function removeIssuer(address issuer) external onlyAdmin {
        issuers[issuer] = false;
        emit IssuerRemoved(issuer);
    }

    function issueCertificate(
        string memory candidateName,
        string memory course,
        string memory issueDate
    ) external onlyIssuer {
        bytes32 aiValidationHash = generateAIValidationHash(candidateName);
        certificates[nextCertificateId] = Certificate(
            nextCertificateId,
            candidateName,
            course,
            issueDate,
            true,
            aiValidationHash
        );
        emit CertificateIssued(nextCertificateId);
        nextCertificateId++;
    }

    function verifyCertificate(uint256 id) external view returns (Certificate memory) {
        require(id < nextCertificateId, "Invalid certificate ID");
        return certificates[id];
    }

    function invalidateCertificate(uint256 id) external onlyIssuer {
        require(id < nextCertificateId, "Invalid certificate ID");
        certificates[id].valid = false;
        emit CertificateVerified(id, false);
    }

    // Internal function to generate AI validation hash
    function generateAIValidationHash(string memory candidateName) internal pure returns (bytes32) {
        // Replace this with your AI validation logic
        // For demonstration purposes, using a simple keccak256 hash
        return keccak256(abi.encodePacked(candidateName));
    }
}

