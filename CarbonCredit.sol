// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Carbon Credit Smart Contract
contract CarbonCredit is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct CarbonCreditData {
        uint256 carbonReduction;
        uint256 baselineFootprint;
        string industryType;
        string location;
        string verificationStatus;
    }

    mapping(uint256 => CarbonCreditData) public carbonCreditData;

    // Events
    event CarbonCreditGenerated(uint256 tokenId, uint256 carbonReduction, uint256 baselineFootprint);
    event CarbonCreditRetired(uint256 tokenId);

    constructor() ERC721("CarbonCredit", "CCT") Ownable(msg.sender) {}


    // constructor() ERC721("CarbonCredit", "CCT") {}

    // Function to generate carbon credits based on verified emission reductions
    function generateCarbonCredit(
        uint256 _carbonReduction, 
        uint256 _baselineFootprint, 
        string memory _industryType, 
        string memory _location, 
        string memory _verificationStatus
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        carbonCreditData[newTokenId] = CarbonCreditData({
            carbonReduction: _carbonReduction,
            baselineFootprint: _baselineFootprint,
            industryType: _industryType,
            location: _location,
            verificationStatus: _verificationStatus
        });

        _mint(msg.sender, newTokenId);

        emit CarbonCreditGenerated(newTokenId, _carbonReduction, _baselineFootprint);
        return newTokenId;
    }

    // Function to retire a carbon credit after it is utilized
    function retireCarbonCredit(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Carbon credit does not exist");
        _burn(tokenId);
        emit CarbonCreditRetired(tokenId);
    }

    // Function to retrieve details of a carbon credit NFT
    function getCarbonCreditDetails(uint256 tokenId) public view returns (
        uint256, uint256, string memory, string memory, string memory
    ) {
        require(_exists(tokenId), "Carbon credit does not exist");
        CarbonCreditData memory creditData = carbonCreditData[tokenId];
        return (
            creditData.carbonReduction,
            creditData.baselineFootprint,
            creditData.industryType,
            creditData.location,
            creditData.verificationStatus
        );
    }

    // Function to calculate carbon credits based on emission reduction
    function calculateCarbonCredits(uint256 _baselineFootprint, uint256 _currentFootprint, uint256 _conversionFactor) public pure returns (uint256) {
        require(_baselineFootprint >= _currentFootprint, "Invalid footprints");
        uint256 carbonCredits = (_baselineFootprint - _currentFootprint) / _conversionFactor;
        return carbonCredits;
    }
}