// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {QoreLeaseEscrow} from "../src/QoreLeaseEscrow.sol";
import {CrossVMBridgeService} from "../src/CrossVMBridgeService.sol";
import {CrossVMResponseCodec} from "../src/CrossVMResponseCodec.sol";
import {MockFUSD} from "./mocks/MockFUSD.sol";
import {MockCrossVMBridge} from "./mocks/MockCrossVMBridge.sol";
import {MockNativeTarget} from "./mocks/MockNativeTarget.sol";
import {RevertingAfterNativeCall} from "./mocks/RevertingAfterNativeCall.sol";

/// @notice LOCAL TESTS ONLY. The mock bridge/native pair is a stateful EVM model,
/// not Diana. No result here proves QoreChain precompile or rollback behaviour.
contract QoreLeaseEscrowTest is Test {
    MockFUSD internal fusd;
    MockCrossVMBridge internal bridge;
    MockNativeTarget internal nativeRegistry;
    QoreLeaseEscrow internal escrow;

    address internal constant ADMIN = address(0xA11);
    address internal constant BUYER_A = address(0xB1A);
    address internal constant BUYER_B = address(0xB2B);
    address internal constant PROVIDER = address(0xC1C);
    address internal constant MONITOR = address(0xD1D);

    uint256 internal constant PRICE = 1_000_000; // 1 fUSD at 6 decimals
    string internal constant PROVIDER_ID = "provider-a";
    string internal constant SLOT_ID = "slot-1";
    string internal constant NATIVE_TARGET = "qor1localnativeregistry";
    string internal constant ESCROW_IDENTITY = "qor1localescrow";

    bytes32 internal constant TERMS = keccak256("QoreLease terms v1");
    bytes32 internal constant SLOT_TERMS = keccak256("QoreLease slot terms v1");

    function setUp() public {
        fusd = new MockFUSD();
        bridge = new MockCrossVMBridge(address(0));
        escrow = new QoreLeaseEscrow(address(fusd), ADMIN, address(bridge), NATIVE_TARGET, ESCROW_IDENTITY);
        nativeRegistry = new MockNativeTarget(100, address(bridge), address(escrow));
        bridge.setNativeTarget(address(nativeRegistry));
        vm.prank(ADMIN);
        escrow.authorizeMonitor(MONITOR, true);

        fusd.mint(BUYER_A, 1_000_000_000);
        fusd.mint(BUYER_B, 1_000_000_000);
        vm.prank(BUYER_A);
        fusd.approve(address(escrow), type(uint256).max);
        vm.prank(BUYER_B);
        fusd.approve(address(escrow), type(uint256).max);
    }

    function createJob(address buyer, bytes32 salt, uint32 units) internal returns (bytes32 jobId) {
        vm.prank(buyer);
        jobId = escrow.createRequest(
            salt,
            TERMS,
            SLOT_TERMS,
            PROVIDER_ID,
            SLOT_ID,
            uint64(block.timestamp),
            uint64(block.timestamp + 600),
            units,
            PRICE,
            PROVIDER
        );
    }

    function expectNativeRevert(bytes memory innerData) internal {
        vm.expectRevert(abi.encodeWithSelector(CrossVMBridgeService.BridgeCallFailed.selector, innerData));
    }

    // ------------------------------------------------------------ happy paths

    function test_successfulEscrowAndNativeReservation() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 70);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);

        (QoreLeaseEscrow.JobState state, , , uint32 units, uint256 escrowed, , , ) = escrow.getJobStatus(jobId);
        assertEq(uint8(state), uint8(QoreLeaseEscrow.JobState.Reserved));
        assertEq(units, 70);
        assertEq(escrowed, 70 * PRICE);
        assertEq(fusd.balanceOf(address(escrow)), 70 * PRICE);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000 - 70 * PRICE);
        assertEq(nativeRegistry.totalReserved(), 70);
        assertEq(bridge.lastTargetVm(), 1);
        assertEq(bridge.lastTargetContract(), NATIVE_TARGET);
        assertEq(bridge.lastCaller(), address(escrow));

        // No caller identity is smuggled into the JSON payload.
        string memory payload = string(bridge.lastPayload());
        assertFalse(_contains(payload, "caller"));
        assertFalse(_contains(payload, "sender"));
    }

    function test_localOverbookingRejectionRollsBackBuyerBTransfer() public {
        bytes32 jobA = createJob(BUYER_A, keccak256("job-a"), 70);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobA);
        bytes32 jobB = createJob(BUYER_B, keccak256("job-b"), 50);
        uint256 before = fusd.balanceOf(BUYER_B);

        expectNativeRevert(abi.encodeWithSignature("Error(string)", "insufficient capacity"));
        vm.prank(BUYER_B);
        escrow.acceptOffer(jobB);

        assertEq(fusd.balanceOf(BUYER_B), before, "buyer B fUSD must be unchanged");
        assertEq(fusd.balanceOf(address(escrow)), 70 * PRICE, "escrow must hold only job A funds");
        assertEq(nativeRegistry.totalReserved(), 70, "native capacity must not overbook");
        (QoreLeaseEscrow.JobState stateB, , , , , , , ) = escrow.getJobStatus(jobB);
        assertEq(uint8(stateB), uint8(QoreLeaseEscrow.JobState.Created), "reverted acceptOffer must leave job Created");
    }

    // ------------------------------------------------------------ failure paths

    function test_nativeRejectionRevertsEscrow() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        nativeRegistry.setBehaviour(true, false, false, false, false, false);
        expectNativeRevert(abi.encodeWithSignature("Error(string)", "Native reservation rejected"));
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000);
        assertEq(fusd.balanceOf(address(escrow)), 0);
    }

    function test_emptyBridgeResponseIsRejected() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        nativeRegistry.setBehaviour(false, true, false, false, false, false);
        vm.prank(BUYER_A);
        vm.expectRevert(CrossVMBridgeService.EmptyBridgeResponse.selector);
        escrow.acceptOffer(jobId);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000);
    }

    function test_malformedNativeResponseIsRejected() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        nativeRegistry.setBehaviour(false, false, true, false, false, false);
        vm.prank(BUYER_A);
        vm.expectPartialRevert(CrossVMResponseCodec.MalformedBridgeResponse.selector);
        escrow.acceptOffer(jobId);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000);
    }

    function test_wrongJobOrTermsInResponseIsRejected() public {
        bytes32 jobA = createJob(BUYER_A, keccak256("job-a"), 10);
        nativeRegistry.setBehaviour(false, false, false, true, false, false);
        vm.prank(BUYER_A);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("WrongJobInResponse(bytes32,bytes32)")), jobA, keccak256("wrong-job"))
        );
        escrow.acceptOffer(jobA);

        bytes32 jobB = createJob(BUYER_A, keccak256("job-b"), 10);
        nativeRegistry.setBehaviour(false, false, false, false, true, false);
        vm.prank(BUYER_A);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("TermsMismatch(bytes32,bytes32)")), TERMS, keccak256("wrong-terms"))
        );
        escrow.acceptOffer(jobB);
    }

    function test_duplicateReservationIsRejected() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InvalidState(uint8)")), uint8(3)));
        escrow.reserveCapacity(jobId);
        assertEq(nativeRegistry.totalReserved(), 10);
    }

    function test_bridgeFailureIsHandled() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        bridge.setForceRevert(true);
        expectNativeRevert(abi.encodeWithSignature("Error(string)", "bridge forced failure"));
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000);
    }

    // ------------------------------------------------------------ evidence / settlement

    function test_invalidEvidenceCannotTriggerPayment() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);

        vm.prank(MONITOR);
        vm.expectPartialRevert(bytes4(keccak256("EvidenceHashMismatch(bytes32,bytes32)")));
        escrow.submitEvidence(jobId, 10, keccak256("forged"));

        vm.expectRevert(abi.encodeWithSignature("EvidenceNotAccepted()"));
        escrow.settle(jobId);
        assertEq(fusd.balanceOf(address(escrow)), 10 * PRICE);
    }

    function test_validSettlementPaysProviderAndBlocksDuplicateSettlement() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 70);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);

        bytes32 evidence = escrow.expectedEvidenceHash(jobId, 60);
        vm.prank(MONITOR);
        escrow.submitEvidence(jobId, 60, evidence);
        escrow.settle(jobId);

        (QoreLeaseEscrow.JobState state, , , , , uint256 delivered, bool accepted, ) = escrow.getJobStatus(jobId);
        assertEq(uint8(state), uint8(QoreLeaseEscrow.JobState.Settled));
        assertEq(delivered, 60);
        assertTrue(accepted);
        assertEq(fusd.balanceOf(PROVIDER), 60 * PRICE);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000 - 70 * PRICE + 10 * PRICE);
        assertEq(fusd.balanceOf(address(escrow)), 0);
        assertEq(nativeRegistry.totalReserved(), 0);
        assertTrue(nativeRegistry.isFinalized(jobId));

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InvalidState(uint8)")), uint8(4)));
        escrow.settle(jobId);
    }

    function test_failedSettlementLeavesFundsInEscrow() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 10);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);
        bytes32 evidence = escrow.expectedEvidenceHash(jobId, 10);
        vm.prank(MONITOR);
        escrow.submitEvidence(jobId, 10, evidence);

        nativeRegistry.setBehaviour(true, false, false, false, false, false);
        expectNativeRevert(abi.encodeWithSignature("Error(string)", "Native reservation rejected"));
        escrow.settle(jobId);

        assertEq(fusd.balanceOf(address(escrow)), 10 * PRICE);
        assertEq(fusd.balanceOf(PROVIDER), 0);
        (QoreLeaseEscrow.JobState state, , , , , , , ) = escrow.getJobStatus(jobId);
        assertEq(uint8(state), uint8(QoreLeaseEscrow.JobState.Reserved));
    }

    function test_refundReleasesNativeReservationAndReturnsFunds() public {
        bytes32 jobId = createJob(BUYER_A, keccak256("job-a"), 20);
        vm.prank(BUYER_A);
        escrow.acceptOffer(jobId);
        vm.prank(BUYER_A);
        escrow.refund(jobId);
        assertEq(fusd.balanceOf(BUYER_A), 1_000_000_000);
        assertEq(fusd.balanceOf(address(escrow)), 0);
        assertEq(nativeRegistry.totalReserved(), 0);
        assertTrue(nativeRegistry.isReleased(jobId));
    }

    function test_laterEvmRevertUndoesMockedNativeStateChange() public {
        RevertingAfterNativeCall harness = new RevertingAfterNativeCall(escrow);
        fusd.mint(address(harness), 1_000_000_000);
        vm.prank(address(harness));
        fusd.approve(address(escrow), type(uint256).max);
        bytes32 jobId = createJob(address(harness), keccak256("job-harness"), 30);

        vm.expectRevert("forced later EVM revert");
        harness.acceptThenRevert(jobId);

        assertEq(nativeRegistry.totalReserved(), 0, "native mock state must roll back with EVM revert");
        assertEq(fusd.balanceOf(address(escrow)), 0);
        (QoreLeaseEscrow.JobState state, , , , , , , ) = escrow.getJobStatus(jobId);
        assertEq(uint8(state), uint8(QoreLeaseEscrow.JobState.Created));
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
}