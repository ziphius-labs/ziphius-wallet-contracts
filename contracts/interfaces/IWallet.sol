// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IWallet {
    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external;
    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    event UpdateValidator(address newValidator);
    event Execute();
}
