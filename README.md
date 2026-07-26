<div align="center">

<img src="docs/assets/marble-banner.svg" alt="Marble Kernel Builder" width="720" />

**CI-driven AnyKernel3 kernel builder for Poco F5 / Redmi Note 12 Turbo**

`marble` · `marblein`

[![Build](https://img.shields.io/badge/GitHub_Actions-CI_Builder-2088FF?logo=githubactions&logoColor=white)](https://github.com/mohdakil2426/marble-kernel-builder/actions)
[![Device](https://img.shields.io/badge/Device-Poco_F5_%2F_RN12_Turbo-EF5350)](https://github.com/mohdakil2426/android_kernel_xiaomi_marble)
[![Managers](https://img.shields.io/badge/Managers-KernelSU_·_KSU--Next_·_SukiSU_·_ReSukiSU-4CAF50?logo=linux&logoColor=white)](#-managers)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.2.0-FF6D00?logo=gitlab&logoColor=white)](https://gitlab.com/simonpunk/susfs4ksu)

</div>

---

> [!WARNING]
> **Flashing a custom kernel can bootloop your phone, lose your data, or brick it.**
> Everything here is provided as-is and your warranty may no longer be valid.
>
> Before you flash, make sure all of these are true:
>
> - You have an **unlocked bootloader**
> - Your device is a **Poco F5** (`marblein`) or **Redmi Note 12 Turbo** (`marble`)
> - You saved the stock `boot.img` from the **same ROM and firmware**, **off-device**
> - The build you picked matches your **device and ROM family** (see the table below)
>
> By flashing these artifacts you accept all risk.

---

## What this does

You pick a kernel source, a root manager, and a few options in the GitHub Actions UI.
CI checks out the kernel, applies the manager and SUSFS **in the runner workspace only**,
compiles it, and hands back a flashable AnyKernel3 ZIP with full provenance.

Kernel source repositories are never modified. Every patch lives and dies inside one CI job.

```text
Pick options in Actions
        ↓
Check out the selected kernel source
        ↓
Apply manager + SUSFS (runner workspace only)
        ↓
Compile with a pinned, checksum-verified toolchain
        ↓
Package AnyKernel3 ZIP + checksums + metadata
        ↓
Upload artifacts  ·  optionally open a draft release
```

| Capability | Detail |
|---|---|
| Kernel sources | Melt (HyperOS) · LineageOS · Evolution-X · aosp-pablo · pa-gr |
| Root managers | KernelSU · KernelSU-Next · SukiSU Ultra · ReSukiSU · or a clean no-root baseline |
| SUSFS | Optional, `v2.2.0` / `v2.1.0` / custom, for managers that support it |
| LTO | `none` · `thin` (default) · `full` |
| Builds per run | One manager or several in parallel, with one combined summary |
| Safety | Codename check and automatic boot backup at flash time |
| Provenance | Commit-pinned toolchains, allowlisted managers, policy tests, ZIP attestations |
| Reproducible | Build timestamp pinned to the source commit, so identical inputs give an identical `Image` |

---

## 📱 Supported devices

| Device | Codename |
|---|---|
| Poco F5 | `marblein` |
| Redmi Note 12 Turbo | `marble` |

No other device is supported. Do not flash these on anything else.

---

## ⚙️ Kernel sources

Pick one from the `kernel_source` dropdown. **Flash only on the matching ROM family** —
a LOS-family kernel on stock HyperOS (or the reverse) will not boot.

| Dropdown | Source repo | Default ref | Flash on | Toolchain (`auto`) |
|---|---|---|---|---|
| `melt` | [`mohdakil2426/android_kernel_xiaomi_marble`](https://github.com/mohdakil2426/android_kernel_xiaomi_marble) | `melt-rebase` | Stock **HyperOS** | `android-r416183b` |
| `lineageos` | [`LineageOS/android_kernel_xiaomi_sm8450`](https://github.com/LineageOS/android_kernel_xiaomi_sm8450) | `lineage-23.2` | **LOS-based** ROMs only | `llvm-22.1.8` |
| `evolution-x` | [`Evolution-X-Devices/kernel_xiaomi_sm8450`](https://github.com/Evolution-X-Devices/kernel_xiaomi_sm8450) | `cnb` | **LOS-based** ROMs only | `llvm-22.1.8` |
| `aosp-pablo` | [`aosp-pablo/android_kernel_xiaomi_sm8450`](https://github.com/aosp-pablo/android_kernel_xiaomi_sm8450) | `16` | **LOS-based** ROMs only | `llvm-22.1.8` |
| `pa-gr` | [`pa-gr/android_kernel_xiaomi_sm8450`](https://github.com/pa-gr/android_kernel_xiaomi_sm8450) | `vauxite` | **LOS-based** ROMs only | `llvm-22.1.8` |

- `melt` builds a single `marble_defconfig`; the LOS family merges `gki_defconfig` with the
  marble vendor GKI fragments.
- LOS-family kernels need LLVM 22 for armv9 flags — leave `toolchain` on `auto` and it is
  chosen for you.
- `source_ref` overrides the default branch, tag, or commit when you need it.
- `pa-gr@vauxite` may ship an in-tree KernelSU; smoke-test the manager apply before trusting it.

---

## 🔑 Managers

| Manager | Without SUSFS | With SUSFS | Notes |
|---|:---:|:---:|---|
| `none` | yes | — | Baseline no-root validation build |
| `kernelsu` | yes | — | Official only; no compatible SUSFS path exists yet |
| `kernelsu-next` | yes | yes | No SUSFS uses official `dev`; SUSFS uses `pershoot/dev-susfs` |
| `sukisu-ultra` | yes | yes | No SUSFS uses `main`; SUSFS uses official `builtin` |
| `resukisu` | yes | yes | `main` already includes manager-side SUSFS |

Only **official upstream** manager repositories are allowlisted at CI time. The single
exception is `pershoot/KernelSU-Next@dev-susfs`, which is a CI-proven fork of official `dev`
for the KernelSU-Next SUSFS path. Arbitrary forks are rejected by `validate-inputs.sh`.

For final SUSFS builds use `kernelsu-next`, `sukisu-ultra`, or `resukisu`.

---

## Building

1. Open **[Actions → Build Marble Kernel → Run workflow](https://github.com/mohdakil2426/marble-kernel-builder/actions)**
2. Pick a **kernel source**
3. Tick one or more **manager** checkboxes
4. Leave `toolchain=auto` and `lto=thin` unless you know you need otherwise
5. Run, then download the artifacts when the run goes green

If you are building for the first time, work up in this order and verify each step boots
before moving on:

| Step | Build |
|:---:|---|
| 1 | `melt` · no manager · `image-only` |
| 2 | Same, plus one manager, SUSFS off |
| 3 | `kernelsu-next` / `sukisu-ultra` / `resukisu` with SUSFS on |
| 4 | A LOS preset, starting with no manager |
| 5 | Multi-manager matrix, optionally with `create_draft_release` |

<details>
<summary><b>All workflow inputs</b></summary>

<br/>

| Input | Default | Description |
|---|---|---|
| `build_none` | `false` | Baseline no-root kernel |
| `build_kernelsu` | `false` | KernelSU (no SUSFS) |
| `build_kernelsu_next` | `false` | KernelSU-Next |
| `build_sukisu_ultra` | `false` | SukiSU Ultra |
| `build_resukisu` | `false` | ReSukiSU |
| `enable_susfs` | `false` | Enable SUSFS for managers that support it |
| `susfs_version` | `v2.2.0` | `v2.2.0` · `v2.1.0` · `custom` |
| `susfs_ref` | *(empty)* | Branch, tag, or commit — only with `custom` |
| `kernel_source` | `melt` | See the kernel source table above |
| `source_ref` | *(empty)* | Override the preset's default ref |
| `build_scope` | `image-only` | `image-only` or `full` (adds modules and dtbs) |
| `toolchain` | `auto` | `auto` · `android-r416183b` · `llvm-22.1.8` |
| `lto` | `thin` | `none` · `thin` (free-runner safe) · `full` (needs more RAM) |
| `enable_ccache` | `true` | Object cache plus the ThinLTO cache when `lto=thin` |
| `create_draft_release` | `false` | Open one ZIP-only draft release after a fully green run |

</details>

<details>
<summary><b>Draft releases</b></summary>

<br/>

Tick `create_draft_release` in the same run. The release job runs only when **every**
selected build **and** the combined summary succeed. It re-verifies each ZIP against its
recorded SHA-256 before attaching anything.

Assets are **flashable ZIPs only** — checksums and build metadata stay in the Actions
artifacts. The result is a **draft**; review it and publish manually. The checkbox is the
only gate, with no GitHub Environment approval involved.

</details>

---

## 📦 Artifacts

Each build produces two artifacts: `marble-flash-…` with the ZIP and everything else, and
`marble-meta-…` with just the text metadata that the combined summary needs.

```text
marble-flash-<label>-<scope>-r<run>/
├─ AK3_marble_<FAMILY>_<source>_<manager>[-version][-codeN][_susfs-vX.Y.Z]_rN.zip
├─ *.zip.sha256
├─ build-info.txt       # resolved refs + workflow metadata
├─ build-info.json      # the same, structured for tooling
├─ summary.md           # per-build summary
├─ zip-audit.txt        # ZIP structure audit
└─ ccache-stats.txt     # raw ccache -s
```

`FAMILY` is `MELT` for `melt` and `LOS` for the other four sources. Version numbers come
from the manager build itself, falling back to its resolved tag and then to a 7-character
commit. LTO and toolchain are recorded in the flash banner and `build-info`, not in the
filename.

```text
AK3_marble_MELT_melt_ksunext-v3.2.0-code33203_susfs-v2.2.0_r121.zip
AK3_marble_LOS_evolution-x_sukisu-v4.1.3-code40813_susfs-v2.2.0_r122.zip
AK3_marble_MELT_melt_noroot_r124.zip
```

---

## Flashing

1. Download the ZIP and **verify its SHA-256** against the run summary
2. Flash it to the **active slot** with [Kernel Flasher](https://github.com/fatalcoder524/KernelFlasher/releases)
3. AnyKernel3 checks your codename and backs up the current boot image to
   `/sdcard/marble-kernel-backup/` before writing
4. Reboot, then install or open the matching manager app
5. For a SUSFS build, also install the
   [SUSFS userspace module](https://github.com/sidex15/susfs4ksu-module/releases) and set
   your hiding rules — kernel patches alone are not enough

> [!WARNING]
> **Bootloop?** Flash the stock `boot.img` from the same ROM and firmware back to the active
> slot. On A/B devices, target the correct slot, or both if you are unsure. Keep that backup
> somewhere you can reach it from a PC.

---

## CI design

Static checks (`shellcheck`, `actionlint`, policy tests) run on every push through
[`preflight.yml`](.github/workflows/preflight.yml) before any build burns a runner.

| Area | Approach |
|---|---|
| Actions | Pinned to immutable commits, Dependabot weekly |
| Android Clang | Partial clone + sparse checkout, pinned commit verified before use |
| LLVM 22.1.8 | Official release tarball, SHA-256 checked |
| Toolchain check | Every `llvm-*` binutil `LLVM=1` needs is asserted before compiling |
| Object cache | One shared bucket per toolchain + LTO + source, rotated weekly, capped at 2 GiB |
| ThinLTO cache | Bounded at 1 GiB (LLVM would otherwise grow it to 75% of free disk) |
| Cache writer | Exactly one matrix job saves, since Actions cache keys are immutable |
| Free-runner tuning | 16 GiB swap when `lto ≠ none`, ThinLTO jobs capped at 2, LLVM `JOBS` capped at 2 |
| Artifacts | Zero recompression, 30-day retention, metadata split from ZIPs |
| Permissions | Build jobs are `contents: read`; only the optional release job can write |
| Provenance | OIDC-backed attestations on the final ZIPs, plus the digest of every manager `setup.sh` executed |

**Deep dive:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
**Exact pins:** [`docs/versions.md`](docs/versions.md).

<details>
<summary><b>Recent verification</b></summary>

<br/>

**2026-07-13** — Melt no-root + thin ([29211438837](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29211438837)) ·
LineageOS no-root + thin + LLVM ([29212535876](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29212535876)) ·
LineageOS KSU-Next + SUSFS + thin ([29214274071](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29214274071))

**2026-07-12** — Multi-kernel smoke across all presets
([29189567468](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29189567468) … [29192972075](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29192972075))

**2026-06-22** — Melt device boot: KernelSU-Next, SukiSU Ultra, ReSukiSU with SUSFS v2.2.0 (r46–r48)

LOS-family manager and SUSFS builds are CI-verified at compile and package level. Device
boot proof currently exists for **Melt / HyperOS** only.

</details>

---

## Credits

| Project | For |
|---|---|
| Kernel source maintainers | Melt, LineageOS, Evolution-X, aosp-pablo, pa-gr trees |
| [osm0sis](https://github.com/osm0sis/AnyKernel3) | AnyKernel3 flashing framework |
| [tiann](https://github.com/tiann/KernelSU) | KernelSU |
| [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) | KernelSU-Next |
| [pershoot](https://github.com/pershoot/KernelSU-Next) | KernelSU-Next `dev-susfs` integration |
| [SukiSU Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) | SukiSU Ultra |
| [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) | ReSukiSU |
| [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) | susfs4ksu patches |
| [sidex15](https://github.com/sidex15/susfs4ksu-module) | SUSFS userspace module |
| [WildKernels](https://github.com/WildKernels/GKI_KernelSU_SUSFS) | Reference CI, cache, and release patterns |
| Device and ROM communities | HyperOS and LOS-family marble support |

Found a builder or CI problem? [Open an issue](https://github.com/mohdakil2426/marble-kernel-builder/issues).

<div align="center">

Built with GitHub Actions · for Marble

`marble` · `marblein`

</div>
