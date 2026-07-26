<!--
  Design reference for the combined matrix summary
  (scripts/generate-matrix-summary.sh -> matrix-summary.md / release notes).

  Generated from the real generator with representative fixture data, so it
  cannot drift from the implementation. Regenerate rather than hand-editing.
-->

<div align="center">

<img src="https://raw.githubusercontent.com/mohdakil2426/marble-kernel-builder/main/docs/assets/marble-banner.svg" alt="Marble Kernel" width="720" />

# Marble Kernel · Matrix Build

**Combined summary for a multi-manager CI run**

`marble` · `marblein` · `image-only`

[![Matrix](https://img.shields.io/badge/Matrix-3_managers_passed-4CAF50?logo=githubactions&logoColor=white)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29214274071)
[![LTO](https://img.shields.io/badge/LTO-thin-9C27B0)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29214274071)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.2.0-FF6D00?logo=gitlab&logoColor=white)](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d)
[![Device](https://img.shields.io/badge/Device-Poco_F5_%2F_RN12_Turbo-EF5350)](https://github.com/mohdakil2426/android_kernel_xiaomi_marble)
[![Scope](https://img.shields.io/badge/Scope-image--only-2088FF)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29214274071)

**2026-07-26 09:14:02 UTC** &nbsp;·&nbsp; **Run #121** &nbsp;·&nbsp; [View workflow](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/29214274071)

</div>

---

## ⚠️ Before you flash

> [!WARNING]
> Custom kernels can bootloop or lose data. Artifacts are provided **as-is**.
>
> - Back up `boot.img` from the **same** ROM and firmware, stored off-device
> - Unlocked bootloader required
> - **Poco F5** (`marblein`) or **Redmi Note 12 Turbo** (`marble`) only
> - Match **device + ROM family** to the build you flash
> - Verify **SHA-256** before flashing

---

## ⚙️ Matrix configuration

| | |
|:---|:---|
| 📱 **Device** | Poco F5 (`marblein`) · Redmi Note 12 Turbo (`marble`) |
| **ROM support** | **Official Xiaomi stock HyperOS only** |
| **Kernel Source** | **Melt** ([`melt`](https://github.com/mohdakil2426/android_kernel_xiaomi_marble)) |
| **Kernel base** | `android12-5.10` |
| ⚙️ **Build scope** | `image-only` |
| **Package family** | `MELT` |
| **Quality** | `melt-stable-candidate` |
| **LTO** | `thin` |
| **Toolchain** | `android-r416183b` |
| **Source** | [`melt-rebase @ 3673961`](https://github.com/mohdakil2426/android_kernel_xiaomi_marble/commit/3673961d444b5e2b879be97a161241243d543bd2) |
| **Compiler** | `clang-r416183b` |
| **Compiler commit** | `6e3223f` |
| **Kernel timestamp** | `Fri Jul 24 11:02:19 UTC 2026` (pinned to the source commit) |
| 🛡️ **SUSFS** | `v2.2.0` · `gki-android12-5.10` · [`4003ecf`](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d) |
| **Result** | **3 / 3** manager builds passed |

---

<!-- marble-ci-cache-start -->
## Cache

> CI diagnostics only — this section is **not** included in GitHub Release notes.

| Manager | Actions ccache hit | Actions ThinLTO hit | ccache hit rate | Direct rate | Cache writer |
|:---|:---:|:---:|:---:|:---:|:---:|
| **KernelSU-Next** | `true` | `true` | `91.4%` | `88.2%` | `true` |
| **ReSukiSU** | `true` | `true` | `96.8%` | `94.1%` | `false` |
| **SukiSU Ultra** | `true` | `true` | `97.1%` | `95.0%` | `false` |

Raw `ccache -s` output is attached to each build as `ccache-stats.txt`.

<!-- marble-ci-cache-end -->
---

## 🔑 Managers

| Manager | Version | Code | SUSFS | Status |
|:---|:---|:---:|:---:|:---:|
| **KernelSU-Next** | `v3.2.0` | `33203` | yes | Passed |
| **ReSukiSU** | `v4.1.0` | `34990` | yes | Passed |
| **SukiSU Ultra** | `v4.1.3` | `40813` | yes | Passed |

<details>
<summary><b>KernelSU-Next</b> — v3.2.0 · code 33203 · Passed</summary>

| | |
|:---|:---|
| **Repository** | [`pershoot/KernelSU-Next @ dev-susfs`](https://github.com/pershoot/KernelSU-Next) |
| **Version name** | `v3.2.0` |
| **Version** | `v3.2.0` |
| **Version code** | `33203` |
| **Commit** | [`5a8a604`](https://github.com/pershoot/KernelSU-Next/commit/5a8a604a9078c2fbfb50e2b0cba87b3a6f4da1c2) |
| **setup.sh sha256** | `9f2c1b7d5e4a3c88f0b6d21e7a45c93b8de10f6742ab5c39d8e0741bc2a6f358` |
| **Note** | Non-SUSFS builds use official `KernelSU-Next/KernelSU-Next@dev`; SUSFS builds use `pershoot/dev-susfs` |
| **App** | [Manager releases](https://github.com/KernelSU-Next/KernelSU-Next/releases) |

</details>

<details>
<summary><b>ReSukiSU</b> — v4.1.0 · code 34990 · Passed</summary>

| | |
|:---|:---|
| **Repository** | [`ReSukiSU/ReSukiSU @ main`](https://github.com/ReSukiSU/ReSukiSU) |
| **Version name** | `v4.1.0` |
| **Version** | `v4.1.0` |
| **Version code** | `34990` |
| **Commit** | [`5a8a604`](https://github.com/ReSukiSU/ReSukiSU/commit/5a8a604a9078c2fbfb50e2b0cba87b3a6f4da1c2) |
| **setup.sh sha256** | `9f2c1b7d5e4a3c88f0b6d21e7a45c93b8de10f6742ab5c39d8e0741bc2a6f358` |
| **App** | [Manager releases](https://github.com/ReSukiSU/ReSukiSU) |

</details>

<details>
<summary><b>SukiSU Ultra</b> — v4.1.3 · code 40813 · Passed</summary>

| | |
|:---|:---|
| **Repository** | [`SukiSU-Ultra/SukiSU-Ultra @ builtin`](https://github.com/SukiSU-Ultra/SukiSU-Ultra) |
| **Version name** | `v4.1.3` |
| **Version** | `v4.1.3` |
| **Version code** | `40813` |
| **Commit** | [`5a8a604`](https://github.com/SukiSU-Ultra/SukiSU-Ultra/commit/5a8a604a9078c2fbfb50e2b0cba87b3a6f4da1c2) |
| **setup.sh sha256** | `9f2c1b7d5e4a3c88f0b6d21e7a45c93b8de10f6742ab5c39d8e0741bc2a6f358` |
| **App** | [Manager releases](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) |

</details>

---

## 🛡️ SUSFS

| | |
|:---|:---|
| **Version** | `v2.2.0` |
| **Kernel branch** | `gki-android12-5.10` |
| **Commit** | [`4003ecf`](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d) |
| **Userspace module** | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases) |

### SUSFS userspace module

A SUSFS kernel needs both halves: flash the kernel ZIP **and** install a matching SUSFS userspace module for your manager, for example [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases). Kernel patches alone do not give you full hide functionality.

---

## 📦 Artifacts & checksums

| Manager | File | Size | SHA-256 |
|:---|:---|:---:|:---|
| KernelSU-Next | `AK3_marble_MELT_melt_ksunext-v3.2.0-code33203_susfs-v2.2.0_r121.zip` | 30.0 MiB | `4c1f8a9e2b7d6035ae81c94f27b0d6e35a8c1927fd4e60b8391cae72d05f6b14` |
| ReSukiSU | `AK3_marble_MELT_melt_resukisu-v4.1.0-code34990_susfs-v2.2.0_r121.zip` | 30.0 MiB | `7ae03d21c6b95f8412d0e7ab35c9f6142d8be07a91c3f4652b8daf10e937c5d6` |
| SukiSU Ultra | `AK3_marble_MELT_melt_sukisu-v4.1.3-code40813_susfs-v2.2.0_r121.zip` | 30.0 MiB | `b25e9c740af1836d5e2b09fc7143ad86e0c95b2718df460a3c9e15782bd06f4a` |

---

## Installation

<details>
<summary><b>Prerequisites</b></summary>
<br/>

- Unlocked bootloader
- Poco F5 (`marblein`) or Redmi Note 12 Turbo (`marble`) only
- A kernel build that matches your **device + ROM**
- Original `boot.img` from the same ROM and firmware, stored off-device
- [KernelSU-Next manager app](https://github.com/KernelSU-Next/KernelSU-Next/releases) for the matching ZIP
- [ReSukiSU manager app](https://github.com/ReSukiSU/ReSukiSU) for the matching ZIP
- [SukiSU Ultra manager app](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) for the matching ZIP
- [KSU SUSFS module](https://github.com/sidex15/susfs4ksu-module/releases) matching `v2.2.0`

</details>

<details>
<summary><b>Flash steps</b> (Kernel Flasher recommended)</summary>
<br/>

1. Download the ZIP for **one** manager
2. Verify **SHA-256** against the table above
3. Flash the ZIP to the active slot with [Kernel Flasher](https://github.com/fatalcoder524/KernelFlasher/releases)
4. AnyKernel3 verifies the codename (`marble` / `marblein`) and backs up boot to `/sdcard/marble-kernel-backup/`
5. Reboot, then install or open the matching manager app
6. Install the SUSFS userspace module, configure rules, reboot

</details>

> [!WARNING]
> **Bootloop?** Flash the original `boot.img` from the same ROM and firmware back to the active slot with Kernel Flasher or fastboot. Keep that backup reachable **before** you flash.

---

## Credits

| | |
|:---|:---|
| **Kernel source** | [Melt](https://github.com/mohdakil2426/android_kernel_xiaomi_marble) (`mohdakil2426/android_kernel_xiaomi_marble`) |
| **AnyKernel3** | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) |
| **KernelSU-Next** | [`pershoot/KernelSU-Next`](https://github.com/pershoot/KernelSU-Next) |
| **ReSukiSU** | [`ReSukiSU/ReSukiSU`](https://github.com/ReSukiSU/ReSukiSU) |
| **SukiSU Ultra** | [`SukiSU-Ultra/SukiSU-Ultra`](https://github.com/SukiSU-Ultra/SukiSU-Ultra) |
| **SUSFS** | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) |

---

<div align="center">

Built with **GitHub Actions** · for Marble

`marble` · `marblein`

</div>
