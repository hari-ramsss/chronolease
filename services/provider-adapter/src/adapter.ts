import type {
  ExecutionReport,
  Job,
  NativeClient,
  WorkloadClient,
} from "./types.ts";
import { stableHash } from "./nativeClient.ts";

export type AdapterErrorCode =
  | "INVALID_JOB_ID"
  | "NO_RESERVATION"
  | "RESERVATION_INACTIVE"
  | "RESERVATION_EXPIRED"
  | "PROVIDER_MISMATCH"
  | "TERMS_MISMATCH"
  | "SERVICE_MISMATCH"
  | "UNITS_EXCEEDED"
  | "INVALID_UNITS"
  | "JOB_DEADLINE_PASSED";

export class AdapterError extends Error {
  public readonly code: AdapterErrorCode;

  constructor(code: AdapterErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = "AdapterError";
  }
}

const HEX_HASH = /^0x[0-9a-fA-F]{64}$/;

/**
 * Provider-side execution gate.
 *
 * The adapter will not run any workload unless a live Native reservation exists
 * and every bound field matches. All Native reads go through the injected
 * NativeClient; on a real deployment that client must query the canonical
 * registry, not a local cache.
 */
export class ProviderAdapter {
  private readonly native: NativeClient;
  private readonly workload: WorkloadClient;
  private readonly providerId: string;

  constructor(native: NativeClient, workload: WorkloadClient, providerId: string) {
    this.native = native;
    this.workload = workload;
    this.providerId = providerId;
  }

  async execute(job: Job): Promise<ExecutionReport> {
    if (!HEX_HASH.test(job.jobId)) {
      throw new AdapterError("INVALID_JOB_ID", "job_id must be a 0x-prefixed 32-byte hash");
    }
    const reservation = await this.native.queryReservation(job.jobId);
    if (!reservation) {
      throw new AdapterError("NO_RESERVATION", `no Native reservation for ${job.jobId}`);
    }
    const slot = await this.native.querySlot(reservation.providerId, reservation.slotId);
    if (!slot) throw new AdapterError("NO_RESERVATION", "reservation references an unknown slot");

    const now = this.native.now();
    if (reservation.status !== "ACTIVE" || !slot.active) {
      throw new AdapterError("RESERVATION_INACTIVE", "Native reservation is not active");
    }
    if (now > reservation.expiresAt || now >= slot.endTime) {
      throw new AdapterError("RESERVATION_EXPIRED", "Native reservation window has expired");
    }
    if (now > job.deadline) {
      throw new AdapterError("JOB_DEADLINE_PASSED", "job deadline has passed");
    }
    if (reservation.providerId !== this.providerId || job.providerId !== this.providerId) {
      throw new AdapterError("PROVIDER_MISMATCH", "job or reservation belongs to another provider");
    }
    if (reservation.providerId !== job.providerId || reservation.slotId !== job.slotId) {
      throw new AdapterError("PROVIDER_MISMATCH", "job does not reference the reserved provider/slot");
    }
    if (reservation.termsHash !== job.termsHash || slot.termsHash !== job.termsHash) {
      throw new AdapterError("TERMS_MISMATCH", "terms hash differs from the Native reservation");
    }
    if (slot.serviceType !== job.serviceType) {
      throw new AdapterError("SERVICE_MISMATCH", "service type differs from the published slot");
    }
    if (!Number.isInteger(job.requestedUnits) || job.requestedUnits <= 0) {
      throw new AdapterError("INVALID_UNITS", "requested_units must be a positive integer");
    }
    const permitted = Math.min(job.permittedUnits, reservation.units);
    if (job.requestedUnits > permitted) {
      throw new AdapterError(
        "UNITS_EXCEEDED",
        `requested ${job.requestedUnits} units exceeds permitted ${permitted}`,
      );
    }

    const startedAt = now;
    const outputHashes: string[] = [];
    let completedUnits = 0;
    let failedUnits = 0;
    const latencies: number[] = [];

    for (let index = 0; index < job.requestedUnits; index += 1) {
      const response = await this.workload.execute({
        jobId: job.jobId,
        serviceType: job.serviceType,
        index,
      });
      latencies.push(response.latencyMs);
      if (response.ok) {
        completedUnits += 1;
        outputHashes.push(response.outputHash);
      } else {
        failedUnits += 1;
      }
    }

    const sorted = [...latencies].sort((a, b) => a - b);
    const p95Index = Math.max(0, Math.ceil(sorted.length * 0.95) - 1);
    const report: Omit<ExecutionReport, "evidenceHash"> = {
      jobId: job.jobId,
      providerId: job.providerId,
      slotId: job.slotId,
      termsHash: job.termsHash,
      serviceType: job.serviceType,
      requestedUnits: job.requestedUnits,
      completedUnits,
      failedUnits,
      avgLatencyMs:
        latencies.length === 0
          ? 0
          : Math.round((latencies.reduce((sum, value) => sum + value, 0) / latencies.length) * 100) / 100,
      p95LatencyMs: sorted.length === 0 ? 0 : sorted[p95Index],
      outputHashes,
      startedAt,
      finishedAt: this.native.now(),
    };
    return { ...report, evidenceHash: stableHash(report) };
  }
}
