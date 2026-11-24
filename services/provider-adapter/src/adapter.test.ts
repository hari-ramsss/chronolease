import assert from "node:assert/strict";
import { test } from "node:test";
import { ProviderAdapter, AdapterError } from "./adapter.ts";
import {
  InMemoryNativeClient,
  canonicalJson,
  fixtureJob,
  fixtureReservation,
  fixtureSlot,
} from "./nativeClient.ts";
import { DeterministicWorkloadClient } from "./workload.ts";
import { generateDeliveryReport } from "./monitor.ts";

const NOW = 1_750_000_000;

function setup(overrides: Record<string, unknown> = {}) {
  const job = fixtureJob({
    requestedUnits: 70,
    ...overrides,
  } as Parameters<typeof fixtureJob>[0]);
  const native = new InMemoryNativeClient(NOW);
  native.seedSlot(fixtureSlot(job));
  native.seedReservation(fixtureReservation(job));
  const workload = new DeterministicWorkloadClient();
  return { job, native, workload, adapter: new ProviderAdapter(native, workload, job.providerId) };
}

test("valid reservation permits execution and produces a structured report", async () => {
  const { job, adapter, workload } = setup();
  const report = await adapter.execute(job);
  assert.equal(report.jobId, job.jobId);
  assert.equal(report.termsHash, job.termsHash);
  assert.equal(report.requestedUnits, 70);
  assert.equal(report.completedUnits, 70);
  assert.equal(report.failedUnits, 0);
  assert.equal(report.outputHashes.length, 70);
  assert.equal(workload.calls, 70);
  assert.match(report.evidenceHash, /^[0-9a-f]{64}$/);
  assert.ok(report.p95LatencyMs >= report.avgLatencyMs - 3);
});

test("missing reservation rejects execution before any workload call", async () => {
  const { job, adapter, workload } = setup();
  const otherJob = fixtureJob({ jobId: `0x${"b".repeat(64)}` });
  await assert.rejects(
    adapter.execute(otherJob),
    (error: unknown) => error instanceof AdapterError && error.code === "NO_RESERVATION",
  );
  assert.equal(workload.calls, 0);
});

test("expired reservation rejects execution", async () => {
  const { job, adapter, native, workload } = setup();
  native.setClock(job.deadline + 1);
  await assert.rejects(
    adapter.execute(job),
    (error: unknown) => error instanceof AdapterError && error.code === "RESERVATION_EXPIRED",
  );
  assert.equal(workload.calls, 0);
});

test("request exceeding reserved units is rejected", async () => {
  const { job, adapter, workload } = setup({ requestedUnits: 71, permittedUnits: 70 });
  await assert.rejects(
    adapter.execute(job),
    (error: unknown) => error instanceof AdapterError && error.code === "UNITS_EXCEEDED",
  );
  assert.equal(workload.calls, 0);
});

test("terms hash mismatch is rejected", async () => {
  const { job, adapter, native, workload } = setup();
  native.seedReservation(fixtureReservation(job, { termsHash: `0x${"f".repeat(64)}` }));
  await assert.rejects(
    adapter.execute(job),
    (error: unknown) => error instanceof AdapterError && error.code === "TERMS_MISMATCH",
  );
  assert.equal(workload.calls, 0);
});

test("released reservation is rejected and invalid job id fails fast", async () => {
  const { job, adapter, native, workload } = setup();
  native.seedReservation(fixtureReservation(job, { status: "RELEASED" }));
  await assert.rejects(
    adapter.execute(job),
    (error: unknown) => error instanceof AdapterError && error.code === "RESERVATION_INACTIVE",
  );
  await assert.rejects(
    adapter.execute({ ...job, jobId: "not-a-hash" }),
    (error: unknown) => error instanceof AdapterError && error.code === "INVALID_JOB_ID",
  );
  assert.equal(workload.calls, 0);
});

test("delivery evidence includes job id and terms hash and monitor binds to it", async () => {
  const { job, adapter } = setup({ requestedUnits: 5 });
  const report = await adapter.execute(job);
  const monitorA = generateDeliveryReport(report, "monitor-1");
  const monitorB = generateDeliveryReport(report, "monitor-2");
  assert.equal(monitorA.jobId, job.jobId);
  assert.equal(monitorA.termsHash, job.termsHash);
  assert.equal(monitorA.deliveredUnits, 5);
  assert.notEqual(monitorA.reportHash, monitorB.reportHash);
  const canonical = canonicalJson({ jobId: report.jobId, termsHash: report.termsHash });
  assert.match(canonical, /"jobId"/);
});
