# QoreLease Native provider registry

Standalone CosmWasm 1.5.11 contract, kept separate from the accepted
`contracts/staking-probe` feasibility artifact. No probe source, optimized Wasm,
checksum, or Proposal A file was modified.

## Implemented operations

`register_provider`, `deposit_bond`, `withdraw_bond`, `publish_slot`, `reserve`,
`finalize`, `release`, `update_config`, and the queries `provider`, `slot`,
`reservation`, `available_capacity`, `provider_bond`, `config`.

All token/capacity math uses `Uint128::checked_*`. One exact non-zero `uqor` coin
is required for `deposit_bond`; the precompile cannot attach funds. Job ids are
0x-prefixed 32-byte values, and the persistence of every reservation record is
the replay guard.

## Staking admission (unresolved on Diana)

`query_uqor_delegations` is the single isolated helper. It calls
`deps.querier.query_all_delegations`, sums only `uqor` with checked arithmetic,
and propagates any query error (fail closed). Tests use `MockQuerier` staking
entries; they do **not** verify Diana. The exact unresolved question is whether
`AllDelegations` includes only bonded delegations or also unbonding ones, and
whether the query is available at all inside the bridge execution context.

The `authorized_escrow` address is compared directly with `info.sender`. No JSON
payload field can supply or override the caller identity. The correctness of the
mapped `qor1...` identity for the deployed EVM escrow remains G0-C unverified.

## Local tests

```powershell
cd contracts/qorelease-registry
cargo test --locked
```

Includes 11 unit tests and one end-to-end integration test
(`tests/e2e_native.rs`) that runs the real contract entry points with mocked
staking queries. All 12 pass locally. These are **local mock tests**, not Diana
verification.
