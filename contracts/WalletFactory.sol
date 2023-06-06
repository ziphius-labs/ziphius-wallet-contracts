// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./SafeWhale.sol";

contract WalletFactory {
    SafeWhale public immutable walletImplement;

    constructor(address entryPoint) {
        walletImplement = new SafeWhale(entryPoint);
    }

    function createSafeWhale(address owner, bytes32 salt) external returns (SafeWhale) {}

    function getSafeWhaleAddress(address owner, bytes32 salt) external view returns (SafeWhale) {}
}
