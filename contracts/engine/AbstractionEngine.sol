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
import "../interfaces/IKeyStore.sol";
import "./WalletStorage.sol";

/**
 * @title Abstraction Engine
 * @author Terry
 * @notice CoreWallet implement authentication methods in Smart Contracts Wallet inherit BaseAccount
 */
abstract contract AbstractionEngine is BaseAccount, IERC1271, ERC165, Initializable {
    using Address for address;
    using ECDSA for bytes32;

    event SetValidator(address[] validators, bool[] isActives);

    /**
     * validate userOp
     */
    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal returns (uint256 validationData) {
        address validator = address(bytes20(userOp.signature[:20]));
        bytes memory signature = userOp.signature[20:];

        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());

        if (keyStore.isValidator(validator)) {
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
     * External function to update validator
     */
    function setValidators(address[] memory validator, bool[] memory isActive, uint256 walletIndex) external virtual;

    /**
     * External function to update validator
     */
    function isValidator(address validator) external view virtual returns (bool);

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4 magicValue) {
        address validator = address(bytes20(signature[:20]));
        bytes memory trueSignature = signature[20:];

        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());

        if (keyStore.isValidator(validator)) {
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
