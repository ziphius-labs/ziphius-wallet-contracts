// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IKeyStore {
    function init(address initValidator) external;
    function isValidator(address validator) external view returns (bool);
}
