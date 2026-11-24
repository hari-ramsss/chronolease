// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Like} from "./interfaces/IERC20Like.sol";
import {CrossVMBridgeService} from "./CrossVMBridgeService.sol";
import {CrossVMResponseCodec} from "./CrossVMResponseCodec.sol";
import {QoreLeaseConfig, QoreLeaseMonitorRoles} from "./QoreLeaseConfig.sol";

/// @title QoreLeaseEscrow
/// @notice Buyer-side fUSD escrow with Native capacity reservation and verified
///         delivery settlement through the QoreChain synchronous cross-VM bridge.
///
/// @dev Product invariant enforced here:
///      buyer fUSD can only be committed after the Native registry has accepted the
///      matching capacity commitment, and payout always references the same job id,
///      terms hash and accepted delivery evidence.
///
///      Asset separation: fUSD (buyer payment) lives in this contract only. Provider
///      QOR collateral is deposited into and locked by the Native registry through
///      Native transactions. The EVM side never holds or moves QOR.
///
///      Explicit machine:
///      None -> Created -> Funded -> Reserved -> Settled
///                                        \-> Refunded
contract QoreLeaseEscrow is QoreLeaseConfig, QoreLeaseMonitorRoles {
    using CrossVMBridgeService for address;

    enum JobState {
        None, // 0 unknown job
        Created, // 1 buyer signed terms; no funds committed
        Funded, // 2 fUSD is escrowed; Native capacity not yet accepted
        Reserved, // 3 Native accepted the capacity commitment
        Settled, // 4 evidence accepted, provider paid
        Refunded // 5 reservation released, buyer refunded
    }

    struct Job {
        bytes32 jobId;
        address buyer;
        address providerPayout;
        bytes32 termsHash;
        bytes32 slotTermsHash; // hash of the published Native slot terms
        string providerId; // Native provider reference
        string slotId; // Native slot reference
        uint64 startTime;
        uint64 endTime;
        uint32 units;
        uint256 pricePerUnit;
        uint256 totalEscrow; // fUSD held for this job
        uint256 escrowPaidOut;
        uint256 escrowRefunded;
        uint256 deliveredUnits;
        bytes32 evidenceHash;
        bool evidenceAccepted;
        JobState state;
        uint64 createdAt;
    }

    IERC20Like public immutable fusd;
    uint256 public escrowedTotal;
    bytes32[] public jobIds;

    mapping(bytes32 => Job) internal _jobs;
    /// One accepted evidence digest per job; a report cannot be reused across jobs.
    mapping(bytes32 => mapping(bytes32 => bool)) public evidenceConsumed;

    event RequestCreated(bytes32 indexed jobId, address indexed buyer, bytes32 termsHash, uint32 units);
    event FundsEscrowed(bytes32 indexed jobId, address indexed buyer, uint256 amount);
    event CapacityReserved(bytes32 indexed jobId, uint256 reservedUnits, uint256 availableUnits);
    event EvidenceSubmitted(bytes32 indexed jobId, address indexed monitor, bytes32 evidenceHash, uint256 deliveredUnits);
    event JobSettled(bytes32 indexed jobId, address indexed providerPayout, uint256 providerPaid, uint256 buyerRefunded, uint256 deliveredUnits);
    event JobRefunded(bytes32 indexed jobId, uint256 buyerRefunded);
    event MonitorAuthorized(address indexed monitor, bool allowed);

    error InvalidJobId();
    error UnknownJob();
    error NotBuyer();
    error InvalidState(JobState current);
    error SlotWindowInvalid();
    error UnitsZero();
    error PriceZero();
    error ProviderPayoutZero();
    error NativeRegistryNotConfigured();
    error BridgeNotConfigured();
    error EscrowBalanceShortfall();
    error WrongJobInResponse(bytes32 expected, bytes32 actual);
    error TermsMismatch(bytes32 expected, bytes32 actual);
    error InvalidDeliveredUnits(uint256 delivered, uint256 reserved);
    error EvidenceAlreadyConsumed(bytes32 jobId, bytes32 evidenceHash);
    error EvidenceHashMismatch(bytes32 expected, bytes32 actual);
    error EvidenceNotAccepted();
    error ZeroAmount();

    constructor(
        address fusd_,
        address admin_,
        address bridge_,
        string memory nativeRegistry_,
        string memory escrowNativeIdentity_
    ) QoreLeaseConfig(admin_) {
        if (fusd_ == address(0)) revert ZeroAddress();
        if (bridge_ == address(0)) revert ZeroAddress();
        fusd = IERC20Like(fusd_);
        bridgeAddress = bridge_;
        nativeRegistryAddress = nativeRegistry_;
        escrowNativeIdentity = escrowNativeIdentity_;
    }

    // ---------------------------------------------------------------- admin

    function authorizeMonitor(address monitor, bool allowed) external onlyAdmin {
        _authorizeMonitor(monitor, allowed);
        emit MonitorAuthorized(monitor, allowed);
    }

    function _authorizeMonitor(address monitor, bool allowed) internal override {
        authorizedMonitor[monitor] = allowed;
    }

    // ---------------------------------------------------------------- request / escrow

    /// @notice Buyer creates a service request with immutable terms.
    /// @param salt Buyer-chosen salt; with the buyer address it makes the job id
    ///        deterministic and replay-resistant.
    /// @param slotTermsHash The Native published slot terms hash the job commits to.
    function createRequest(
        bytes32 salt,
        bytes32 termsHash,
        bytes32 slotTermsHash,
        string calldata providerId,
        string calldata slotId,
        uint64 startTime,
        uint64 endTime,
        uint32 units,
        uint256 pricePerUnit,
        address providerPayout
    ) external returns (bytes32 jobId) {
        if (endTime <= startTime) revert SlotWindowInvalid();
        if (units == 0) revert UnitsZero();
        if (pricePerUnit == 0) revert PriceZero();
        if (providerPayout == address(0)) revert ProviderPayoutZero();

        jobId = keccak256(
            abi.encode(address(this), msg.sender, salt, termsHash, slotTermsHash, providerId, slotId, units, pricePerUnit)
        );
        if (_jobs[jobId].state != JobState.None) revert InvalidJobId();

        Job storage job = _jobs[jobId];
        job.jobId = jobId;
        job.buyer = msg.sender;
        job.providerPayout = providerPayout;
        job.termsHash = termsHash;
        job.slotTermsHash = slotTermsHash;
        job.providerId = providerId;
        job.slotId = slotId;
        job.startTime = startTime;
        job.endTime = endTime;
        job.units = units;
        job.pricePerUnit = pricePerUnit;
        job.state = JobState.Created;
        job.createdAt = uint64(block.timestamp);

        jobIds.push(jobId);
        emit RequestCreated(jobId, msg.sender, termsHash, units);
    }

    /// @notice Buyer accepts the offer: fUSD is escrowed and Native capacity is
    ///         reserved in the same transaction. A Native rejection reverts both.
    function acceptOffer(bytes32 jobId) external {
        Job storage job = _jobs[jobId];
        if (job.state == JobState.None) revert UnknownJob();
        if (msg.sender != job.buyer) revert NotBuyer();
        if (job.state != JobState.Created) revert InvalidState(job.state);

        _escrowFunds(jobId);
        _reserveCapacity(jobId);
    }

    /// @notice Reserves Native capacity for an already-escrowed job.
    /// @dev Public for isolated retries; only valid while the job is Funded.
    function reserveCapacity(bytes32 jobId) external {
        _reserveCapacity(jobId);
    }

    function _escrowFunds(bytes32 jobId) internal {
        Job storage job = _jobs[jobId];
        uint256 amount = uint256(job.units) * job.pricePerUnit;
        if (amount == 0) revert ZeroAmount();

        uint256 balanceBefore = fusd.balanceOf(address(this));
        _safeTransferFrom(fusd, job.buyer, address(this), amount);
        // Fail closed on fee-on-transfer / partial-delivery tokens.
        if (fusd.balanceOf(address(this)) - balanceBefore < amount) revert EscrowBalanceShortfall();

        job.totalEscrow = amount;
        escrowedTotal += amount;
        job.state = JobState.Funded;
        emit FundsEscrowed(jobId, job.buyer, amount);
    }

    function _reserveCapacity(bytes32 jobId) internal {
        Job storage job = _jobs[jobId];
        if (job.state == JobState.None) revert UnknownJob();
        if (job.state != JobState.Funded) revert InvalidState(job.state);
        if (bytes(nativeRegistryAddress).length == 0) revert NativeRegistryNotConfigured();
        if (bridgeAddress == address(0)) revert BridgeNotConfigured();
        if (fusd.balanceOf(address(this)) < job.totalEscrow) revert EscrowBalanceShortfall();

        bytes memory response = CrossVMBridgeService.callNative(bridgeAddress, nativeRegistryAddress, _reservePayload(job));
        CrossVMResponseCodec.NativeResult memory result = CrossVMResponseCodec.decodeOperation(
            response,
            CrossVMResponseCodec.OP_RESERVE
        );

        if (result.jobId != jobId) revert WrongJobInResponse(jobId, result.jobId);
        if (result.termsHash != job.termsHash) revert TermsMismatch(job.termsHash, result.termsHash);
        if (result.reservedUnits != job.units) revert InvalidDeliveredUnits(result.reservedUnits, job.units);

        job.state = JobState.Reserved;
        emit CapacityReserved(jobId, result.reservedUnits, result.availableUnits);
    }

    // ---------------------------------------------------------------- evidence

    /// @notice Canonical evidence digest expected from an authorized monitor.
    function expectedEvidenceHash(bytes32 jobId, uint256 deliveredUnits) public view returns (bytes32) {
        Job storage job = _jobs[jobId];
        return keccak256(abi.encode(jobId, job.termsHash, deliveredUnits, job.providerId, job.slotId));
    }

    /// @notice Authorized monitor submits delivery evidence for a reserved job.
    function submitEvidence(bytes32 jobId, uint256 deliveredUnits, bytes32 evidenceHash) external onlyAuthorizedMonitor {
        Job storage job = _jobs[jobId];
        if (job.state == JobState.None) revert UnknownJob();
        if (job.state != JobState.Reserved) revert InvalidState(job.state);
        if (deliveredUnits > job.units) revert InvalidDeliveredUnits(deliveredUnits, job.units);
        if (evidenceConsumed[jobId][evidenceHash]) revert EvidenceAlreadyConsumed(jobId, evidenceHash);

        bytes32 expected = expectedEvidenceHash(jobId, deliveredUnits);
        if (evidenceHash != expected) revert EvidenceHashMismatch(expected, evidenceHash);

        evidenceConsumed[jobId][evidenceHash] = true;
        job.deliveredUnits = deliveredUnits;
        job.evidenceHash = evidenceHash;
        job.evidenceAccepted = true;
        emit EvidenceSubmitted(jobId, msg.sender, evidenceHash, deliveredUnits);
    }

    // ---------------------------------------------------------------- settlement

    /// @notice Finalizes Native reservation, pays provider and refunds the remainder.
    /// @dev Duplicate settlement is blocked by the state check. If the Native call
    ///      fails or the response is malformed, the whole tx reverts and fUSD stays.
    function settle(bytes32 jobId) external {
        Job storage job = _jobs[jobId];
        if (job.state == JobState.None) revert UnknownJob();
        if (job.state != JobState.Reserved) revert InvalidState(job.state);
        if (!job.evidenceAccepted) revert EvidenceNotAccepted();
        if (bytes(nativeRegistryAddress).length == 0) revert NativeRegistryNotConfigured();
        if (bridgeAddress == address(0)) revert BridgeNotConfigured();

        bytes memory response = CrossVMBridgeService.callNative(bridgeAddress, nativeRegistryAddress, _finalizePayload(job));
        CrossVMResponseCodec.NativeResult memory result = CrossVMResponseCodec.decodeOperation(
            response,
            CrossVMResponseCodec.OP_FINALIZE
        );

        if (result.jobId != jobId) revert WrongJobInResponse(jobId, result.jobId);
        if (result.termsHash != job.termsHash) revert TermsMismatch(job.termsHash, result.termsHash);
        if (result.deliveredUnits != job.deliveredUnits) {
            revert InvalidDeliveredUnits(result.deliveredUnits, job.deliveredUnits);
        }

        uint256 providerPaid = job.deliveredUnits * job.pricePerUnit;
        uint256 buyerRefund = job.totalEscrow - providerPaid;

        job.state = JobState.Settled;
        job.escrowPaidOut = providerPaid;
        job.escrowRefunded = buyerRefund;
        if (escrowedTotal >= providerPaid + buyerRefund) escrowedTotal -= (providerPaid + buyerRefund);

        if (providerPaid > 0) _safeTransfer(fusd, job.providerPayout, providerPaid);
        if (buyerRefund > 0) _safeTransfer(fusd, job.buyer, buyerRefund);
        emit JobSettled(jobId, job.providerPayout, providerPaid, buyerRefund, job.deliveredUnits);
    }

    /// @notice Releases Native reservation and refunds the buyer.
    /// @dev Permissionless after endTime; buyer-only before endTime. Native release
    ///      is called first for Reserved jobs; a failed call reverts the refund too.
    function refund(bytes32 jobId) external {
        Job storage job = _jobs[jobId];
        if (job.state == JobState.None) revert UnknownJob();
        if (job.state != JobState.Funded && job.state != JobState.Reserved) revert InvalidState(job.state);
        if (msg.sender != job.buyer && block.timestamp < job.endTime) revert NotBuyer();
        if (bridgeAddress == address(0)) revert BridgeNotConfigured();
        if (bytes(nativeRegistryAddress).length == 0) revert NativeRegistryNotConfigured();

        if (job.state == JobState.Reserved) {
            bytes memory response = CrossVMBridgeService.callNative(bridgeAddress, nativeRegistryAddress, _releasePayload(job));
            CrossVMResponseCodec.NativeResult memory result = CrossVMResponseCodec.decodeOperation(
                response,
                CrossVMResponseCodec.OP_RELEASE
            );
            if (result.jobId != jobId) revert WrongJobInResponse(jobId, result.jobId);
            if (result.termsHash != job.termsHash) revert TermsMismatch(job.termsHash, result.termsHash);
        }

        uint256 refundAmount = job.totalEscrow - job.escrowRefunded;
        job.state = JobState.Refunded;
        job.escrowRefunded = job.totalEscrow;
        if (escrowedTotal >= refundAmount) escrowedTotal -= refundAmount;
        if (refundAmount > 0) _safeTransfer(fusd, job.buyer, refundAmount);
        emit JobRefunded(jobId, refundAmount);
    }

    // ---------------------------------------------------------------- views

    function getJobStatus(
        bytes32 jobId
    )
        external
        view
        returns (
            JobState state,
            address buyer,
            address providerPayout,
            uint32 units,
            uint256 totalEscrow,
            uint256 deliveredUnits,
            bool evidenceAccepted,
            bytes32 evidenceHash
        )
    {
        Job storage job = _jobs[jobId];
        return (
            job.state,
            job.buyer,
            job.providerPayout,
            job.units,
            job.totalEscrow,
            job.deliveredUnits,
            job.evidenceAccepted,
            job.evidenceHash
        );
    }

    function jobCount() external view returns (uint256) {
        return jobIds.length;
    }

    function jobIdAt(uint256 index) external view returns (bytes32) {
        return jobIds[index];
    }

    // ---------------------------------------------------------------- JSON execute payloads

    /// @dev No caller identity is included: the Native contract authorizes its own
    ///      `info.sender`, never a field supplied inside the JSON payload.
    function _reservePayload(Job storage job) internal view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    '{"reserve":{"job_id":"',
                    CrossVMBridgeService.encodeBytes32(job.jobId),
                    '","provider_id":"',
                    job.providerId,
                    '","slot_id":"',
                    job.slotId,
                    '","units":"',
                    _toString(job.units),
                    '","terms_hash":"',
                    CrossVMBridgeService.encodeBytes32(job.termsHash),
                    '","slot_terms_hash":"',
                    CrossVMBridgeService.encodeBytes32(job.slotTermsHash),
                    '"}}'
                )
            );
    }

    function _finalizePayload(Job storage job) internal view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    '{"finalize":{"job_id":"',
                    CrossVMBridgeService.encodeBytes32(job.jobId),
                    '","terms_hash":"',
                    CrossVMBridgeService.encodeBytes32(job.termsHash),
                    '","delivered_units":"',
                    _toString(job.deliveredUnits),
                    '","accepted_breach":false}}'
                )
            );
    }

    function _releasePayload(Job storage job) internal view returns (bytes memory) {
        return
            bytes(
                string.concat(
                    '{"release":{"job_id":"',
                    CrossVMBridgeService.encodeBytes32(job.jobId),
                    '"}}'
                )
            );
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ---------------------------------------------------------------- ERC-20 safety

    function _safeTransfer(IERC20Like token, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, amount));
        if (!ok || (ret.length != 0 && !_decodeBool(ret))) revert EscrowBalanceShortfall();
    }

    function _safeTransferFrom(IERC20Like token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = address(token).call(
            abi.encodeWithSelector(token.transferFrom.selector, from, to, amount)
        );
        if (!ok || (ret.length != 0 && !_decodeBool(ret))) revert EscrowBalanceShortfall();
    }

    function _decodeBool(bytes memory ret) internal pure returns (bool) {
        if (ret.length < 32) return false;
        uint256 value;
        assembly ("memory-safe") {
            value := mload(add(ret, 32))
        }
        return value != 0;
    }
}