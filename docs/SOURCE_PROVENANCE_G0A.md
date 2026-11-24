# G0-A source provenance

## Source commit

Local commit: `724729bcfc34bb43131165bbbe49f90dace5926e` (Add reproducible G0-A staking probe source). It is a new commit on `main`; no history was rewritten. It includes only:

- `.gitignore`
- `contracts/staking-probe/src/lib.rs`
- `contracts/staking-probe/Cargo.toml`
- `contracts/staking-probe/Cargo.lock`
- `contracts/staking-probe/README.md` with pinned build instructions

The crate is standalone. There is no root Cargo workspace, `build.rs`, or `.cargo/config.toml`. The committed lockfile is the complete dependency resolution. No generated target files, proposal payloads, credentials, wallet data, or local environment files were included.

| Input | SHA-256 |
|---|---|
| `contracts/staking-probe/src/lib.rs` | `65a609605d04562892084c9f3f7f74d557f0b27fb7922285d58af9ab32aaee24` |
| `contracts/staking-probe/Cargo.toml` | `58c8d97616345e4e5e8dfdb134438c6739d2db8710ff91a4142e9b8c4684f542` |
| `contracts/staking-probe/Cargo.lock` | `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce` |

Git blob IDs at the commit: lib.rs `5d32219acb1b50562c4a833a6328582445ccf11f`; Cargo.toml `d21a7510dcbf48bb654d540750412c9562439116`; Cargo.lock `4ff38afeee7f0e1f6f33fd49d38f594a097dac10`.

## Public source availability

`origin` now points to `git@github.com:hari-ramsss/chronolease.git`, the repository URL supplied by the user. Commit `724729bcfc34bb43131165bbbe49f90dace5926e` was pushed as a fast-forward to public `main`, now confirmed at that exact hash. Public commit: [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e). Source file: [lib.rs at that commit](https://github.com/hari-ramsss/chronolease/blob/724729bcfc34bb43131165bbbe49f90dace5926e/contracts/staking-probe/src/lib.rs). The earlier `chronoquote` origin was the wrong destination and is no longer configured. Public source provenance is resolved; Proposal A remains **NOT READY FOR SUBMISSION** because of dependency security findings.

## Reproduction and artifact correspondence

Run in Ubuntu WSL2 from the probe directory:

```bash
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/staking-probe"
docker run --rm --platform linux/amd64 -v "$PWD":/code --mount type=volume,source=staking-probe_cache,target=/target --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
sha256sum -c artifacts/checksums.txt
```

This is official `cosmwasm/optimizer:0.16.1`, platform `linux/amd64`, pinned by digest. After the local source commit, the command ran twice using the committed source and lock bytes. Both builds emitted SHA-256 `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`, matching the optimizer checksum and `artifacts/contracts/qorelease_staking_probe.wasm`. The file hashes above were measured after committing and match the inputs used by those builds.

The two post-commit run records are `docs/evidence/optimizer-provenance-build-1.log` and `docs/evidence/optimizer-provenance-build-2.log`. The prior direct Cargo Wasm is diagnostic only. No probe logic was changed during this audit.
