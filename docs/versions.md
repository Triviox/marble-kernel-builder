# Verified Defaults

Last updated: **2026-07-13** (branch `feature/pa-gr-kernel-source` — pa-gr SM8450 preset).

| Component | Repo | Default Ref | Version / Commit |
|---|---|---|---|
| Kernel source (`melt`) | `mohdakil2426/android_kernel_xiaomi_marble` | `melt-rebase` | HyperOS / Melt marble source (`marble_defconfig`) |
| Kernel source (`lineageos`) | `LineageOS/android_kernel_xiaomi_sm8450` | `lineage-23.2` | LOS GKI fragments (`gki_defconfig` + marble vendor configs) |
| Kernel source (`evolution-x`) | `Evolution-X-Devices/kernel_xiaomi_sm8450` | `cnb` | LOS-family GKI fragments for Evolution X / custom LOS |
| Kernel source (`aosp-pablo`) | `aosp-pablo/android_kernel_xiaomi_sm8450` | `16` | LOS-family GKI fragments (GitHub org aosp-pablo) |
| Kernel source (`pa-gr`) | `pa-gr/android_kernel_xiaomi_sm8450` | `vauxite` | LOS-family GKI fragments; default branch may ship in-tree KernelSU |
| Android kernel Clang | `https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86` | `master-kernel-build-2021` | commit `6e3223f76384455acde43affde3df0ea9df66c0d`; sparse path `clang-r416183b`, matching `build.config.common` |
| LLVM experimental | `https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-X64.tar.xz` | `llvmorg-22.1.8` | SHA-256 `df0e1ecf16caf3489a272a5eea4eec9b0d82878f6477fa309504f918a0006384`; selectable with `toolchain=llvm-22.1.8` |
| AnyKernel3 | `osm0sis/AnyKernel3` | commit `dca9dc370838d919d56c1f59ec78b27a14a72c68` | Immutable packaging template |
| SUSFS | `https://gitlab.com/simonpunk/susfs4ksu.git` | commit `4003ecf2d01c6d13fa8edf6c4f2607365738dc3d` | `SUSFS_VERSION v2.2.0`; CI-proven with KernelSU-Next/pershoot, official SukiSU Ultra, and ReSukiSU |
| SUSFS older preset | `https://gitlab.com/simonpunk/susfs4ksu.git` | commit `86114db0c49f20fa7857b8b559f3ab87cbc2d00d` | `SUSFS_VERSION v2.1.0`; WildKernels GKI r4 gki-android12-5.10 pin |
| KernelSU | `tiann/KernelSU` | `main` | Official source; non-SUSFS builds only |
| KernelSU-Next | `KernelSU-Next/KernelSU-Next` | `dev` | Official non-SUSFS ref |
| KernelSU-Next + SUSFS | `pershoot/KernelSU-Next` | `dev-susfs` | Fork branch based on official `dev` with SUSFS integration; CI-proven on Marble run `27937351021` |
| Manager version code | (computed in `read-manager-version.sh`) | Wild-style | `git rev-list --count HEAD + BASE` (KSUN/Suki/ReSuki: BASE 10200 if commits&lt;2684 else 30000; KernelSU BASE 30000), inject `DKSU_VERSION`/`KSU_VERSION` into Makefile; fallback to Makefile literal |
| SukiSU Ultra | `SukiSU-Ultra/SukiSU-Ultra` | `main` | Official non-SUSFS ref |
| SukiSU Ultra + SUSFS | `SukiSU-Ultra/SukiSU-Ultra` | `builtin` | Official branch with manager-side SUSFS support |
| ReSukiSU | `ReSukiSU/ReSukiSU` | `main` | Official branch with manager-side SUSFS support |

The workflow resolves branch, tag, and commit inputs to exact commits at run time and records them in `release/build-info.txt`. For SUSFS, the user chooses `susfs_version=v2.2.0`, `susfs_version=v2.1.0`, or `susfs_version=custom`. Custom mode uses `susfs_ref` and verifies `susfs_expected_version` when provided.

Device targets remain Poco F5 (`marblein`) and Redmi Note 12 Turbo (`marble`). ROM support depends on the selected kernel preset: `melt` is stock HyperOS; `lineageos`, `evolution-x`, `aosp-pablo`, and `pa-gr` are for LOS-based custom ROMs only.

**ZIP naming (2026-07-13+):**

```text
AK3_marble_<FAMILY>_<source>_<manager>[-version][-codeN][_susfs-vX.Y.Z]_rN.zip
```

`FAMILY` is `MELT` or `LOS`. Manager version/code stay in the name when available; SUSFS off omits the segment; LTO is not in the filename. Enabling `create_draft_release` creates a ZIP-only draft tag `marble-<preset>-r<run>` without rebuilding.

**Toolchain:** workflow default is `auto` (preset `recommended_toolchain`, else `android-r416183b`).

## Pin refresh

Review `config/known-good-pins.json` and manager SUSFS forks **every 2–4 weeks** or after upstream breaks CI.

## JOBS / ThinLTO overrides (self-hosted)

Free defaults: LLVM `JOBS<=2`, `THINLTO_JOBS=2`. On larger hosts:

```bash
JOBS_FORCE=1 JOBS=8 THINLTO_JOBS=4
```

Manager repositories are allowlisted for normal builds. KernelSU-Next is official `KernelSU-Next/KernelSU-Next@dev` when SUSFS is disabled; when SUSFS is enabled, the workflow intentionally switches only that manager to `pershoot/KernelSU-Next@dev-susfs` because current official KernelSU-Next SUSFS paths are not Marble-compatible. Supported SUSFS paths apply only the kernel-side SUSFS patch/files and verify final Kconfig values. Official KernelSU + SUSFS remains rejected until a compatible integration exists.

The default Android compiler is retrieved with Git partial clone and sparse checkout, not a generated archive. The workflow verifies the remote branch resolves to the pinned commit before checking out `clang-r416183b`. This is intentional because repeated downloads of the official generated Gitiles archive produced different whole-archive SHA-256 values even though the underlying Git commit was unchanged.

LLVM 22.1.8 is **required for LOS-family** kernels (armv9). For **Melt / HyperOS**, keep default `android-r416183b` for release-safe builds; use LLVM on Melt only for experiments.

## Clang LTO and free runners

Workflow input `lto` selects Clang LTO mode for all presets (`none` / `thin` / `full`). Default is **`thin`**.

| Mode | Guidance |
|------|----------|
| `none` | Fastest link; use for debug/smoke builds when LTO is not required |
| `thin` | **Default.** Free-runner safe with the build-core 16 GiB swap, JOBS caps for LLVM 22, and ThinLTO job limits |
| `full` | Highest optimization; memory-heavy — prefer high-RAM hosts; may OOM on free GitHub-hosted runners (~7 GiB) |

Notes:

- **Melt / HyperOS** keeps LTO enabled (default `thin`) with Android `clang-r416183b`.
- **LOS-family** presets (`lineageos`, `evolution-x`, `aosp-pablo`, `pa-gr`) should use `toolchain=llvm-22.1.8` and `lto=thin` on free runners; the workflow enables swap and caps parallelism to reduce OOM risk. `lto=full` is experimental on free runners (OOM risk).

## Cache budget

GitHub allows **10 GB of Actions cache per repository**, LRU-evicted, with a 7-day idle
expiry. Everything below is sized to fit inside that. Full rationale:
`docs/ARCHITECTURE.md` section 11.

| Cache | Cap | Key |
|---|---|---|
| Android clang | ~1.5 GB | `marble-builder-clang-v3-...` (stable) |
| LLVM 22.1.8 | ~1.8 GB | `marble-builder-llvm-v1-...` (stable) |
| ccache | **2 GiB** | `marble-ccache-v5-{os}-{arch}-{toolchain}-lto{mode}-{source}-{code_hash}-w{isoweek}` |
| ThinLTO | **1 GiB** | `marble-thinlto-v5-...` (same shape) |

- One bucket per **(toolchain, LTO mode, kernel source)**, rotated weekly. Managers share a
  bucket, because their object sets differ by a rounding error against the kernel tree.
- **No commit SHAs in the key.** The old v4 key embedded source, manager, and SUSFS commits,
  so the primary key missed on every run and each run uploaded a fresh multi-GiB entry.
- The restore chain drops the week first, then the code hash. There is no bucket-wide
  fallback: another source's cache is a multi-GB download for near-zero hits.
- `code_hash` covers only `scripts/build-kernel.sh` and `config/marble.env`, so adding a
  kernel preset does not invalidate every cache in the repository.
- ccache: `compiler_check=content`, `compression_level=1`, `hash_dir=false`,
  `inode_cache=true`, and
  `sloppiness=include_file_mtime,include_file_ctime,time_macros,locale,system_headers`
  so a freshly cloned tree still gets direct-mode hits.
- ThinLTO runs with `--thinlto-cache-policy=cache_size_bytes=1g:prune_after=168h`. LLVM's
  default is 75% of free disk, which would evict every other cache in the repository.
- **One writer per matrix run.** Actions cache keys are immutable, so exactly one job is
  elected `cache_writer` and the rest skip the save.
- **Save on failure too:** `always() && !cancelled() && cache_writer && exact miss`. A build
  that dies at 90% still warms the next run. ZIP and release stay success-only.
- **Summary Cache section:** hit flags plus hit-rate percentages, with the raw `ccache -s`
  text in the per-build summary and `ccache-stats.txt`. **Stripped** from GitHub Release
  notes (`matrix-summary-release.md`).
- Disk: hosted SDKs are relocated (a same-filesystem rename, so it returns at once) and
  purged in the background, so the delete overlaps the compile instead of blocking it.

Self-hosted overrides: `MARBLE_CCACHE_SIZE`, `MARBLE_CCACHE_COMPRESS_LEVEL`,
`MARBLE_CCACHE_SLOPPINESS`, `THINLTO_CACHE_MAX`, `THINLTO_CACHE_PRUNE_AFTER`.

## Reproducible builds

`SOURCE_DATE_EPOCH` and `KBUILD_BUILD_TIMESTAMP` come from the **kernel source commit date**,
so identical inputs produce a byte-identical `Image`. `uname -a` therefore shows the source
commit date rather than the CI run date; the real build time is recorded in `build-info`,
the summary, and the AnyKernel banner.
