// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/IRateProvider.sol";

contract LsdToken is ILsdToken, ERC20Burnable {
    address public minter;
    event MinterChanged(address oldMinter, address newMinter);

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert CallerNotAllowed();
        }
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function getRate() external view override returns (uint256) {
        return IRateProvider(minter).getRate();
    }

    function initMinter(address _minter) external override {
        if (minter != address(0)) {
            revert AlreadyInitialized();
        }

        minter = _minter;
    }

    // Mint lsdToken
    // Only accepts calls from minter
    function mint(address _to, uint256 _lsdTokenAmount) external override onlyMinter {
        // Check lsdToken amount
        if (_lsdTokenAmount == 0) {
            revert AmountZero();
        }
        // Update balance & supply
        _mint(_to, _lsdTokenAmount);
    }

    function updateMinter(address _newMinter) external override onlyMinter {
        if (_newMinter == address(0)) revert AddressNotAllowed();
        emit MinterChanged(minter, _newMinter);
        minter = _newMinter;
    }
}
