// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IValidator {
    function validateSignature(bytes32 hash, bytes memory signature) external view returns (uint256 validationData);
}
