/**
 * LOCAL E2E (steps 10-12 of the Phase 1E scenario).
 *
 * Steps 1-9 and 13 are proven by `contracts/qorelease-registry/tests/e2e_native.rs`
 * and `contracts/evm/test/QoreLeaseEscrow.t.sol`. This script drives the provider
 * adapter against a real local OpenAI-compatible HTTP endpoint, then builds two
 * independent local monitor reports. It does NOT call Diana or claim Diana proof.
 */
import { createOpenAICompatServer, HttpWorkloadClient } from "./workload.ts";
import { ProviderAdapter } from "./adapter.ts";
import {
  InMemoryNativeClient,
  fixtureJob,
  fixtureReservation,
  fixtureSlot,
} from "./nativeClient.ts";
import { generateDeliveryReport } from "./monitor.ts";

async function main(): Promise<void> {
  const server = createOpenAICompatServer();
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("no local port");
  const endpoint = `http://127.0.0.1:${address.port}/v1/chat/completions`;

  try {
    const job = fixtureJob({ requestedUnits: 70, permittedUnits: 70 });
    const native = new InMemoryNativeClient(1_750_000_000);
    // Mirrors the Native state after Buyer A's successful 70-unit reservation.
    native.seedSlot(fixtureSlot(job, { totalUnits: 100, reservedUnits: 70 }));
    native.seedReservation(fixtureReservation(job, { units: 70 }));

    console.log("STEP 10: adapter checks Native reservation and executes 70 requests");
    const adapter = new ProviderAdapter(native, new HttpWorkloadClient(endpoint), job.providerId);
    const report = await adapter.execute(job);
    if (report.completedUnits !== 70 || report.failedUnits !== 0) {
      throw new Error(`unexpected execution result: ${JSON.stringify(report)}`);
    }
    console.log(
      JSON.stringify({
        jobId: report.jobId,
        completedUnits: report.completedUnits,
        failedUnits: report.failedUnits,
        avgLatencyMs: report.avgLatencyMs,
        p95LatencyMs: report.p95LatencyMs,
        evidenceHash: report.evidenceHash,
      }),
    );

    console.log("STEP 11: independent monitors attest to the delivery report");
    const reports = ["monitor-1", "monitor-2"].map((id) => generateDeliveryReport(report, id));
    for (const item of reports) {
      console.log(JSON.stringify(item));
    }
    if (reports.some((item) => item.deliveredUnits !== 70 || item.jobId !== job.jobId)) {
      throw new Error("monitor report does not bind to the job");
    }

    console.log("STEP 12: evidence fields are ready for local EVM validation");
    console.log(
      JSON.stringify({
        jobId: report.jobId,
        termsHash: report.termsHash,
        deliveredUnits: report.completedUnits,
        providerId: report.providerId,
        slotId: report.slotId,
        note: "EVM validation of accepted evidence is proven by forge test test_validSettlementPaysProviderAndBlocksDuplicateSettlement",
      }),
    );
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    );
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
