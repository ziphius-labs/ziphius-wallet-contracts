// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library WalletStorage {
    bytes32 private constant STORAGE_POSITION = keccak256("ziphius.contracts.v1");

    struct StorageLayout {
        mapping(address => bool) isValidators;
    }

    function getStorage() internal pure returns (StorageLayout storage sw) {
        bytes32 storagePosition = STORAGE_POSITION;
        assembly {
            sw.slot := storagePosition
        }
    }
}
