import type { DeliveryReport, ExecutionReport } from "./types.ts";
import { stableHash } from "./nativeClient.ts";

/**
 * Independent monitor report builder. The "attestation" here is a deterministic
 * local digest only. It is NOT a real signature, not a quorum, and not a Diana
 * PQC precompile result. Those remain separate deployment/integration work.
 */
export function generateDeliveryReport(
  execution: ExecutionReport,
  monitorId: string,
): DeliveryReport {
  const body = {
    monitorId,
    jobId: execution.jobId,
    termsHash: execution.termsHash,
    deliveredUnits: execution.completedUnits,
    failedUnits: execution.failedUnits,
    p95LatencyMs: execution.p95LatencyMs,
    evidenceHash: execution.evidenceHash,
  };
  const reportHash = stableHash(body);
  return {
    ...body,
    reportHash,
    mockAttestation: stableHash(`${monitorId}:${reportHash}`),
  };
}
