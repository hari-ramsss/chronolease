# QoreLease provider adapter (TypeScript)

Minimal reservation-gated execution service. No cloud GPU or real LLM is used.

## Run

Node >= 22.6 with native TypeScript type stripping:

```powershell
npm test        # 7 local adapter tests
npm run e2e     # local OpenAI-compatible HTTP workload + two monitor reports
```

## What it enforces

`ProviderAdapter.execute` queries a Native client for the reservation and slot,
then verifies the job id, provider id, slot id, service type, terms hash, active
status, time window, and permitted units before dispatching any request. It
records request counts, failures, latency statistics, output hashes, and a
canonical evidence digest.

The local workload is an OpenAI-compatible HTTP mock in `src/workload.ts`. The
monitor reports in `src/monitor.ts` are deterministic local attestations, not
real signatures, not a quorum, and not Diana PQC-precompile evidence.
