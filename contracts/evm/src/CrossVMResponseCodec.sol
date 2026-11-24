// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title CrossVMResponseCodec
/// @notice Strict decoder for the proposed v1 Native bridge response layout.
/// @dev IMPORTANT: the layout below (seven 32-byte ABI words, no dynamic offset)
///      is the format implemented by `qorelease-registry`'s `wire_response`.
///      The QoreChain Diana precompile's actual passthrough encoding of a
///      CosmWasm `Response.data` is NOT VERIFIED. Until G0-D evidence exists,
///      every consumer must fail closed on length or field mismatch instead of
///      assuming a different encoding. See docs/INTERFACES.md and
///      docs/decisions/ADR-0007-crossvm-response-encoding.md.
library CrossVMResponseCodec {
    uint256 internal constant RESPONSE_BYTES = 7 * 32;
    uint8 internal constant VERSION_1 = 1;

    /// Operation codes shared with the Native contract.
    uint8 internal constant OP_RESERVE = 1;
    uint8 internal constant OP_FINALIZE = 2;
    uint8 internal constant OP_RELEASE = 3;

    struct NativeResult {
        uint8 version;
        uint8 operation;
        bytes32 jobId;
        bytes32 termsHash;
        uint256 reservedUnits;
        uint256 deliveredUnits;
        uint256 availableUnits;
    }

    error MalformedBridgeResponse(uint256 length);
    error UnsupportedResponseVersion(uint8 version);
    error UnexpectedBridgeOperation(uint8 operation);

    function decode(bytes memory data) internal pure returns (NativeResult memory result) {
        if (data.length != RESPONSE_BYTES) {
            revert MalformedBridgeResponse(data.length);
        }
        result.version = uint8(uint256(word(data, 0)));
        result.operation = uint8(uint256(word(data, 1)));
        result.jobId = word(data, 2);
        result.termsHash = word(data, 3);
        result.reservedUnits = uint256(word(data, 4));
        result.deliveredUnits = uint256(word(data, 5));
        result.availableUnits = uint256(word(data, 6));

        if (result.version != VERSION_1) {
            revert UnsupportedResponseVersion(result.version);
        }
    }

    function decodeOperation(bytes memory data, uint8 expected) internal pure returns (NativeResult memory result) {
        result = decode(data);
        if (result.operation != expected) {
            revert UnexpectedBridgeOperation(result.operation);
        }
    }

    function word(bytes memory data, uint256 index) private pure returns (bytes32 out) {
        uint256 offset = 32 + index * 32;
        assembly ("memory-safe") {
            out := mload(add(data, offset))
        }
    }
}