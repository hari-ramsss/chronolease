export type ReservationStatus = "ACTIVE" | "FINALIZED" | "RELEASED";

export interface Reservation {
  jobId: string;
  providerId: string;
  slotId: string;
  termsHash: string;
  units: number;
  status: ReservationStatus;
  /** Unix seconds; the reservation is only valid up to this instant. */
  expiresAt: number;
}

export interface Slot {
  providerId: string;
  slotId: string;
  serviceType: string;
  totalUnits: number;
  reservedUnits: number;
  consumedUnits: number;
  termsHash: string;
  startTime: number;
  endTime: number;
  active: boolean;
}

export interface Job {
  jobId: string;
  providerId: string;
  slotId: string;
  termsHash: string;
  serviceType: string;
  requestedUnits: number;
  /** Maximum units the buyer's terms permit for this job. */
  permittedUnits: number;
  /** Unix seconds deadline for execution. */
  deadline: number;
}

export interface WorkloadInput {
  jobId: string;
  serviceType: string;
  index: number;
}

export interface WorkloadResponse {
  ok: boolean;
  statusCode: number;
  latencyMs: number;
  outputHash: string;
}

export interface WorkloadClient {
  execute(input: WorkloadInput): Promise<WorkloadResponse>;
}

export interface NativeClient {
  queryReservation(jobId: string): Promise<Reservation | null>;
  querySlot(providerId: string, slotId: string): Promise<Slot | null>;
  queryAvailableCapacity(providerId: string, slotId: string): Promise<number>;
  now(): number;
}

export interface ExecutionReport {
  jobId: string;
  providerId: string;
  slotId: string;
  termsHash: string;
  serviceType: string;
  requestedUnits: number;
  completedUnits: number;
  failedUnits: number;
  avgLatencyMs: number;
  p95LatencyMs: number;
  outputHashes: string[];
  evidenceHash: string;
  startedAt: number;
  finishedAt: number;
}

export interface DeliveryReport {
  monitorId: string;
  jobId: string;
  termsHash: string;
  deliveredUnits: number;
  failedUnits: number;
  p95LatencyMs: number;
  reportHash: string;
  /** Local mock attestation; NOT a real signature or a Diana precompile result. */
  mockAttestation: string;
}
