// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract Paymaster is BasePaymaster {
    address private _signer;

    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct PaymasterData {
        address token; // if token == address(0), transaction will be sponsor
        uint48 validUntil;
        uint256 exchangeRate;
        bytes signature;
    }

    uint256 constant public COST_OF_POST = 35000;

    constructor(address entryPoint, address owner, address signer) BasePaymaster(IEntryPoint(entryPoint)) {
        _transferOwnership(owner);

        _signer = signer;
    }

    function _packUserOp(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            userOp.sender,
            userOp.nonce,
            keccak256(userOp.initCode),
            keccak256(userOp.callData),
            userOp.callGasLimit,
            userOp.verificationGasLimit,
            userOp.preVerificationGas,
            userOp.maxFeePerGas,
            userOp.maxPriorityFeePerGas
        ));
    }

    function _hashUserOp(UserOperation calldata userOp, PaymasterData memory paymasterData) internal view returns (bytes32) {
        return keccak256(abi.encode(
            _packUserOp(userOp),
            block.chainid,
            address(this),
            address(paymasterData.token),
            paymasterData.validUntil,
            paymasterData.exchangeRate
        ));
    }

    function _parsePaymasterData(bytes calldata paymasterData) internal pure returns (PaymasterData memory) {
        address token = address(bytes20(paymasterData[20:40]));
        uint48 validUntil = uint48(bytes6(paymasterData[40:47]));
        uint256 exchangeRate = uint256(bytes32(paymasterData[47:79]));
        return PaymasterData(
            token,
            validUntil,
            exchangeRate,
            paymasterData[79:]
        );
    }

    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost) internal view override returns (bytes memory, uint256) {
        (userOpHash, maxCost);

        PaymasterData memory paymasterData = _parsePaymasterData(userOp.paymasterAndData);

        bytes32 hash = _hashUserOp(userOp, paymasterData).toEthSignedMessageHash();
        if (_signer != hash.recover(paymasterData.signature)) {
            return ("", _packValidationData(true, paymasterData.validUntil, 0));
        }

        bytes memory context = abi.encode(
            userOp.sender,
            paymasterData.token,
            paymasterData.exchangeRate,
            userOp.maxFeePerGas,
            userOp.maxPriorityFeePerGas
        );

        return (context, _packValidationData(false, paymasterData.validUntil, 0));
    }

    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        (mode); // we don't care about mode
        (address sender, address token, uint256 exchangeRate, uint256 maxFeePerGas, uint256 maxPriorityFeePerGas)
            = abi.decode(context, (address, address, uint256, uint256, uint256));

        if (token == address(0)) {
            // sponsor mode
            return;
        }

        uint256 gasPricePostOp;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            gasPricePostOp = maxFeePerGas;
        } else {
            gasPricePostOp = Math.min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
        uint256 actualTokenCost = ((actualGasCost + (COST_OF_POST * gasPricePostOp)) * exchangeRate) / 1e18;
        IERC20(token).safeTransferFrom(sender, owner(), actualTokenCost);
    }

    function changeSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }
}
