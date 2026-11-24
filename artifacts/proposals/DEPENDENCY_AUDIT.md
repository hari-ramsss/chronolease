# Cargo dependency and RustSec audit

Audit date: 24 November 2026. Cargo.lock SHA-256: `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce`. Original lock: `docs/evidence/Cargo.lock.before-optimizer`. Exact diff: `docs/evidence/Cargo.lock.optimizer-diff.patch`.

## Compatibility pins

The official optimizer uses Rust/Cargo 1.81.0. Original `base64ct 1.8.3` and `zeroize 1.9.2` require Edition 2024 / Rust 1.85 and could not be parsed by Cargo 1.81. Only these lock entries changed to `base64ct 1.7.3` and `zeroize 1.8.1`; checksums are in the diff.

`base64ct 1.7.3` appears through `spki 0.7.3`, but Cargo reports no active inverse dependency path for the selected features (it is optional). `zeroize 1.8.1` is active through crypto-bigint → elliptic-curve → ecdsa/k256 → cosmwasm-crypto → cosmwasm-std → probe; curve25519-dalek → ed25519-zebra → cosmwasm-crypto; and DER/PKCS8/SPKI paths. Logs: `docs/evidence/cargo-tree-base64ct-independent.log` and `docs/evidence/cargo-tree-zeroize-independent.log`.

## RustSec results

Command: `cargo audit --file contracts/staking-probe/Cargo.lock` with cargo-audit 0.23.0. The database loaded 1,566 advisories; the scan covered 78 dependencies. Full output: `docs/evidence/cargo-audit.txt`.

- **RUSTSEC-2026-0387 — crypto-bigint 0.5.5, vulnerability.** Several operations intended to be constant-time may use secret-dependent branches; patched in `>=0.7.6`. Impact depends on downstream use, compiler, CPU, and an attacker’s ability to observe timing.
- **RUSTSEC-2024-0344 — curve25519-dalek 3.2.0, vulnerability.** Timing variability in scalar subtraction; patched in `>=4.1.3`.
- **RUSTSEC-2024-0388 — derivative 2.2.0, unmaintained warning.** No patched version exists.

The audit did not list `base64ct` or `zeroize` directly. `zeroize` is security-sensitive; pin 1.8.1 predates later upstream changes. That compatibility reason does not waive findings in other active crypto dependencies.

## Recommendation

Treat these findings as a submission blocker. Do not silently change the verified lock/artifact. Review a compatible CosmWasm/crypto stack that resolves the advisories. Any change needs a new committed lock, pinned optimizer build, reproducibility comparison, fresh Wasm audit, and refreshed proposal payload. No dependencies were upgraded in this audit.
