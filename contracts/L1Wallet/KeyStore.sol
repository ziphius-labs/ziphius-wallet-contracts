// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "../libraries/CustomERC1967Proxy.sol";

/**
 * @title Ziphius Wallet
 * @author Terry
 * @notice Ziphius wallet
 */
contract KeyStore {
    address private immutable _factory;
    mapping(address => bool) private _validators;

    event SetValidator(address[] validators, bool[] isActives);

    constructor(address initValidator) {
        _factory = msg.sender;
        _validators[initValidator] = true;
    }

    /**
     * @notice only accept entrypoint
     */
    function _requireFromWallet(uint256 walletIndex) internal view returns (bool) {
        bytes32 salt = keccak256(abi.encode(address(this), walletIndex));
        address wallet = Create2.computeAddress(salt, keccak256(abi.encodePacked(
            type(CustomERC1967).creationCode,
            "",
        )), _factory);

        require(wallet == msg.sender, "Invalid caller");
    }

    function setValidators(address[] memory validators, bool[] memory isActives, uint256 walletIndex) external {
        _requireFromWallet(walletIndex);

        for (uint i = 0; i < validators.length; i++) {
            _validators[validators[i]] = isActives[i];

        }
        emit SetValidator(validators, isActives);
    }

    function isValidator(address validator) external view returns (bool) {
        return _validators[validator];
    }
}
