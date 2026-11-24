// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockNativeTarget} from "./MockNativeTarget.sol";

/// @notice Local stateful stand-in for precompile 0x0901. The escrow's bridge
///         address is a configuration input, so tests point it here. Nothing in
///         these tests proves Diana precompile behaviour.
contract MockCrossVMBridge {
    address public nativeTarget;
    bool public forceRevert;
    uint8 public lastTargetVm;
    string public lastTargetContract;
    bytes public lastPayload;
    address public lastCaller;

    event CrossVMCall(uint8 targetVm, string targetContract, bytes payload, address caller);

    constructor(address nativeTarget_) {
        nativeTarget = nativeTarget_;
    }

    function setForceRevert(bool value) external {
        forceRevert = value;
    }

    function setNativeTarget(address value) external {
        nativeTarget = value;
    }

    function executeCrossVMCall(
        uint8 targetVm,
        string calldata targetContract,
        bytes calldata payload
    ) external payable returns (bytes memory) {
        lastTargetVm = targetVm;
        lastTargetContract = targetContract;
        lastPayload = payload;
        lastCaller = msg.sender;
        emit CrossVMCall(targetVm, targetContract, payload, msg.sender);

        if (forceRevert) revert("bridge forced failure");
        require(msg.value == 0, "no EVM value through bridge");
        return MockNativeTarget(nativeTarget).dispatch(payload, msg.sender);
    }
}