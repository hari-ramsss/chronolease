# Phase 0 architecture boundary

Status: specification for feasibility tests only. No QoreLease product contract is approved.

```text
Native staking probe ── query AllDelegations ── Diana staking keeper (unknown)
          ▲
          │ synchronous call, targetVM=1
Solidity test caller ── 0x0901 ── allowlisted Native probe
          │
          └── forced revert tests bridge journaling
```

The probe stores the returned delegation list and checked `uqor` sum. It does
not custody provider service bonds. Delegated stake, unbonding entries, and
liquid application collateral are separate concepts. `AllDelegations` behavior
and unbonding inclusion remain NOT VERIFIED against Diana v3.2.9 source/runtime.

Canonical evidence is the chain state and transaction receipt. Source commit,
release binary hash, Wasm checksum, code ID, address, governance result, pin,
and block heights must accompany any result.

Product implementation remains NO-GO until G0-A through G0-E pass with Diana
evidence and the Native-specific responsibility is validated.
