// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "./interfaces/IWallet.sol";
import "./interfaces/IValidator.sol";
import "./core/CoreWallet.sol";

contract Wallet is CoreWallet, IWallet {
    IEntryPoint private immutable _entryPoint;

    constructor(address entryPoint_) {
        _entryPoint = IEntryPoint(entryPoint_);
    }

    /**
     * modifier validate caller is entrypoint
     */
    modifier authorized() {
        require(msg.sender == address(entryPoint()), "Core Wallet: Invalid Caller");
        _;
    }

    /// @inheritdoc CoreWallet
    function setValidator(bytes4 mode, address validator) external override authorized {
        _setValidator(mode, validator);
        emit SetValidator(mode, validator);
    }

    /// @inheritdoc IWallet
    function execute(address dest, uint256 value, bytes calldata func) external override authorized {
        _call(dest, value, func);
    }

    /// @inheritdoc IWallet
    function executeBatch(address[] calldata dest, bytes[] calldata func) external override authorized {
        require(dest.length == func.length, "Roll Wallet: Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IWallet).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
