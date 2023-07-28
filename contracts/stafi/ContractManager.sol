pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StafiBase.sol";
import "./types/ProjectType.sol";
import "../project/ProjEther.sol";
import "../project/ProjBalances.sol";
import "../project/ProjNodeManager.sol";
import "../project/ProjSettings.sol";
import "../project/ProjUserDeposit.sol";
import "../project/rToken.sol";

contract ContractManager is StafiBase {
    using SafeMath for uint256;

    event ProjectCreated(uint256 indexed id, Project proj);
    event ContractUpgraded(bytes32 indexed name, address indexed oldAddress, address indexed newAddress, uint256 time);
    event ContractAdded(bytes32 indexed name, address indexed newAddress, uint256 time);

    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    function getProjectNonce() public view returns (uint256) {
        return getUintS("contractManager.project.nonce");
    }

    function setProjectNonce(uint256 _nonce) internal {
        setUintS("contractManager.project.nonce", _nonce);
    }

    function generateProjectId() internal returns (uint256) {
        uint256 id = getProjectNonce();
        if (id == 0) id = 2;
        setProjectNonce(id.add(1));
        return id;
    }

    function setProjectContractAddress(
        uint256 _id,
        string memory _name,
        address _value
    ) internal {
        setAddress(contractKey(_id, _name), _value);
    }

    function setProjectContractName(
        uint256 _pId,
        address _value,
        string memory _name
    ) internal {
        setString(contractNameKey(_pId, _value), _name);
    }

    function setProjectId(address _contractAddress, uint256 _pId) internal {
        setUint(projectIdKey(_contractAddress), _pId);
    }

    function saveProject(Project memory _proj) internal {
        setProjectContractAddress(_proj.id, "projrToken", _proj.rToken);
        setProjectContractAddress(_proj.id, "projEther", _proj.etherKeeper);
        setProjectContractAddress(_proj.id, "projUserDeposit", _proj.userDeposit);
        setProjectContractAddress(_proj.id, "projBalances", _proj.balances);
        setProjectContractAddress(_proj.id, "projSettings", _proj.settings);
        setProjectContractAddress(_proj.id, "projNodeManager", _proj.nodeManager);
        setProjectContractName(_proj.id, _proj.rToken, "projrToken");
        setProjectContractName(_proj.id, _proj.etherKeeper, "projEther");
        setProjectContractName(_proj.id, _proj.userDeposit, "projUserDeposit");
        setProjectContractName(_proj.id, _proj.balances, "projBalances")
        setProjectContractName(_proj.id, _proj.settings, "projSettings")
        setProjectContractName(_proj.id, _proj.nodeManager, "projNodeManager")
        setProjectId(_proj.rToken, _proj.id);
        setProjectId(_proj.etherKeeper, _proj.id);
        setProjectId(_proj.userDeposit, _proj.id);
        setProjectId(_proj.balances, _proj.id);
        setProjectId(_proj.settings, _proj.id);
        setProjectId(_proj.nodeManager, _proj.id);
    }

    function createProject(
        string memory _name,
        string memory _symbol,
        address _superUser
    ) external onlySuperUser(1) returns (uint256) {
        Project memory proj;
        uint256 _pId = generateProjectId();
        address  _stafiStorageAddress = address(stafiStorage)
        proj.id = _pId
        proj.rToken = address(new rToken(_pId, _stafiStorageAddress, _name, _symbol));
        proj.etherKeeper = address(new ProjEther(_pId, _stafiStorageAddress));
        proj.userDeposit = address(
            new UserDeposit(_pId, _stafiStorageAddress)
        );
        proj.balances = address(new ProjBalances(_pId, _stafiStorageAddress))
        proj.settings = address(new ProjSettings(_pId, _stafiStorageAddress))
        proj.nodeManager = address(new ProjNodeManager(_pId, _stafiStorageAddress));
        emit ProjectCreated(proj.id, proj);
        return proj.id;
    }

    // function upgradeContract(string memory _name, address _contractAddress) override external onlyLatestContract("stafiUpgrade", address(this)) onlySuperUser {
    //     // Check contract being upgraded
    //     bytes32 nameHash = keccak256(abi.encodePacked(_name));
    //     require(nameHash != keccak256(abi.encodePacked("stafiEther")), "Cannot upgrade the stafi ether contract");
    //     require(nameHash != keccak256(abi.encodePacked("rETHToken")), "Cannot upgrade token contracts");
    //     require(nameHash != keccak256(abi.encodePacked("ethDeposit")), "Cannot upgrade the eth deposit contract");
    //     // Get old contract address & check contract exists
    //     address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
    //     require(oldContractAddress != address(0x0), "Contract does not exist");
    //     // Check new contract address
    //     require(_contractAddress != address(0x0), "Invalid contract address");
    //     require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
    //     // Register new contract
    //     setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
    //     setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
    //     setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
    //     // Deregister old contract
    //     deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
    //     deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
    //     // Emit contract upgraded event
    //     emit ContractUpgraded(nameHash, oldContractAddress, _contractAddress, block.timestamp);
    // }

    // function addContract(string memory _name, address _contractAddress) override external onlyLatestContract("stafiUpgrade", address(this)) onlySuperUser {
    //     // Check contract name
    //     bytes32 nameHash = keccak256(abi.encodePacked(_name));
    //     require(nameHash != keccak256(abi.encodePacked("")), "Invalid contract name");
    //     require(getAddress(keccak256(abi.encodePacked("contract.address", _name))) == address(0x0), "Contract name is already in use");
    //     // Check contract address
    //     require(_contractAddress != address(0x0), "Invalid contract address");
    //     require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
    //     // Register contract
    //     setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
    //     setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
    //     setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
    //     // Emit contract added event
    //     emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    // }

    // // Init stafi storage contract
    // function initStorage(bool _value) external onlySuperUser {
    //     setBool(keccak256(abi.encodePacked("contract.storage.initialised")), _value);
    // }

    // // Init stafi upgrade contract
    // function initThisContract() external onlySuperUser {
    //     addStafiUpgradeContract(address(this));
    // }

    // // Upgrade stafi upgrade contract
    // function upgradeThisContract(address _contractAddress) external onlySuperUser {
    //     addStafiUpgradeContract(_contractAddress);
    // }

    // // Add stafi upgrade contract
    // function addStafiUpgradeContract(address _contractAddress) private {
    //     string memory name = "stafiUpgrade";
    //     bytes32 nameHash = keccak256(abi.encodePacked(name));
    //     address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", name)));
        
    //     setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
    //     setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), name);
    //     setAddress(keccak256(abi.encodePacked("contract.address", name)), _contractAddress);
        
    //     if (oldContractAddress != address(0x0)) {
    //         deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
    //         deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
    //     }
    //     // Emit contract added event
    //     emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    // }
}
