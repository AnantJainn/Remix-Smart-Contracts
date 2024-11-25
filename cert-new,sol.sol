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

    struct AIValidation {
        bool validated;
        bytes32 validationHash;
    }

    // State Variables
    address public admin;
    mapping(uint256 => Certificate) public certificates;
    mapping(string => AIValidation) public aiValidations;
    mapping(address => bool) public issuers;
    uint256 public nextCertificateId;

    // Events
    event CertificateIssued(uint256 id);
    event CertificateVerified(uint256 id, bool valid);
    event AIValidationRecorded(string candidateDetails, bytes32 validationHash);
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

    modifier aiValidated(string memory candidateDetails) {
        require(aiValidations[candidateDetails].validated, "AI validation not recorded for candidate");
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

    function recordAIValidation(string memory candidateDetails, bytes32 validationHash) external onlyIssuer {
        aiValidations[candidateDetails] = AIValidation(true, validationHash);
        emit AIValidationRecorded(candidateDetails, validationHash);
    }

    function issueCertificate(
        string memory candidateName,
        string memory course,
        string memory issueDate,
        bytes32 aiValidationHash
    ) external onlyIssuer aiValidated(candidateName) {
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
}
