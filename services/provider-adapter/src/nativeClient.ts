import { createHash } from "node:crypto";
import type { Job, NativeClient, Reservation, Slot } from "./types.ts";

/**
 * Local in-memory stand-in for Native contract queries. It mirrors the query
 * surface of `qorelease-registry` (reservation / slot / available_capacity).
 * It is NOT a Diana client: live queries must use the deployed contract address
 * and a verified QoreChain SDK/RPC path.
 */
export class InMemoryNativeClient implements NativeClient {
  private reservations = new Map<string, Reservation>();
  private slots = new Map<string, Slot>();
  private clockSeconds: number;

  constructor(nowSeconds = Math.floor(Date.now() / 1000)) {
    this.clockSeconds = nowSeconds;
  }

  setClock(nowSeconds: number): void {
    this.clockSeconds = nowSeconds;
  }

  seedReservation(reservation: Reservation): void {
    this.reservations.set(reservation.jobId, { ...reservation });
  }

  seedSlot(slot: Slot): void {
    this.slots.set(`${slot.providerId}/${slot.slotId}`, { ...slot });
  }

  async queryReservation(jobId: string): Promise<Reservation | null> {
    return this.reservations.get(jobId) ?? null;
  }

  async querySlot(providerId: string, slotId: string): Promise<Slot | null> {
    return this.slots.get(`${providerId}/${slotId}`) ?? null;
  }

  async queryAvailableCapacity(providerId: string, slotId: string): Promise<number> {
    const slot = await this.querySlot(providerId, slotId);
    if (!slot || !slot.active || this.clockSeconds >= slot.endTime) return 0;
    return Math.max(0, slot.totalUnits - slot.reservedUnits - slot.consumedUnits);
  }

  now(): number {
    return this.clockSeconds;
  }
}

/** Deterministic identifiers used by the local demo and tests. */
export function fixtureJob(overrides: Partial<Job> = {}): Job {
  return {
    jobId: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    providerId: "provider-a",
    slotId: "slot-1",
    termsHash: "0x1111111111111111111111111111111111111111111111111111111111111111",
    serviceType: "inference-api",
    requestedUnits: 70,
    permittedUnits: 70,
    deadline: 1_800_000_000,
    ...overrides,
  };
}

export function fixtureReservation(job: Job, overrides: Partial<Reservation> = {}): Reservation {
  return {
    jobId: job.jobId,
    providerId: job.providerId,
    slotId: job.slotId,
    termsHash: job.termsHash,
    units: job.permittedUnits,
    status: "ACTIVE",
    expiresAt: job.deadline,
    ...overrides,
  };
}

export function fixtureSlot(job: Job, overrides: Partial<Slot> = {}): Slot {
  return {
    providerId: job.providerId,
    slotId: job.slotId,
    serviceType: job.serviceType,
    totalUnits: 100,
    reservedUnits: job.permittedUnits,
    consumedUnits: 0,
    termsHash: job.termsHash,
    startTime: 1_700_000_000,
    endTime: job.deadline,
    active: true,
    ...overrides,
  };
}

export function stableHash(value: unknown): string {
  return createHash("sha256").update(canonicalJson(value)).digest("hex");
}

export function canonicalJson(value: unknown): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  return `{${keys.map((key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`).join(",")}}`;
}
