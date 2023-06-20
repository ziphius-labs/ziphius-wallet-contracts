// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IWallet.sol";
import "./core/AbstractionEngine.sol";
import "./libraries/DefaultCallbackHandler.sol";

/**
 * @title Ziphius Wallet
 * @author Terry
 * @notice Ziphius wallet
 */
contract Wallet is AbstractionEngine, IWallet, UUPSUpgradeable, DefaultCallbackHandler {
    IEntryPoint private immutable _entryPoint;

    constructor(address entryPoint_) {
        _entryPoint = IEntryPoint(entryPoint_);
    }

    function _isValidCaller() internal view override(AbstractionEngine) returns (bool) {
        return msg.sender == address(entryPoint()) || msg.sender == address(this);
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

    function init(address validator) external initializer {
        _setValidator(validator, true);
    }

    /// @inheritdoc AbstractionEngine
    function setValidator(address validator, bool isActive) external override(AbstractionEngine) authorized {
        _setValidator(validator, isActive);
        emit SetValidator(validator, isActive);
    }

    function isValidator(address validator) external view override(AbstractionEngine) returns (bool) {
        return _isValidator(validator);
    }

    /// @inheritdoc IWallet
    function execute(address dest, uint256 value, bytes calldata func) external override(IWallet) authorized {
        _call(dest, value, func);
        emit Execute();
    }

    /// @inheritdoc IWallet
    function executeBatch(address[] calldata dest, bytes[] calldata func) external override(IWallet) authorized {
        require(dest.length == func.length, "Core Wallet: Wrong array lengths");
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(DefaultCallbackHandler, AbstractionEngine) returns (bool) {
        return interfaceId == type(IWallet).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    function withdrawTo(address payable to, uint256 amount) public payable authorized {
        entryPoint().withdrawTo(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        require(_isValidCaller(), "Core Wallet: Invalid Caller");
    }
}