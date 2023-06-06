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
import "../interfaces/IWallet.sol";
import "../libraries/SafeWhaleV1Storage.sol";

abstract contract CoreWallet is IERC1271, BaseAccount, ERC165, Initializable {
    using Address for address;
    using ECDSA for bytes32;
    using WalletStorage for WalletStorage.StorageLayout;

    event SetValidator(address validator, bool isActive);

    function _isValidCaller() internal virtual view returns(bool);

    /**
     * modifier validate caller is entrypoint
     */
    modifier authorized() {
        require(_isValidCaller(), "Core Wallet: Invalid Caller");
        _;
    }

    /**
     * update add validators
     */
    function _setValidator(address validator, bool isActive) internal {
        WalletStorage.StorageLayout storage layout = WalletStorage.getStorage();
        layout.isValidators[validator] = isActive;
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal override returns (uint256 validationData) {
        (address validator, bytes memory signature) = abi.decode(userOp.signature, (address, bytes));
        WalletStorage.StorageLayout storage layout = WalletStorage.getStorage();

        if (layout.isValidators[validator]) {
            if (validator.isContract()) {
                validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
            } else {
                bytes32 hash = userOpHash.toEthSignedMessageHash();
                if (validator == hash.recover(signature)) {
                    validationData = 0;
                } else {
                    validationData = SIG_VALIDATION_FAILED;
                }
            }
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
    function setValidator(address validator, bool isActive) external virtual;

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4 magicValue) {
        (address validator, bytes memory trueSignature) = abi.decode(signature, (address, bytes));

        WalletStorage.StorageLayout storage layout = WalletStorage.getStorage();

        if (layout.isValidators[validator]) {
            if (validator.isContract()) {
                magicValue = IValidator(validator).isValidSignature(hash, trueSignature);
            } else {
                if (validator == hash.recover(trueSignature)) {
                    magicValue = this.isValidSignature.selector;
                } else {
                    magicValue = bytes4(0xffffffff) ;
                }
            }
        } else {
            magicValue = bytes4(0xffffffff);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1271).interfaceId || super.supportsInterface(interfaceId);
    }
}
