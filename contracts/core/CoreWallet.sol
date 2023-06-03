// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IValidator.sol";

abstract contract CoreWallet is IERC1271, BaseAccount, ERC165, Initializable {
    using Address for address;
    using ECDSA for bytes32;

    event SetKey(address key, bool isActive);

    mapping(address => bool) public keys;

    /**
     * modifier validate caller is entrypoint
     */
    modifier authorized() {
        require(msg.sender == address(entryPoint()) || keys[msg.sender], "Core Wallet: Invalid Caller");
        _;
    }

    function _initCoreWallet(address initKey) internal onlyInitializing {
        keys[initKey] = true;
    }

    /**
     * update sub keys
     */
    function _setKey(address key, bool isActive) internal {
        keys[key] = isActive;
    }

    /**
     * core validate signature
     */
    function _validateSignature(
        address key,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (uint256 validationData) {
        if (key.isContract()) {
            validationData = IValidator(key).validateSignature(hash, signature);
        } else {
            if (key == hash.recover(signature)) {
                validationData = 0;
            } else {
                validationData = SIG_VALIDATION_FAILED;
            }
        }
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256 validationData) {
        (address key, bytes memory signature) = abi.decode(userOp.signature, (address, bytes));

        if (keys[key]) {
            validationData = _validateSignature(key, userOpHash.toEthSignedMessageHash(), signature);
        } else {
            validationData = SIG_VALIDATION_FAILED;
        }
    }

    /**
     * execute a transactions
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * External function to update validator
     */
    function setKey(address key, bool isActive) external virtual;

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4 magicValue) {
        (address key, bytes memory trueSignature) = abi.decode(signature, (address, bytes));

        uint256 validationData;
        if (keys[key]) {
            validationData = _validateSignature(key, hash, trueSignature);
        } else {
            validationData = SIG_VALIDATION_FAILED;
        }

        return validationData == SIG_VALIDATION_FAILED ? bytes4(0xffffffff) : this.isValidSignature.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1271).interfaceId || super.supportsInterface(interfaceId);
    }
}
