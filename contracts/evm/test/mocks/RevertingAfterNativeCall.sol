// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {QoreLeaseEscrow} from "../../src/QoreLeaseEscrow.sol";

/// @notice Local atomicity harness: completes a Native-backed reservation and
///         then deliberately reverts the enclosing EVM transaction. The stateful
///         native mock shares this transaction's journal, so its changes must roll
///         back with the EVM side. This is a local test only, not Diana evidence.
contract RevertingAfterNativeCall {
    QoreLeaseEscrow public immutable escrow;

    constructor(QoreLeaseEscrow escrow_) {
        escrow = escrow_;
    }

    function acceptThenRevert(bytes32 jobId) external {
        escrow.acceptOffer(jobId);
        revert("forced later EVM revert");
    }
}