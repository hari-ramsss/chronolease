// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICrossVMBridge} from "./interfaces/ICrossVMBridge.sol";

/// @title CrossVMBridgeService
/// @notice Isolated, reusable low-level caller for the QoreChain EVM -> Native bridge.
/// @dev Design rules enforced here, mirroring the specification:
///      - A normal CALL is used (never STATICCALL) with an explicit zero value.
///      - A failed low-level call reverts with the bridge's own revert data bubbled up.
///      - Empty return data is surfaced to the caller, which must then fail closed.
///      - No EVM value is ever attached: Native funds cannot cross through the precompile.
library CrossVMBridgeService {
    /// @dev Target VM id documented for QoreChain Native (CosmWasm).
    uint8 internal constant TARGET_VM_NATIVE = 1;

    /// @dev Documented Diana EVM -> Native synchronous bridge precompile.
    address internal constant DIANA_BRIDGE = 0x0000000000000000000000000000000000000901;

    error BridgeCallFailed(bytes revertData);
    error EmptyBridgeResponse();

    /// @notice Calls the Native bridge and returns the raw response bytes.
    /// @param bridge Bridge address. Configuration only; not a product-logic value.
    /// @param targetContract Native contract address (`qor1...`) as a string.
    /// @param payload UTF-8 JSON CosmWasm execute message.
    function callNative(
        address bridge,
        string memory targetContract,
        bytes memory payload
    ) internal returns (bytes memory) {
        if (bridge == address(0)) revert BridgeCallFailed("bridge not configured");
        // Explicit ETH value of 0. Native funds must not be attached to this call.
        (bool ok, bytes memory ret) = bridge.call{value: 0}(
            abi.encodeWithSelector(ICrossVMBridge.executeCrossVMCall.selector, TARGET_VM_NATIVE, targetContract, payload)
        );
        if (!ok) {
            // Bubble up the bridge/target revert reason; the caller fails closed.
            revert BridgeCallFailed(ret);
        }
        // Solidity interfaces ABI-encode dynamic `bytes` as offset + length + data.
        // The bridge documentation describes raw passthrough bytes; accept both
        // shapes, but only after normalising so empty/malformed data fails closed.
        bytes memory raw = unwrapReturn(ret);
        if (raw.length == 0) {
            // An inactive precompile can report success with no return data.
            revert EmptyBridgeResponse();
        }
        return raw;
    }

    /// @dev Normalises ABI-encoded `bytes` to raw bytes; leaves raw responses intact.
    function unwrapReturn(bytes memory ret) internal pure returns (bytes memory) {
        if (ret.length < 64) return ret;
        uint256 offset;
        uint256 length;
        assembly ("memory-safe") {
            offset := mload(add(ret, 32))
            length := mload(add(ret, 64))
        }
        if (offset == 0x20 && length == ret.length - 64) {
            bytes memory inner = new bytes(length);
            for (uint256 i = 0; i < length; i++) {
                inner[i] = ret[64 + i];
            }
            return inner;
        }
        return ret;
    }

    /// @notice JSON-encodes a 32-byte value as a 0x-prefixed lowercase hex string.
    function encodeBytes32(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory buffer = new bytes(66);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            buffer[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            buffer[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(buffer);
    }
}