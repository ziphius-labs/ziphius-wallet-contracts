// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./Wallet.sol";

/**
 * @title Wallet Factory
 * @author Terry
 * @notice wallet factory use to create new wallet base on ERC1967Proxy
 */
contract WalletFactory {
    Wallet public immutable walletImplement;

    constructor(address entryPoint) {
        walletImplement = new Wallet(entryPoint);
    }

    function createWallet(address owner, bytes32 salt) external returns (Wallet) {
        address wallet = getWalletAddress(owner, salt);
        uint codeSize = wallet.code.length;
        if (codeSize > 0) {
            return Wallet(payable(wallet));
        }

        return Wallet(payable(new ERC1967Proxy{ salt: salt }(
            address(walletImplement),
            abi.encodeCall(Wallet.init, (owner))
        )));
    }

    function getWalletAddress(address owner, bytes32 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                address(walletImplement),
                abi.encodeCall(Wallet.init, (owner))
            )
        )));
    }
}
