# WASM-target dependency security audit

Audit date: 24 November 2026
Repository commit inspected: `b0dd15e03e4bc7b37a35eab16f6413048fb25cfd`
Probe source commit: [`724729bcfc34bb43131165bbbe49f90dace5926e`](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e)

## Scope and conclusion

This is a static dependency and artifact review of the existing staking probe. No source, lockfile, optimized Wasm, or Proposal A payload was changed. No upload, instantiation, proposal submission, signing, or transaction broadcast occurred.

The `cargo audit` findings for `crypto-bigint 0.5.5` and `curve25519-dalek 3.2.0` resolve through `cosmwasm-crypto 1.5.11`. CosmWasm 1.5.11's published manifest declares `cosmwasm-crypto` under `cfg(not(target_arch = "wasm32"))`. The current locked target-specific inverse trees also return no path for either affected crate, and neither package appears in `cargo metadata --filter-platform wasm32-unknown-unknown`'s resolved package set. This supports the conclusion that those two Rust crate implementations are not compiled into this contract's wasm32 module.

This does **not** mean the entire Wasm has no crypto-related content: the binary contains standard CosmWasm host imports for secp256k1 and Ed25519 verification/recovery and corresponding wrapper functions. Those wrappers call the host ABI imports; they are not the Rust implementations of the two advisory packages. Binaryen call-graph output plus a direct/indirect function-table analysis found all four wrappers unreachable from every exported contract/API function. This is an over-approximation of indirect targets by signature, so failure to reach their signatures bounds reachability conservatively. A stripped Wasm is not a dependable way to identify crate provenance; the source graph and target-gated manifest remain the basis for crate attribution.

The host/native lock graph still contains both affected crates. Native builds and test binaries therefore remain within the advisory's affected dependency surface, even though this contract's current test cases do not handle secret scalar material. A formal, recorded risk acceptance is appropriate before treating the existing pinned dependency set as cleared for continued native build/test use. This audit does not silently accept that risk on behalf of a project owner.

For the exact vulnerable routines named by these advisories, neither package is resolved for wasm32 and so those package implementations are not compiled into this build. The cryptographic wrapper functions visible in the Wasm are distinct CosmWasm API glue and delegate to imported host functions. The follow-on direct/indirect call-graph analysis below found these four wrappers unreachable from all function exports; this resolves the wrapper reachability question for this module.

**Security disposition: NOT READY FOR SUBMISSION until the project owner records acceptance of the bounded native/build/test dependency risk.** The findings do not, on the available target-graph evidence, establish that vulnerable crate code is present in or reachable from the deployed Wasm. If that host-side risk is accepted, these two findings alone do not technically require changing this upload-only feasibility artifact. G0-A remains untested and not passed.

## Exact graph evidence

Commands ran from `contracts/staking-probe`, using the committed `Cargo.lock` and `--locked`:

```powershell
cargo tree --locked --target wasm32-unknown-unknown -e normal
cargo tree --locked --target wasm32-unknown-unknown -i crypto-bigint
cargo tree --locked --target wasm32-unknown-unknown -i curve25519-dalek
cargo tree --locked --target wasm32-unknown-unknown -i zeroize
cargo tree --locked --target wasm32-unknown-unknown -i derivative
cargo tree --locked --target wasm32-unknown-unknown -e features
cargo tree --locked --target wasm32-unknown-unknown -e features -i generic-array
cargo tree --locked -e features -i generic-array
cargo tree --locked --target wasm32-unknown-unknown -e normal,build
cargo tree --locked --target wasm32-unknown-unknown -e dev
cargo tree --locked --target wasm32-unknown-unknown -e features -i zeroize
cargo metadata --locked --format-version 1 --filter-platform wasm32-unknown-unknown
cargo metadata --locked --format-version 1
```

Captured outputs: the `cargo-tree-wasm-*.log` files, `docs/evidence/cargo-tree-host-generic-array-features.log`, `docs/evidence/cargo-tree-host-inverse-security.log`, `docs/evidence/cargo-metadata-wasm.json`, and `docs/evidence/cargo-metadata-unfiltered.json`.

| Package | Unrestricted locked graph | wasm32 inverse tree / filtered metadata | Interpretation |
|---|---|---|---|
| `cosmwasm-crypto 1.5.11` | Present | Absent from wasm filtered package set; no target inverse was requested | Host-side CosmWasm crypto dependency |
| `crypto-bigint 0.5.5` | Present via `elliptic-curve -> ecdsa -> k256 -> cosmwasm-crypto -> cosmwasm-std` | `cargo tree -i`: nothing to print; absent from filtered metadata package set | Native-only path for this target configuration |
| `curve25519-dalek 3.2.0` | Present via `ed25519-zebra -> cosmwasm-crypto -> cosmwasm-std` | `cargo tree -i`: nothing to print; absent from filtered metadata package set | Native-only path for this target configuration |
| `derivative 2.2.0` | Present | Present in the target inverse tree through `cosmwasm-std`; proc-macro target | Built/run as a host procedural macro; not a runtime crate embedded in Wasm |
| `zeroize 1.8.1` | Present; host feature tree activates `generic-array/zeroize` through the host crypto graph | Target inverse tree prints nothing and `cargo tree -e features --target wasm32-unknown-unknown` does not show the `zeroize` feature | Host/build/test dependency only; filtered metadata serializes a package-level feature union that does not identify the host/target compilation unit |

The filtered metadata has 45 resolve nodes / 43 unique package names; unrestricted metadata has 78 nodes / 72 unique package names. Filtered metadata lists `generic-array` with features `more_lengths,zeroize` and resolves its optional `zeroize` edge. However, `cargo tree -e features --target wasm32-unknown-unknown` shows only `generic-array`'s `default` and `more_lengths` features, while unrestricted `cargo tree -e features -i generic-array` shows `generic-array/zeroize` activated through the native crypto graph (including `elliptic-curve` / `crypto-bigint`). The target-specific inverse query also prints nothing. Cargo's [metadata output](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html) is package-ID based and its `--filter-platform` filters the resolved dependency output; the target-aware [feature-unified tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) confirms which features are active for the requested target. Therefore `zeroize 1.8.1` is present only in the host/native dependency graph, not active for this Wasm build. The contract has no `[dev-dependencies]` or target-specific dependency sections; the host crypto path is selected for native builds/tests by CosmWasm's non-wasm cfg. `zeroize` is not itself a finding in the saved RustSec output.

The local cached `cosmwasm-std-1.5.11/Cargo.toml` confirms:

```toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies.cosmwasm-crypto]
version = "1.5.11"
```

The manifest also lists `derivative` as a normal source dependency; target tree shows it as `(proc-macro)`. Proc-macro implementation executes on the build host to generate Rust code and is not linked as a runtime dependency into the Wasm.

The unrestricted inverse-tree outputs are in `docs/evidence/cargo-tree-host-inverse-security.log`; the saved full audit is `docs/evidence/cargo-audit.txt`. `cargo audit` scanned 78 lockfile dependencies; it does not prove that every lockfile package is compiled for the Wasm target.

## RustSec findings in context

| Advisory | Package/version and issue | Probe path / target status | Secrets and practical context | Classification |
|---|---|---|---|---|
| [RUSTSEC-2026-0387](https://rustsec.org/advisories/RUSTSEC-2026-0387.html) | `crypto-bigint 0.5.5`; timing variability in operations intended to be constant-time. RustSec says secret-dependent branches can occur in subtraction, zero counting, division, Montgomery multiplication, equality, and inversion. Patched in `>=0.7.6`. | Native graph path: `crypto-bigint -> elliptic-curve -> ecdsa -> k256 -> cosmwasm-crypto -> cosmwasm-std -> probe`. `cosmwasm-crypto` is cfg-excluded on wasm32; target inverse tree and filtered package list omit `crypto-bigint`. | Probe accepts a provider address and reads public staking delegation data; it does not accept or process private scalars, keys, or signing secrets. Native tests use mocks and do not test secret arithmetic. A future native consumer of the crypto APIs could still exercise this vulnerable implementation. | **Present only in native/build/test dependencies**; not established in deployed Wasm. Host-side risk acceptance recommended. |
| [RUSTSEC-2024-0344](https://rustsec.org/advisories/RUSTSEC-2024-0344.html) | `curve25519-dalek 3.2.0`; timing variability in `Scalar29::sub` / `Scalar52::sub`; patched in `>=4.1.3`. | Native graph path: `curve25519-dalek -> ed25519-zebra -> cosmwasm-crypto -> cosmwasm-std -> probe`. `cosmwasm-crypto` is cfg-excluded on wasm32; target inverse tree and filtered package list omit `curve25519-dalek`. | Same probe behavior: no private scalar handling or secret input. Native dependency remains relevant to host-side CosmWasm crypto use and tests/tooling that invoke it. | **Present only in native/build/test dependencies**; not established in deployed Wasm. Host-side risk acceptance recommended. |
| [RUSTSEC-2024-0388](https://rustsec.org/advisories/RUSTSEC-2024-0388.html) | `derivative 2.2.0`; RustSec classifies it as unmaintained (`INFO`), with no patched release. This is not a confirmed vulnerability. | Appears in the target Cargo tree as a `(proc-macro)` dependency of `cosmwasm-std`; it executes on the host during compilation. The final Wasm's 22 type definitions and code do not prove or disprove crate identity. | No secret-processing allegation is attached to this advisory. | **Present only in native/build-time proc-macro dependency**; unmaintained warning only, not a confirmed vulnerability and not a runtime Wasm finding. |

`base64ct 1.7.3` and `zeroize 1.8.1` are compatibility pins in this project's lockfile but were not reported as advisories by the captured `cargo audit`. No dependency was upgraded in this review. Any change needs a compatible dependency/toolchain decision, a fresh pinned optimizer build, and a new artifact audit.

## Actual optimized Wasm inspection

Artifact: `artifacts/contracts/qorelease_staking_probe.wasm`
Size: `169,218` bytes
SHA-256: `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`
Optimizer checksum: same value in `artifacts/contracts/checksums.txt`.

Inspection used `wasm-opt 116` from the pinned official optimizer image, `cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`, with `--platform linux/amd64`. The emitted text view was produced without optimization passes, to inspect the existing bytes:

```powershell
wsl -d Ubuntu --cd "/mnt/c/Users/Hari Ram/Documents/chronoquota" -- docker run --rm --platform linux/amd64 -v "/mnt/c/Users/Hari Ram/Documents/chronoquota:/code" --entrypoint wasm-opt cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e /code/artifacts/contracts/qorelease_staking_probe.wasm --emit-text -o /code/docs/evidence/staking-probe-review.wat
```

Complete imports (`env` module):

```text
abort(i32)
db_read(i32) -> i32
db_write(i32, i32)
db_remove(i32)
db_scan(i32, i32, i32) -> i32
db_next(i32) -> i32
addr_validate(i32) -> i32
addr_canonicalize(i32, i32) -> i32
addr_humanize(i32, i32) -> i32
secp256k1_verify(i32, i32, i32) -> i32
secp256k1_recover_pubkey(i32, i32, i32) -> i64
ed25519_verify(i32, i32, i32) -> i32
ed25519_batch_verify(i32, i32, i32) -> i32
debug(i32)
query_chain(i32) -> i32
```

Complete exports:

```text
memory
query
execute
instantiate
interface_version_8
allocate
deallocate
requires_staking
requires_iterator
__data_end
__heap_base
```

Module/function observations: Wasm MVP module; 22 function types; 15 imported plus 285 defined functions (300 total); 11 exports; 3 globals; one table (minimum/maximum 140); one element segment with 139 entries; 15 data segments; initial memory 17 pages; no custom sections; zero f32/f64 instructions in the independent audit. The signature-check imports are present in this generic CosmWasm module. Their host implementations are outside the module. The wrappers are `$165` (`secp256k1_verify`, import `$fimport$9`), `$166` (`secp256k1_recover_pubkey`, import `$fimport$10`), `$167` (`ed25519_verify`, import `$fimport$11`), and `$168` (`ed25519_batch_verify`, import `$fimport$12`). Each wrapper directly calls its matching host import and is included in the function table. The entrypoint analysis found no path from any function export to a call-indirect site with a matching wrapper signature: wrappers `$165/$167/$168` match type `$10`, `$166` matches type `$8`, and no reachable call-indirect site from the exports uses either type. All four wrappers are therefore **present in the binary but unreachable from contract entrypoints** under the conservative table/type analysis. They are not imports that are simply unused: their wrapper bodies call the imports. The host cryptographic implementation is supplied by the chain runtime, not by these wrapper functions.

Binary limitations: release Wasm symbols are largely numeric/stripped, dependency names are not a trustworthy presence test, wrapper/inlined code cannot generally be attributed to a crate by name, and imported host functions do not identify the host's own implementation. The target-specific Cargo graph plus the pinned CosmWasm manifest provide the evidence for whether these two Rust packages were compiled for this build. The binary inspection is corroborating context, not standalone crate attribution.

The existing structural-limit audit remains in `docs/WASM_ARTIFACT_AUDIT.md`; the artifact was not regenerated or edited. Reproduce the direct/indirect call graph with the pinned image command `wsl -d Ubuntu -- docker run --rm --platform linux/amd64 -v "/mnt/c/Users/Hari Ram/Documents/chronoquota:/code" --entrypoint wasm-opt cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e /code/artifacts/contracts/qorelease_staking_probe.wasm --print-call-graph -o /dev/null`; saved output: `docs/evidence/wasm-call-graph.log`. The reachability walk is reproducible with `powershell -NoProfile -ExecutionPolicy Bypass -File docs/evidence/wasm-reachability.ps1`; report: `docs/evidence/wasm-entrypoint-reachability.txt`. Supporting structural outputs are `docs/evidence/wasm-independent-audit.log` and `docs/evidence/wasm-independent-section-metrics.log`.

## Diana runtime/API compatibility

QoreChain's official [QoreChain Native Development guide](https://docs.qorechain.io/developer-guide/cosmwasm-development/) identifies QoreChain Native as its CosmWasm runtime and lists `cosmwasm-std 1.5+` as the contract prerequisite. `1.5.11` satisfies that documented API range. The official [version history](https://docs.qorechain.io/appendix/version-history/) states Diana has run v3.2.9 since 20 November 2026 (testnet governance proposal 39, height 10,424,000); that release note describes SVM and cross-VM changes, not a CosmWasm runtime/API version change. This establishes documented compatibility, not live acceptance or successful query execution of this particular artifact. G0-A remains unverified.

The public docs do not state the exact internal `wasmvm`/CosmWasm VM library version bundled into Diana v3.2.9. No exact internal engine version is asserted here. A deployment/runtime test would still be needed to establish acceptance and staking-query behavior, and is outside this audit.

## Reproduction and supporting command record

Tool versions: Rust/Cargo used for this audit `1.93.0`; official optimizer build environment remains Rust `1.81.0` and Cargo `1.81.0` as shown in the two preserved build logs; Binaryen `wasm-opt 116`; `cargo-audit 0.23.0`. Existing pinned optimizer digest is recorded above. Target-specific graph commands ran with `--locked`; they made no lockfile edits.

The saved RustSec output is `docs/evidence/cargo-audit.txt`. It reported two vulnerabilities and one allowed unmaintained warning. The target graph does not clear those packages from native build/test tooling, and this report does not recommend a blind upgrade.
