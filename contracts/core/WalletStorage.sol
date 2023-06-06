// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract WalletStorage {
    struct SafeWhaleV1Storage {
        address masterValidator;

        mapping(address => address) validators;
        mapping(bytes4 => bool) onlyMasterValidatorFunctions;
    }

    function _storageLayout() internal pure returns (SafeWhaleV1Storage storage sw) {
        bytes32 storagePosition = bytes32(uint256(keccak256("safewhale.storage")) - 1);
        assembly {
            sw.slot := storagePosition
        }
    }
}
