// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

interface IValidator {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash) external view returns(uint256);
    function validateSignature(bytes32 hash, bytes calldata signature) external view returns(bool);
}
