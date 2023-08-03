pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/storage/IAddressSetStorage.sol";
import "../../project/interfaces/IProjNodeManager.sol";

// Node registration and management
contract StafiNodeManager is StafiBase, IStafiNodeManager {
    // Construct
    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    // Set a node's trusted status
    // Only accepts calls from super users
    function setNodeTrusted(
        address _nodeAddress,
        bool _trusted
    )
        external
        override
        onlyLatestContract(1, "stafiNodeManager", address(this))
    {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projNodeManager") == msg.sender,
            "Invalid caller"
        );
        IProjNodeManager projNodeManager = IProjNodeManager(msg.sender);
        // Check current node status
        require(
            projNodeManager.getNodeTrusted(_nodeAddress) != _trusted,
            "The node's trusted status is already set"
        );
        // Load contracts
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        // Set status
        setBool(
            keccak256(abi.encodePacked("node.trusted", _pId, _nodeAddress)),
            _trusted
        );
        // Add node to / remove node from trusted index
        if (_trusted) {
            addressSetStorage.addItem(
                keccak256(abi.encodePacked("nodes.trusted.index", _pId)),
                _nodeAddress
            );
        } else {
            addressSetStorage.removeItem(
                keccak256(abi.encodePacked("nodes.trusted.index", _pId)),
                _nodeAddress
            );
        }
    }

    // Set a node's super status
    // Only accepts calls from super users
    function setNodeSuper(
        address _nodeAddress,
        bool _super
    )
        external
        override
        onlyLatestContract(1, "stafiNodeManager", address(this))
    {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projNodeManager") == msg.sender,
            "Invalid caller"
        );
        IProjNodeManager projNodeManager = IProjNodeManager(msg.sender);
        // Check current node status
        require(
            !projNodeManager.getSuperNodeExists(_nodeAddress),
            "The node's super status is already set"
        );
        // Load contracts
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        // Set status
        setBool(
            keccak256(abi.encodePacked("node.super", _pId, _nodeAddress)),
            _super
        );
        // Add node to / remove node from trusted index
        if (_super) {
            addressSetStorage.addItem(
                keccak256(abi.encodePacked("nodes.super.index", _pId)),
                _nodeAddress
            );
        } else {
            addressSetStorage.removeItem(
                keccak256(abi.encodePacked("nodes.super.index", _pId)),
                _nodeAddress
            );
        }
    }
}
