// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Stateful local mock of the QoreLease Native registry used only for
///         Foundry atomicity/response tests. It is NOT a Diana runtime.
contract MockNativeTarget {
    struct Record {
        bool exists;
        uint256 units;
        uint256 deliveredUnits;
        bool finalized;
        bool released;
        bytes32 termsHash;
    }

    uint256 public immutable capacity;
    uint256 public totalReserved;
    address public authorizedEscrow;
    address public bridge;
    mapping(bytes32 => Record) public reservations;

    bool public forceReject;
    bool public returnEmpty;
    bool public returnMalformed;
    bool public returnWrongJob;
    bool public returnWrongTerms;
    bool public returnWrongOperation;

    event Dispatch(string operation, bytes payload, address caller);

    function isFinalized(bytes32 jobId) external view returns (bool) {
        return reservations[jobId].finalized;
    }

    function isReleased(bytes32 jobId) external view returns (bool) {
        return reservations[jobId].released;
    }

    constructor(uint256 capacity_, address bridge_, address authorizedEscrow_) {
        capacity = capacity_;
        bridge = bridge_;
        authorizedEscrow = authorizedEscrow_;
    }

    function setBehaviour(
        bool forceReject_,
        bool returnEmpty_,
        bool returnMalformed_,
        bool returnWrongJob_,
        bool returnWrongTerms_,
        bool returnWrongOperation_
    ) external {
        forceReject = forceReject_;
        returnEmpty = returnEmpty_;
        returnMalformed = returnMalformed_;
        returnWrongJob = returnWrongJob_;
        returnWrongTerms = returnWrongTerms_;
        returnWrongOperation = returnWrongOperation_;
    }

    /// @dev Called by MockCrossVMBridge. The bridge passes through the EVM caller
    ///      identity; checking it here approximates the Native `info.sender` rule.
    function dispatch(bytes calldata payload, address caller) external returns (bytes memory) {
        require(msg.sender == bridge, "only bridge");
        require(caller == authorizedEscrow, "unauthorized native caller");

        if (forceReject) revert("Native reservation rejected");
        if (returnEmpty) return "";
        if (returnMalformed) return abi.encodePacked(uint8(1), "garbage");

        string memory body = string(payload);
        if (_contains(body, '"reserve"')) {
            emit Dispatch("reserve", payload, caller);
            return _reserve(body);
        }
        if (_contains(body, '"finalize"')) {
            emit Dispatch("finalize", payload, caller);
            return _finalize(body);
        }
        if (_contains(body, '"release"')) {
            emit Dispatch("release", payload, caller);
            return _release(body);
        }
        revert("unknown native operation");
    }

    function _reserve(string memory body) internal returns (bytes memory) {
        bytes32 jobId = _bytes32Field(body, "job_id");
        bytes32 termsHash = _bytes32Field(body, "terms_hash");
        uint256 units = _uintField(body, "units");
        require(units > 0, "zero units");
        require(!reservations[jobId].exists, "duplicate job id");
        require(totalReserved + units <= capacity, "insufficient capacity");

        reservations[jobId] = Record({exists: true, units: units, deliveredUnits: 0, finalized: false, released: false, termsHash: termsHash});
        totalReserved += units;

        return _response(returnWrongOperation ? 9 : 1, jobId, termsHash, units, 0, capacity - totalReserved);
    }

    function _finalize(string memory body) internal returns (bytes memory) {
        bytes32 jobId = _bytes32Field(body, "job_id");
        bytes32 termsHash = _bytes32Field(body, "terms_hash");
        uint256 delivered = _uintField(body, "delivered_units");
        Record storage record = reservations[jobId];
        require(record.exists, "unknown reservation");
        require(!record.finalized && !record.released, "reservation not active");
        require(delivered <= record.units, "delivered exceeds reserved");

        record.deliveredUnits = delivered;
        record.finalized = true;
        totalReserved -= record.units;

        return _response(returnWrongOperation ? 9 : 2, jobId, termsHash, record.units, delivered, capacity - totalReserved);
    }

    function _release(string memory body) internal returns (bytes memory) {
        bytes32 jobId = _bytes32Field(body, "job_id");
        Record storage record = reservations[jobId];
        require(record.exists, "unknown reservation");
        require(!record.finalized && !record.released, "reservation not active");

        record.released = true;
        totalReserved -= record.units;
        return _response(returnWrongOperation ? 9 : 3, jobId, record.termsHash, record.units, 0, capacity - totalReserved);
    }

    function _response(uint8 op, bytes32 jobId, bytes32 termsHash, uint256 reserved, uint256 delivered, uint256 available)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                uint256(1),
                uint256(op),
                returnWrongJob ? bytes32(keccak256("wrong-job")) : jobId,
                returnWrongTerms ? bytes32(keccak256("wrong-terms")) : termsHash,
                reserved,
                delivered,
                available
            );
    }

    function _contains(string memory source, string memory needle) internal pure returns (bool) {
        bytes memory hay = bytes(source);
        bytes memory nn = bytes(needle);
        if (nn.length > hay.length) return false;
        for (uint256 i = 0; i + nn.length <= hay.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < nn.length; j++) {
                if (hay[i + j] != nn[j]) {
                    hit = false;
                    break;
                }
            }
            if (hit) return true;
        }
        return false;
    }

    function _bytes32Field(string memory source, string memory field) internal pure returns (bytes32) {
        string memory prefix = string.concat('"', field, '":"0x');
        bytes memory hay = bytes(source);
        bytes memory pre = bytes(prefix);
        uint256 start;
        bool found;
        for (uint256 i = 0; i + pre.length <= hay.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < pre.length; j++) {
                if (hay[i + j] != pre[j]) {
                    hit = false;
                    break;
                }
            }
            if (hit) {
                start = i + pre.length;
                found = true;
                break;
            }
        }
        require(found && start + 64 <= hay.length, "field missing");
        return _parseHex32(hay, start);
    }

    function _parseHex32(bytes memory data, uint256 start) internal pure returns (bytes32 out) {
        for (uint256 i = 0; i < 32; i++) {
            uint256 shift = 8 * (31 - i);
            out = bytes32(uint256(out) | (uint256(_hexDigit(data[start + i * 2])) << (shift + 4)));
            out = bytes32(uint256(out) | (uint256(_hexDigit(data[start + i * 2 + 1])) << shift));
        }
    }

    function _hexDigit(bytes1 c) internal pure returns (uint8) {
        if (c >= "0" && c <= "9") return uint8(c) - 48;
        if (c >= "a" && c <= "f") return uint8(c) - 87;
        if (c >= "A" && c <= "F") return uint8(c) - 55;
        revert("bad hex");
    }

    function _uintField(string memory source, string memory field) internal pure returns (uint256) {
        string memory prefix = string.concat('"', field, '":"');
        bytes memory hay = bytes(source);
        bytes memory pre = bytes(prefix);
        uint256 start;
        bool found;
        for (uint256 i = 0; i + pre.length <= hay.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < pre.length; j++) {
                if (hay[i + j] != pre[j]) {
                    hit = false;
                    break;
                }
            }
            if (hit) {
                start = i + pre.length;
                found = true;
                break;
            }
        }
        require(found, "field missing");
        uint256 value = 0;
        bool digitSeen;
        for (uint256 i = start; i < hay.length; i++) {
            bytes1 c = hay[i];
            if (c < "0" || c > "9") break;
            value = value * 10 + (uint8(c) - 48);
            digitSeen = true;
        }
        require(digitSeen, "bad uint");
        return value;
    }
}