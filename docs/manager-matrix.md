# Manager Matrix

Last checked: 2026-07-13 (manager policy + multi-kernel presets including `pa-gr`). Kernel **source** selection is independent — see `config/kernel-sources.json` and README presets (Melt vs LOS-family: lineageos / evolution-x / aosp-pablo / pa-gr).

`none` is a baseline no-root build mode. It is useful for validating the clean kernel source, build system, packaging, and AnyKernel3 flashing path. It is not a root solution, and SUSFS is blocked with `none` because SUSFS needs manager-side KernelSU-compatible hooks.

| Manager | Without SUSFS | With SUSFS | Selected refs |
|---|---:|---:|---|
| `none` | Pass | Blocked | No manager source |
| `kernelsu` | Pass | Blocked | `tiann/KernelSU@main`; official KernelSU SUSFS is not used |
| `kernelsu-next` | Pass | Pass | `KernelSU-Next/KernelSU-Next@dev` without SUSFS; `pershoot/KernelSU-Next@dev-susfs` with SUSFS |
| `sukisu-ultra` | Pass | Pass | `SukiSU-Ultra/SukiSU-Ultra@main` without SUSFS; `SukiSU-Ultra/SukiSU-Ultra@builtin` with SUSFS |
| `resukisu` | Pass | Pass | `ReSukiSU/ReSukiSU@main` |

For final SUSFS builds, use only:

- `manager=kernelsu-next`
- `manager=sukisu-ultra`
- `manager=resukisu`

Do not use SUSFS with:

- `manager=none`
- `manager=kernelsu`
