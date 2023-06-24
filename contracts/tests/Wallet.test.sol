// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@account-abstraction/contracts/core/EntryPoint.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "../WalletFactory.sol";
import "../Wallet.sol";

import "./ERC4337Utils.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

using ERC4337Utils for EntryPoint;

contract WalletTest is Test {

    EntryPoint entryPoint;
    WalletFactory walletFactory;

    address owner;
    uint256 ownerKey;

    address payable beneficiary;

    function setUp() external {
        ownerKey = uint256(keccak256("owner"));
        owner = vm.addr(ownerKey);
        entryPoint = new EntryPoint();

        walletFactory = new WalletFactory(address(entryPoint));
        beneficiary = payable(address(vm.addr(uint256(keccak256("beneficiary")))));
    }

    function test_CreateWallet() external {
        Wallet walletAddress = Wallet(walletFactory.getWalletAddress(owner, bytes32(uint256(1))));

        vm.deal(address(walletAddress), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(walletAddress), "");
        op.initCode = abi.encodePacked(bytes20(address(walletFactory)), abi.encodeWithSelector(walletFactory.createWallet.selector, owner, bytes32(uint256(1))));
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
    }

    function test_SendEth() external {
        Wallet wallet = Wallet(walletFactory.getWalletAddress(owner, bytes32(uint256(1))));

        vm.deal(address(wallet), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(wallet), "");
        op.initCode = abi.encodePacked(bytes20(address(walletFactory)), abi.encodeWithSelector(walletFactory.createWallet.selector, owner, bytes32(uint256(1))));
        op.callData = abi.encodeWithSelector(wallet.execute.selector, beneficiary, 1, "");
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
    }
}
