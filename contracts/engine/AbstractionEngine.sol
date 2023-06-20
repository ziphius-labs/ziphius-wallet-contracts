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
import "./AbstractionEngineV1Storage.sol";

/**
 * @title Abstraction Engine
 * @author Terry
 * @notice CoreWallet implement authentication methods in Smart Contracts Wallet inherit BaseAccount
 */
abstract contract AbstractionEngine is IERC1271, BaseAccount, ERC165, Initializable {
    using Address for address;
    using ECDSA for bytes32;
    using WalletStorage for WalletStorage.StorageLayout;

    event SetValidator(address validator, bool isActive);

    function _isValidCaller() internal view virtual returns (bool);

    /**
     * modifier validate caller is entrypoint
     */
    modifier authorized() {
        require(_isValidCaller(), "Abstraction Engine: Invalid Caller");
        _;
    }

    /**
     * update add validators
     */
    function _setValidator(address validator, bool isActive) internal {
        WalletStorage.StorageLayout storage layout = WalletStorage.getStorage();
        layout.isValidators[validator] = isActive;
    }

    /**
     * check an address is validator
     */
    function _isValidator(address validator) internal view returns (bool) {
        WalletStorage.StorageLayout storage layout = WalletStorage.getStorage();
        return layout.isValidators[validator];
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
                validationData = IValidator(validator).validateSignature(userOp, userOpHash);
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
     * External function to update validator
     */
    function setValidator(address validator, bool isActive) external virtual;

    /**
     * External function to update validator
     */
    function isValidator(address validator) external view virtual returns (bool);

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
                    magicValue = bytes4(0xffffffff);
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
