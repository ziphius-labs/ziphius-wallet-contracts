// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./SafeWhale.sol";

/**
 * @title SafeWhale Wallet Factory
 * @author Terry
 * @notice SafeWhale wallet factory use to create new wallet base on ERC1967Proxy
 */
contract WalletFactory {
    SafeWhale public immutable walletImplement;

    constructor(address entryPoint) {
        walletImplement = new SafeWhale(entryPoint);
    }

    function createSafeWhale(address owner, bytes32 salt) external returns (SafeWhale) {
        address wallet = getSafeWhaleAddress(owner, salt);
        uint codeSize = wallet.code.length;
        if (codeSize > 0) {
            return SafeWhale(payable(wallet));
        }

        return SafeWhale(payable(new ERC1967Proxy{ salt: salt }(
            address(walletImplement),
            abi.encodeCall(SafeWhale.init, (owner))
        )));
    }

    function getSafeWhaleAddress(address owner, bytes32 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                address(walletImplement),
                abi.encodeCall(SafeWhale.init, (owner))
            )
        )));
    }
}
