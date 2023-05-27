// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";

abstract contract CoreWallet  {
    IEntryPoint public immutable entryPoint; // The entry point of the contract

    constructor(address entryPoint_) {
        entryPoint = IEntryPoint(entryPoint_);
    }

    // Modifier to check if the function is called by the entry point, the contract itself or the owner
    modifier onlyFromEntryPointOrOwnerOrSelf() {
        require(
            msg.sender == address(entryPoint) || msg.sender == address(this),
            "account: not from entrypoint or owner or self"
        );
        _;
    }
}
