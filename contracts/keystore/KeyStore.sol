// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/CustomERC1967.sol";

import "../interfaces/IKeyStore.sol";
import "forge-std/console.sol";

/**
 * @title Ziphius Keystore
 * @author Terry
 * @notice Ziphius Keystore, this smart contract will be deploy to Ethereum only
 */
contract KeyStore is IKeyStore, Initializable {
    address private immutable _factory;
    mapping(address => bool) private _validators;

    event SetValidator(address[] validators, bool[] isActives);

    constructor() {
        _factory = msg.sender;
    }

    function init(address initValidator) external override initializer {
        _validators[initValidator] = true;
    }

    /**
     * @notice only accept wallet
     */
    function _requireFromWallet(uint256 walletIndex) internal view {
        bytes32 salt = keccak256(abi.encode(address(this), walletIndex));
        address wallet = Create2.computeAddress(salt, keccak256(abi.encodePacked(
            type(CustomERC1967).creationCode,
            ""
        )), _factory);

        require(wallet == msg.sender, "Invalid caller");
    }

    function setValidators(address[] calldata validators, bool[] calldata isActives, uint256 walletIndex) external override {
        _requireFromWallet(walletIndex);

        for (uint i = 0; i < validators.length; i++) {
            _validators[validators[i]] = isActives[i];

        }
        emit SetValidator(validators, isActives);
    }

    function isValidator(address validator) external view override returns (bool) {
        return _validators[validator];
    }
}