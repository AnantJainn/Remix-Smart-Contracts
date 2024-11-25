// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Contract for buying and selling real estate
contract RealEstate {
    // We're using library here
    using SafeMath for uint256;

    // Data set --> keep information about property which user list for sell
    struct Property {
        uint256 price;
        address owner;
        bool forSale; // Is the property for sale?
        string name;
        string description;
        string location;
    }

    // Keep track every property
    mapping(uint256 => Property) public properties;

    // Keep all the ID of every single property.
    // Registration or buying a land => this Id have a critical role and it's unique.
    // We're going to store into this array.
    uint256[] public propertyIds;

    // When a property is sold, we'll call this event
    event PropertySold(uint256 propertyId);

    // We're taking them from struct above, user can list their ForSale property to the smart contract.
    function listPropertyForSale(
        uint256 _propertyId,
        uint256 _price,
        string memory _name,
        string memory _description,
        string memory _location
    ) public {
        //store this data and update the struct
        Property memory newProperty = Property({
            price: _price,
            owner: msg.sender,
            forSale: true,
            name: _name,
            description: _description,
            location: _location
        });

        // We just pass the Id of the property, it'll give complete data
        properties[_propertyId] = newProperty;
        propertyIds.push(_propertyId);
    }

    // User can buy the ForSale property. Pass the Id and they can buy it.
    function buyProperty(uint256 _propertyId) public payable {
        Property storage property = properties[_propertyId];

        // 1st check --> whether is sale or not.
        // 2nd check --> whether user have enough budget or not.
        require(property.forSale, "Property is not for sale");
        require(property.price <= msg.value, "Insufficient balance");

        property.owner = msg.sender;
        property.forSale = false;

        // After after declaring the property not for sale, do the transfer of the fund to the seller.
        payable(property.owner).transfer(property.price);

        // Initiliaze the event we created before.
        emit PropertySold(_propertyId);
    }
}