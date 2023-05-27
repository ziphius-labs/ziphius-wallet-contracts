// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IValidator.sol";

abstract contract CoreWallet is IERC1271, BaseAccount, ERC165  {
    event SetValidator(bytes4 mode, address validator);

    mapping(bytes4 => address) private _validators;

    /**
     * update validator
     */
    function _setValidator(bytes4 mode, address validator) internal {
        _validators[mode] = validator;
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash) internal view override returns (uint256 validationData) {
        bytes4 mode = bytes4(userOp.signature[:4]);
        address validator = _validators[mode];
        require(validator != address(0), "Core Wallet: Invalid validator");

        return IValidator(_validators[mode]).validateUserOp(userOp, userOpHash);
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

    /**
     * External function to update validator
     */
    function setValidator(bytes4 mode, address validator) external virtual;

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4 magicValue) {
        bytes4 mode = bytes4(signature[:4]);
        address validator = _validators[mode];
        require(validator != address(0), "Core Wallet: Invalid validator");

        return IValidator(validator).validateSignature(hash, signature) ? this.isValidSignature.selector : bytes4(0xffffffff);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1271).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
