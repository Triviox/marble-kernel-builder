<!--
  Design reference for the combined matrix summary
  (scripts/generate-matrix-summary.sh → matrix-summary.md / release notes).

  GENERATED from the real generator with fixture data — regenerate it, do not
  hand-edit. Sample data mirrors a 3-manager SUSFS matrix on the Melt preset.
  Sizes and SHA-256 values are placeholders; production fills them from the
  real ZIPs.
-->

<div align="center">

<img src="https://raw.githubusercontent.com/mohdakil2426/marble-kernel-builder/main/docs/assets/marble-banner.svg" alt="Marble Kernel" width="720" />

<br/>

# Marble Kernel · Matrix Build

**Combined summary for a successful multi-manager CI run**

`marble` · `marblein` · `image-only`

<br/>

[![Matrix](https://img.shields.io/badge/Matrix-3_managers_passed-4CAF50?logo=githubactions&logoColor=white)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/1)
[![LTO](https://img.shields.io/badge/LTO-thin-9C27B0)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/1)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.2.0-FF6D00?logo=gitlab&logoColor=white)](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d)
[![Device](https://img.shields.io/badge/Device-Poco_F5_%2F_RN12_Turbo-EF5350)](https://github.com/mohdakil2426/android_kernel_xiaomi_marble)
[![Scope](https://img.shields.io/badge/Scope-image--only-2088FF)](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/1)

<br/>

🕐 **2026-07-26 21:10:03 UTC** &nbsp;·&nbsp; 🔢 **Run #5** &nbsp;·&nbsp; 🔗 **[View workflow](https://github.com/mohdakil2426/marble-kernel-builder/actions/runs/1)**

</div>

---

## ✅ Result

> [!NOTE]
> **3 of 3 manager builds passed.** Every ZIP below was compiled from the **same** kernel commit, the **same** toolchain and the **same** SUSFS commit — they differ *only* by root manager.

| Manager | Version | Code | SUSFS | Build | Size |
|:---|:---|:---:|:---:|:---:|:---:|
| **KernelSU-Next** | `v3.2.0` | `33201` | 🛡️ on | ✅ passed | *sample* |
| **SukiSU Ultra** | `v4.1.3-b88403d2@HEAD` | `40813` | 🛡️ on | ✅ passed | *sample* |
| **ReSukiSU** | `v4.1.0-d0f59d06@ReSukiSU` | `34989` | 🛡️ on | ✅ passed | *sample* |

---

## 🎯 Which ZIP do I flash?

> [!IMPORTANT]
> **Pick exactly one.** These are alternative kernels, not components of a set. Flashing a second one simply replaces the first.

| If you want | Flash this ZIP | Then install |
|:---|:---|:---|
| **KernelSU-Next** `v3.2.0` | `AK3_marble_MELT_melt_ksunext-v3.2.0-code33201_susfs-v2.2.0_r5.zip` | [KernelSU-Next app](https://github.com/KernelSU-Next/KernelSU-Next/releases) |
| **SukiSU Ultra** `v4.1.3-b88403d2@HEAD` | `AK3_marble_MELT_melt_sukisu-v4.1.3-b88403d2-code40813_susfs-v2.2.0_r5.zip` | [SukiSU Ultra app](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) |
| **ReSukiSU** `v4.1.0-d0f59d06@ReSukiSU` | `AK3_marble_MELT_melt_resukisu-v4.1.0-d0f59d06-code34989_susfs-v2.2.0_r5.zip` | [ReSukiSU app](https://github.com/ReSukiSU/ReSukiSU) |

Every rooted ZIP here also needs the [SUSFS userspace module](https://github.com/sidex15/susfs4ksu-module/releases) matching `v2.2.0`. The kernel patch alone does not give you working hiding.

---

## ⚠️ Before you flash

> [!CAUTION]
> Custom kernels can bootloop or cause data loss. Artifacts are provided **as-is**.

| | Check |
|:---:|:---|
| 🟠 | **Official Xiaomi stock HyperOS only** — flashing across ROM families is the most common way to bootloop this device |
| 📱 | **Poco F5** (`marblein`) or **Redmi Note 12 Turbo** (`marble`) only |
| 🔓 | Unlocked bootloader required |
| 💾 | Back up `boot.img` from the **same** ROM / firmware, stored **off-device** |
| 🧩 | Match **device + ROM** to the build you flash |
| ✅ | Verify **SHA-256** before flashing |

---

## ⚙️ Matrix configuration

| | |
|:---|:---|
| 📱 **Device** | Poco F5 (`marblein`) · Redmi Note 12 Turbo (`marble`) |
| 🟠 **ROM support** | **Official Xiaomi stock HyperOS only** |
| 👤 **Kernel source** | **Melt** ([`melt`](https://github.com/mohdakil2426/android_kernel_xiaomi_marble)) |
| 📦 **Source** | [`melt-rebase @ 3673961`](https://github.com/mohdakil2426/android_kernel_xiaomi_marble/commit/3673961d444b5e2b879be97a161241243d543bd2) |
| 🧬 **Kernel base** | `android12-5.10` |
| 🧾 **Defconfig** | `marble_defconfig` · mode `single` |
| 🛠️ **Build scope** | `image-only` |
| 🏷️ **Package family** | `MELT` |
| 🔗 **LTO** | `thin` |
| 🧰 **Toolchain** | `android-r416183b` |
| 🔨 **Compiler** | `clang-r416183b` |
| 🧷 **Compiler commit** | `6e3223f` |
| 🛡️ **SUSFS** | `v2.2.0` · `gki-android12-5.10` · [`4003ecf`](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d) |
| 🧪 **Quality** | `melt-stable-candidate` |
| 🖥️ **Runner** | `ubuntu24` · image `20260720.1.0` · `28 GiB` free before build |
| ✅ **Result** | **3 / 3** manager builds passed |

---

<!-- marble-ci-cache-start -->
## 💾 Cache

> CI diagnostics only — this section is **not** included in GitHub Release notes.

| Manager | Actions ccache | Actions ThinLTO | Hit rate |
|:---|:---:|:---:|:---:|
| **KernelSU-Next** | `false` | `false` | 105 / 2875 ( 3.65%) |
| **SukiSU Ultra** | `false` | `false` | 105 / 2875 ( 3.65%) |
| **ReSukiSU** | `false` | `false` | 105 / 2875 ( 3.65%) |

### ccache -s — KernelSU-Next

```text
Cacheable calls:   2875 / 4422 (65.02%)
  Hits:             105 / 2875 ( 3.65%)
  Misses:          2770 / 2875 (96.35%)
Local storage:
  Cache size (GB):  0.5 /  4.0 (12.50%)
```

### ccache -s — SukiSU Ultra

```text
Cacheable calls:   2875 / 4422 (65.02%)
  Hits:             105 / 2875 ( 3.65%)
  Misses:          2770 / 2875 (96.35%)
Local storage:
  Cache size (GB):  0.5 /  4.0 (12.50%)
```

### ccache -s — ReSukiSU

```text
Cacheable calls:   2875 / 4422 (65.02%)
  Hits:             105 / 2875 ( 3.65%)
  Misses:          2770 / 2875 (96.35%)
Local storage:
  Cache size (GB):  0.5 /  4.0 (12.50%)
```

<!-- marble-ci-cache-end -->
---

## 🔑 Managers

| Manager | Version | Code | SUSFS | Status |
|:---|:---|:---:|:---:|:---:|
| **KernelSU-Next** | `v3.2.0` | `33201` | ✅ | ✅ Passed |
| **SukiSU Ultra** | `v4.1.3-b88403d2@HEAD` | `40813` | ✅ | ✅ Passed |
| **ReSukiSU** | `v4.1.0-d0f59d06@ReSukiSU` | `34989` | ✅ | ✅ Passed |

<details>
<summary><b>KernelSU-Next</b> — v3.2.0 · code 33201 · ✅ Passed</summary>

<br/>

| | |
|:---|:---|
| 📁 **Repository** | [`pershoot/KernelSU-Next @ dev-susfs`](https://github.com/pershoot/KernelSU-Next) |
| 🔖 **Version** | `v3.2.0` |
| 🔢 **Version code** | `33201` |
| 🔗 **Commit** | [`5a8a604`](https://github.com/pershoot/KernelSU-Next/commit/5a8a604a9078c2fbfb50e2b0cba87b3a6f4da1c2) |
| 📦 **Flashable ZIP** | `AK3_marble_MELT_melt_ksunext-v3.2.0-code33201_susfs-v2.2.0_r5.zip` |
| 📌 **Ref policy** | Non-SUSFS builds use official `KernelSU-Next/KernelSU-Next@dev` · SUSFS builds use `pershoot/dev-susfs` |
| 📦 **App** | [Manager releases](https://github.com/KernelSU-Next/KernelSU-Next/releases) |

</details>

<details>
<summary><b>SukiSU Ultra</b> — v4.1.3-b88403d2@HEAD · code 40813 · ✅ Passed</summary>

<br/>

| | |
|:---|:---|
| 📁 **Repository** | [`SukiSU-Ultra/SukiSU-Ultra @ builtin`](https://github.com/SukiSU-Ultra/SukiSU-Ultra) |
| 🏷️ **Version name** | `v4.1.3-b88403d2@HEAD` |
| 🔢 **Version code** | `40813` |
| 🔗 **Commit** | [`b88403d`](https://github.com/SukiSU-Ultra/SukiSU-Ultra/commit/b88403d2561b6e00dff84a3c851e630c62f57fd0) |
| 📦 **Flashable ZIP** | `AK3_marble_MELT_melt_sukisu-v4.1.3-b88403d2-code40813_susfs-v2.2.0_r5.zip` |
| 📦 **App** | [Manager releases](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) |

</details>

<details>
<summary><b>ReSukiSU</b> — v4.1.0-d0f59d06@ReSukiSU · code 34989 · ✅ Passed</summary>

<br/>

| | |
|:---|:---|
| 📁 **Repository** | [`ReSukiSU/ReSukiSU @ main`](https://github.com/ReSukiSU/ReSukiSU) |
| 🏷️ **Version name** | `v4.1.0-d0f59d06@ReSukiSU` |
| 🔢 **Version code** | `34989` |
| 🔗 **Commit** | [`88e7f51`](https://github.com/ReSukiSU/ReSukiSU/commit/88e7f51c3840436b982276ec35bf2876cfec2713) |
| 📦 **Flashable ZIP** | `AK3_marble_MELT_melt_resukisu-v4.1.0-d0f59d06-code34989_susfs-v2.2.0_r5.zip` |
| 📦 **App** | [Manager releases](https://github.com/ReSukiSU/ReSukiSU) |

</details>

---

## 🛡️ SUSFS

| | |
|:---|:---|
| 🏷️ **Version** | `v2.2.0` |
| 🌿 **Kernel branch** | `gki-android12-5.10` |
| 🔗 **Commit** | [`4003ecf`](https://gitlab.com/simonpunk/susfs4ksu/-/commit/4003ecf2d01c6d13fa8edf6c4f2607365738dc3d) |
| ✅ **Kconfig verified** | `CONFIG_KSU=y` · `CONFIG_KSU_SUSFS=y` |
| 📦 **Userspace module** | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases) |

### SUSFS userspace module

If this build includes **SUSFS**, flash the kernel ZIP **and** install a compatible SUSFS userspace module for your manager (for example [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases)). Kernel patches alone are not enough for full hide functionality.

---

## 📦 Artifacts & checksums

| Manager | File | Size | SHA-256 |
|:---|:---|:---:|:---|
| KernelSU-Next | `AK3_marble_MELT_melt_ksunext-v3.2.0-code33201_susfs-v2.2.0_r5.zip` | *sample* | `…` *(computed at build time)* |
| SukiSU Ultra | `AK3_marble_MELT_melt_sukisu-v4.1.3-b88403d2-code40813_susfs-v2.2.0_r5.zip` | *sample* | `…` *(computed at build time)* |
| ReSukiSU | `AK3_marble_MELT_melt_resukisu-v4.1.0-d0f59d06-code34989_susfs-v2.2.0_r5.zip` | *sample* | `…` *(computed at build time)* |

Each artifact also carries `build-info.txt`, `build-info.json`, `summary.md`, `zip-audit.txt` and `ccache-stats.txt`.

---

## 🔁 Reproduce this build

Every resolved input, in one block. Same values in → byte-identical `Image` out.

```yaml
kernel_source:   melt
source_repo:     mohdakil2426/android_kernel_xiaomi_marble
source_ref:      melt-rebase
source_commit:   3673961d444b5e2b879be97a161241243d543bd2
toolchain:       android-r416183b
clang_commit:    6e3223f76384455acde43affde3df0ea9df66c0d
lto:             thin
build_scope:     image-only
enable_susfs:    true
susfs_version:   v2.2.0
susfs_branch:    gki-android12-5.10
susfs_commit:    4003ecf2d01c6d13fa8edf6c4f2607365738dc3d
anykernel3:      dca9dc370838d919d56c1f59ec78b27a14a72c68
managers:
  kernelsu-next: pershoot/KernelSU-Next@dev-susfs 5a8a604a9078c2fbfb50e2b0cba87b3a6f4da1c2
  sukisu-ultra: SukiSU-Ultra/SukiSU-Ultra@builtin b88403d2561b6e00dff84a3c851e630c62f57fd0
  resukisu: ReSukiSU/ReSukiSU@main 88e7f51c3840436b982276ec35bf2876cfec2713
```

🔏 **Provenance** — every ZIP carries an OIDC-backed [artifact attestation](https://github.com/mohdakil2426/marble-kernel-builder/attestations). Verify a download with:

```bash
gh attestation verify <zip> --repo mohdakil2426/marble-kernel-builder
```

---

## 📲 Installation

<details>
<summary><b>Prerequisites</b></summary>

<br/>

- 🔓 Unlocked bootloader
- 📱 Poco F5 (`marblein`) or Redmi Note 12 Turbo (`marble`) only
- 🧩 Kernel build that matches your **device + ROM**
- 💾 Original `boot.img` from the same ROM/firmware stored **off-device**
- 🧵 Free runners: avoid many parallel LOS+LLVM jobs; prefer `lto=thin`
- 📦 [KernelSU-Next manager app](https://github.com/KernelSU-Next/KernelSU-Next/releases) for the KernelSU-Next ZIP
- 📦 [SukiSU Ultra manager app](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) for the SukiSU Ultra ZIP
- 📦 [ReSukiSU manager app](https://github.com/ReSukiSU/ReSukiSU) for the ReSukiSU ZIP
- 🛡️ [KSU SUSFS module](https://github.com/sidex15/susfs4ksu-module/releases) matching `v2.2.0`

</details>

<details>
<summary><b>Flash steps</b> (Kernel Flasher recommended)</summary>

<br/>

1. Download the ZIP for **one** manager
2. Verify **SHA-256** against the table above
3. Flash to the **active slot** with [Kernel Flasher](https://github.com/fatalcoder524/KernelFlasher/releases)
4. AnyKernel3 will verify codename (`marble` / `marblein`) and **auto-back up** boot to `/sdcard/marble-kernel-backup/`
5. Reboot · install / open the matching manager app
6. Install the SUSFS userspace module, configure rules, reboot

</details>

> [!CAUTION]
> **Bootloop?** Flash the original `boot.img` from the same ROM/firmware back to the active slot (Kernel Flasher or fastboot). On A/B devices confirm you are targeting the correct slot. Keep that backup accessible **before** you flash.

---

## 🙏 Credits

| | |
|:---|:---|
| 🧑‍💻 **Kernel source** | [Melt](https://github.com/mohdakil2426/android_kernel_xiaomi_marble) (`mohdakil2426/android_kernel_xiaomi_marble`) |
| 📦 **AnyKernel3** | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) |
| 🔑 **KernelSU-Next** | [`pershoot/KernelSU-Next`](https://github.com/pershoot/KernelSU-Next) |
| 🔑 **SukiSU Ultra** | [`SukiSU-Ultra/SukiSU-Ultra`](https://github.com/SukiSU-Ultra/SukiSU-Ultra) |
| 🔑 **ReSukiSU** | [`ReSukiSU/ReSukiSU`](https://github.com/ReSukiSU/ReSukiSU) |
| 🛡️ **SUSFS** | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) |

---

<div align="center">

**⚡ Built with GitHub Actions · for Marble**

<br/>

`marble` · `marblein`

</div>
