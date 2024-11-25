// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CertificateStorage {
    mapping(address => string) public certificates;

    function storeCertificate(string memory _certificateData) public {
        certificates[msg.sender] = _certificateData;
    }
}
