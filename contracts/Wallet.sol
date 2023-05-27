// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "./interfaces/IWallet.sol";
import "./interfaces/IValidator.sol";

contract Wallet is IWallet, BaseAccount {
    IEntryPoint private immutable _entryPoint;
    IValidator private _validator;

    constructor(address entryPoint_) {
        _entryPoint = IEntryPoint(entryPoint_);
    }

    modifier authorized() {
        require(_isValidCaller(), "Roll Wallet: Invalid Caller");
        _;
    }

    // Require the function call went through EntryPoint or owner
    function _isValidCaller() internal view returns(bool) {
        if (msg.sender == address(entryPoint())) {
            return true;
        } else {
            return _validator.isValidCaller(msg.sender);
        }
    }

    /**
     * execute a transactions
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view override returns (uint256 validationData) {
        return _validator.validateSignature(userOp, userOpHash);
    }

    /**
     * update new validator
     */
    function updateValidator(address newValidator, bytes calldata initData) external authorized {
        _validator = IValidator(newValidator);
        _call(address(newValidator), 0, initData);

        emit UpdateValidator(newValidator);
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external authorized {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external authorized {
        require(dest.length == func.length, "Roll Wallet: Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }
}
