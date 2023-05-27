// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../interfaces/IValidator.sol";

contract ECDSAValidator is IValidator {
    event Register(address account, address owner);
    mapping(address => address) _owners;

    function register(address owner) external {
    }

    function transferOwner(address newOwner) external {
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash) external view override returns(uint256) {
        return 1;
    }
    function validateSignature(bytes32 hash, bytes calldata signature) external view override returns(bool) {
        return true;
    }
}
