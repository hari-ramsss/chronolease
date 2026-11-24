// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title QoreChain synchronous EVM -> Native bridge interface
/// @notice Documented precompile signature: `executeCrossVMCall(uint8,string,bytes)`.
/// The Diana address documented by QoreChain is
/// 0x0000000000000000000000000000000000000901 with targetVM = 1 for Native.
/// Live active/inactive state must be re-read before deployment; an inactive
/// precompile can return success with empty data, so callers must reject empty
/// return data rather than trusting the call status alone.
interface ICrossVMBridge {
    function executeCrossVMCall(
        uint8 targetVm,
        string calldata targetContract,
        bytes calldata payload
    ) external payable returns (bytes memory);
}