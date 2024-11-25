// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Verification {
    uint16 public countExporters = 0;
    uint16 public countHashes = 0;
    address public owner;

    struct Record {
        uint blockNumber;
        uint mineTime;
        string info;
        string ipfsHash;
    }

    struct ExporterRecord {
        uint blockNumber;
        string info;
    }

    mapping(bytes32 => Record) private docHashes;
    mapping(address => ExporterRecord) private exporters;

    event HashAdded(address indexed exporter, string ipfsHash);
    event ExporterAdded(address indexed exporter);
    event ExporterDeleted(address indexed exporter);
    event ExporterInfoChanged(address indexed exporter, string newInfo);
    event OwnerChanged(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier exporterExists(address _addr) {
        require(exporters[_addr].blockNumber != 0, "Exporter does not exist");
        _;
    }

    modifier canAddHash() {
        require(exporters[msg.sender].blockNumber != 0, "Caller not authorised to add documents");
        _;
    }

    modifier authorisedExporter(bytes32 _doc) {
        require(
            keccak256(abi.encodePacked((exporters[msg.sender].info))) == keccak256(abi.encodePacked((docHashes[_doc].info))),
            "Caller is not authorised to edit this document"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addExporter(address _addr, string calldata _info) external onlyOwner {
        require(_addr != address(0), "Invalid address");
        require(exporters[_addr].blockNumber == 0, "Exporter already exists");

        exporters[_addr] = ExporterRecord(block.number, _info);
        countExporters++;
        emit ExporterAdded(_addr);
    }

    function deleteExporter(address _addr) external onlyOwner exporterExists(_addr) {
        delete exporters[_addr];
        countExporters--;
        emit ExporterDeleted(_addr);
    }

    function alterExporterInfo(address _addr, string calldata _newInfo) external onlyOwner exporterExists(_addr) {
        exporters[_addr].info = _newInfo;
        emit ExporterInfoChanged(_addr, _newInfo);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    function addDocHash(bytes32 hash, string calldata _ipfs) public canAddHash {
        require(docHashes[hash].blockNumber == 0, "Document already exists");

        docHashes[hash] = Record(block.number, block.timestamp, exporters[msg.sender].info, _ipfs);
        countHashes++;
        emit HashAdded(msg.sender, _ipfs);
    }

    function deleteHash(bytes32 _hash) public authorisedExporter(_hash) canAddHash {
        require(docHashes[_hash].mineTime != 0, "Document does not exist");
        
        delete docHashes[_hash];
        countHashes--;
    }

    function findDocHash(bytes32 _hash) external view returns (uint, uint, string memory, string memory) {
        Record memory doc = docHashes[_hash];
        require(doc.mineTime != 0, "Document does not exist");

        return (doc.blockNumber, doc.mineTime, doc.info, doc.ipfsHash);
    }

    function getExporterInfo(address _addr) external view returns (string memory) {
        require(_addr != address(0), "Invalid address");
        return exporters[_addr].info;
    }
}
