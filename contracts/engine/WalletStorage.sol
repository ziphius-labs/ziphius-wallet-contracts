// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

library WalletStorage {
    bytes32 private constant _KEYSTORE_POSITION = keccak256("ziphius.contracts.v1.keystore");

    function getKeyStore() internal view returns(address) {
        return StorageSlot.getAddressSlot(_KEYSTORE_POSITION).value;
    }
}
