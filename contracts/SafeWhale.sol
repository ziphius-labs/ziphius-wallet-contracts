// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "./interfaces/IWallet.sol";
import "./core/CoreWallet.sol";

contract SafeWhale is CoreWallet, IWallet {
    IEntryPoint private immutable _entryPoint;

    constructor(address entryPoint_) {
        _entryPoint = IEntryPoint(entryPoint_);
    }

    function init(address key) external initializer {
        _setKey(key, true);
    }

    /// @inheritdoc CoreWallet
    function setKey(address key, bool isActive) external override authorized {
        _setKey(key, isActive);
        emit SetKey(key, isActive);
    }

    /// @inheritdoc IWallet
    function execute(address dest, uint256 value, bytes calldata func) external override authorized {
        _call(dest, value, func);

        emit Execute();
    }

    /// @inheritdoc IWallet
    function executeBatch(address[] calldata dest, bytes[] calldata func) external override authorized {
        require(dest.length == func.length, "Roll Wallet: Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
        emit Execute();
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IWallet).interfaceId || super.supportsInterface(interfaceId);
    }
}