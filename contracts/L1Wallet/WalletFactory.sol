// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./L1Wallet.sol";
import "../libraries/CustomERC1967Proxy.sol";

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

    function createWallet(address keyStore, uint256 walletIndex) external returns (Wallet) {
        address walletAddress = getWalletAddress(keyStore, walletIndex);
        uint codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return Wallet(payable(walletAddress));
        }

        bytes32 salt = keccak256(abi.encode(keyStore, walletIndex));
        new CustomERC1967{ salt: salt }();

        CustomERC1967(walletAddress).init(walletImplement, abi.encodeCall(Wallet.init, (keyStore)));
    }

    function getWalletAddress(address keyStore, uint256 walletIndex) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(keyStore, walletIndex));
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(
            type(CustomERC1967).creationCode,
            ""
        )));
    }
}
