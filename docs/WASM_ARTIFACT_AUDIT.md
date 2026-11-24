# Independent staking-probe Wasm audit

Date: 24 November 2026. Artifact: `artifacts/contracts/qorelease_staking_probe.wasm`.

## Identity

- Size: **169,218 bytes**.
- SHA-256 measured from the actual file: `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`.
- Optimizer `artifacts/contracts/checksums.txt` records the same hash for `qorelease_staking_probe.wasm`: **MATCH**.
- Image: `cosmwasm/optimizer:0.16.1`, immutable digest `sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`, platform `linux/amd64`.

The binary-section parser measured the values below. `wasm-opt` from the digest-pinned image parsed the module and strict MVP validation passed. Its emitted text was scanned for f32/f64 opcodes.

| QoreChain constraint | Measured | Maximum | Result |
|---|---:|---:|---|
| Compiled size | 169,218 bytes | 33,554,432 bytes (32 MiB) | PASS |
| Functions (285 defined + 15 imported) | 300 | 4,096 | PASS |
| Function types | 22 | 512 | PASS |
| Exports | 11 | 128 | PASS |
| Globals | 3 | 256 | PASS |
| Element segments | 1 | 16 | PASS |
| Element entries | 139 | 2,500 | PASS |
| Data segments | 15 | 1,024 | PASS |
| Initial memory | 17 pages | 64 pages | PASS |
| Custom section payload | 0 bytes | 131,072 bytes (128 KiB) | PASS |
| Floating-point instructions | 0 | 0 allowed | PASS |

Additional measured values: table minimum 140; Wasm MVP version. This structural audit does not show Diana accepts or executes the staking query.

## Exact commands

Run from repository root in Ubuntu WSL2:

```bash
sha256sum artifacts/contracts/qorelease_staking_probe.wasm artifacts/contracts/checksums.txt
python3 docs/evidence/audit-wasm-sections.py
bash docs/evidence/audit-optimized-wasm.sh
```

The Python 3 script parses the binary sections directly. The shell audit runs pinned-image `wasm-opt --emit-text`, counts module features and f32/f64 opcodes, then runs `wasm-opt --mvp-features -o /dev/null`. Captured output: `docs/evidence/wasm-independent-section-metrics.log` and `docs/evidence/wasm-independent-audit.log`.
