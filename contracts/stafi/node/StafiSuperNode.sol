pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/storage/IPubkeySetStorage.sol";
import "../../project/interfaces/IProjSuperNode.sol";
import "../../project/interfaces/IProjNodeManager.sol";
import "../../project/interfaces/IProjSettings.sol";
import "../../project/interfaces/IProjUserDeposit.sol";

contract StafiSuperNode is StafiBase, IStafiSuperNode {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Staked(address node, bytes pubkey);
    event Deposited(address node, bytes pubkey, bytes validatorSignature);
    event SetPubkeyStatus(bytes pubkey, uint256 status);

    uint256 public constant PUBKEY_STATUS_UNINITIAL = 0;
    uint256 public constant PUBKEY_STATUS_INITIAL = 1;
    uint256 public constant PUBKEY_STATUS_MATCH = 2;
    uint256 public constant PUBKEY_STATUS_STAKING = 3;
    uint256 public constant PUBKEY_STATUS_UNMATCH = 4;

    // Construct
    constructor(
        address _stafiStorageAddress
    ) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    function ProjSettings(uint256 _pId) private view returns (IProjSettings) {
        return IProjSettings(getContractAddress(_pId, "projSettings"));
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress(1, "pubkeySetStorage"));
    }

    // Get the number of pubkeys owned by a super node
    function getSuperNodePubkeyCount(
        uint256 _pId,
        address _nodeAddress
    ) public view override returns (uint256) {
        return
            PubkeySetStorage().getCount(
                keccak256(
                    abi.encodePacked(
                        "superNode.pubkeys.index",
                        _pId,
                        _nodeAddress
                    )
                )
            );
    }

    // Get a light node pubkey status
    function getLightNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey
    ) private view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "lightNode.pubkey.status",
                        _pId,
                        _validatorPubkey
                    )
                )
            );
    }

    // Get a super node pubkey status
    function getSuperNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "superNode.pubkey.status",
                        _pId,
                        _validatorPubkey
                    )
                )
            );
    }

    // Set a super node pubkey status
    function _setSuperNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey,
        uint256 _status
    ) private {
        setUint(
            keccak256(
                abi.encodePacked(
                    "superNode.pubkey.status",
                    _pId,
                    _validatorPubkey
                )
            ),
            _status
        );

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }

    function deposit(
        address _user,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external override onlyLatestContract(1, "stafiSuperNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projSuperNode") == msg.sender,
            "Invalid caller"
        );
        IProjNodeManager projNodeManager = IProjNodeManager(
            getContractAddress(_pId, "projNodeManager")
        );
        require(
            projNodeManager.getSuperNodeExists(_user),
            "Invalid super node"
        );
        IProjSuperNode projSuperNode = IProjSuperNode(msg.sender);
        require(
            projSuperNode.getSuperNodeDepositEnabled(),
            "super node deposits are currently disabled"
        );
        uint256 len = _validatorPubkeys.length;
        require(
            len == _validatorSignatures.length &&
                len == _depositDataRoots.length,
            "params len err"
        );
        require(
            getSuperNodePubkeyCount(_pId, _user).add(len) <=
                ProjSettings(_pId).getSuperNodePubkeyLimit(),
            "pubkey amount over limit"
        );
        // Load contracts
        IProjUserDeposit projUserDeposit = IProjUserDeposit(
            getContractAddress(_pId, "projUserDeposit")
        );
        projUserDeposit.withdrawExcessBalanceForSuperNode(len.mul(1 ether));

        for (uint256 i = 0; i < len; i++) {
            _deposit(
                _pId,
                _user,
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i]
            );
        }
    }

    function stake(
        address _user,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external override onlyLatestContract(1, "stafiSuperNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projSuperNode") == msg.sender,
            "Invalid caller"
        );
        IProjNodeManager projNodeManager = IProjNodeManager(
            getContractAddress(_pId, "projNodeManager")
        );
        require(
            projNodeManager.getSuperNodeExists(_user),
            "Invalid super node"
        );
        uint256 len = _validatorPubkeys.length;
        require(
            len == _validatorSignatures.length &&
                len == _depositDataRoots.length,
            "params len err"
        );
        // Load contracts
        IProjUserDeposit projUserDeposit = IProjUserDeposit(
            getContractAddress(_pId, "projUserDeposit")
        );
        projUserDeposit.withdrawExcessBalanceForSuperNode(len.mul(31 ether));

        for (uint256 i = 0; i < len; i++) {
            _stake(
                _pId,
                _user,
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i]
            );
        }
    }

    function _deposit(
        uint256 _pId,
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) private {
        setAndCheckNodePubkeyInDeposit(_pId, _user, _validatorPubkey);
        // Send staking deposit to casper
        IProjSuperNode projSuperNode = IProjSuperNode(msg.sender);
        projSuperNode.ethDeposit(
            _user,
            _validatorPubkey,
            _validatorSignature,
            _depositDataRoot
        );
    }

    function _stake(
        uint256 _pId,
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) private {
        setAndCheckNodePubkeyInStake(_pId, _validatorPubkey);
        // Send staking deposit to casper
        IProjSuperNode projSuperNode = IProjSuperNode(msg.sender);
        projSuperNode.ethStake(
            _user,
            _validatorPubkey,
            _validatorSignature,
            _depositDataRoot
        );
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(
        uint256 _pId,
        address _user,
        bytes calldata _pubkey
    ) private {
        // check pubkey of lightNodes
        require(
            getLightNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_UNINITIAL,
            "light Node pubkey exists"
        );

        // check status
        require(
            getSuperNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_UNINITIAL,
            "pubkey status unmatch"
        );
        // set pubkey status
        _setSuperNodePubkeyStatus(_pId, _pubkey, PUBKEY_STATUS_INITIAL);
        // add pubkey to set
        PubkeySetStorage().addItem(
            keccak256(abi.encodePacked("superNode.pubkeys.index", _pId, _user)),
            _pubkey
        );
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(
        uint256 _pId,
        bytes calldata _pubkey
    ) private {
        // check status
        require(
            getSuperNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_MATCH,
            "pubkey status unmatch"
        );
        // set pubkey status
        _setSuperNodePubkeyStatus(_pId, _pubkey, PUBKEY_STATUS_STAKING);
    }

    function voteWithdrawCredentials(
        address _voter,
        bytes[] calldata _pubkeys,
        bool[] calldata _matchs
    ) external override onlyLatestContract(1, "stafiSuperNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projSuperNode") == msg.sender,
            "Invalid caller"
        );
        require(_pubkeys.length == _matchs.length, "params len err");
        for (uint256 i = 0; i < _pubkeys.length; i++) {
            _voteWithdrawCredentials(_pId, _voter, _pubkeys[i], _matchs[i]);
        }
    }

    // Only accepts calls from trusted (oracle) nodes
    function _voteWithdrawCredentials(
        uint256 _pId,
        address _voter,
        bytes calldata _pubkey,
        bool _match
    ) private {
        // Check & update node vote status
        require(
            !getBool(
                keccak256(
                    abi.encodePacked(
                        "superNode.memberVotes.",
                        _pId,
                        _pubkey,
                        _voter
                    )
                )
            ),
            "Member has already voted to withdrawCredentials"
        );
        setBool(
            keccak256(
                abi.encodePacked(
                    "superNode.memberVotes.",
                    _pId,
                    _pubkey,
                    _voter
                )
            ),
            true
        );

        // Increment votes count
        uint256 totalVotes = getUint(
            keccak256(
                abi.encodePacked("superNode.totalVotes", _pId, _pubkey, _match)
            )
        );
        totalVotes = totalVotes.add(1);
        setUint(
            keccak256(
                abi.encodePacked("superNode.totalVotes", _pId, _pubkey, _match)
            ),
            totalVotes
        );

        // Check count and set status
        uint256 calcBase = 1 ether;
        IProjNodeManager projNodeManager = IProjNodeManager(
            getContractAddress(_pId, "stafiNodeManager")
        );
        if (
            getSuperNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_INITIAL &&
            calcBase.mul(totalVotes) >=
            projNodeManager.getTrustedNodeCount().mul(
                ProjSettings(_pId).getNodeConsensusThreshold()
            )
        ) {
            _setSuperNodePubkeyStatus(
                _pId,
                _pubkey,
                _match ? PUBKEY_STATUS_MATCH : PUBKEY_STATUS_UNMATCH
            );
        }
    }
}