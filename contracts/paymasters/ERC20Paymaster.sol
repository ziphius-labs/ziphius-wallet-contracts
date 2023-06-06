// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Paymaster is IPaymaster {
    address private immutable _nativeTokenPriceFeed;
    IEntryPoint private immutable _entryPoint;

    uint256 fee;

    constructor(address nativeTokenPriceFeed, address entryPoint) {
        _nativeTokenPriceFeed = nativeTokenPriceFeed;
        _entryPoint = IEntryPoint(entryPoint);
    }

    /// validate the call is made from a valid entrypoint
    function _requireFromEntryPoint() private view {
        require(msg.sender == address(_entryPoint));
    }


    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost) external returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external {
        _requireFromEntryPoint();
    }

    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost) internal {
        require(
            userOp.verificationGasLimit > 45000,
            "Paymaster: gas too low for postOp"
        );
    }
}
