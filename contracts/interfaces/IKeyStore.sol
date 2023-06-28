// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IKeyStore {
    function setValidators(address[] calldata validators, bool[] calldata isActives, uint256 walletIndex) external;
    function init(address initValidator) external;
    function isValidator(address validator) external view returns (bool);
}
