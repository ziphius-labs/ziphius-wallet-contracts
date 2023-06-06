// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

interface IValidator is IERC1271 {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash) external returns (uint256 validationData);
}
