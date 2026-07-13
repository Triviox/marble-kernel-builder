# pa-gr source-local patches (ephemeral)

These patches are applied **only in CI / builder workspace** after checkout of
`pa-gr/android_kernel_xiaomi_sm8450`. They are **not** committed to the upstream
kernel repo.

## Scope

| Gate | Value |
|------|--------|
| Preset | `KERNEL_SOURCE=pa-gr` only |
| Branch / ref | `match_refs` in `config/kernel-sources.json` (default: `vauxite`) |
| When | After kernel checkout, **before** manager / SUSFS apply |

Other presets (`melt`, `lineageos`, …) never load this directory.

## Current series (`vauxite/`)

| Patch | Why |
|-------|-----|
| `0001-kvm-arm64-init-clidr-for-clang22.patch` | Clang 22 `-Werror,-Wuninitialized-const-pointer` on `arch/arm64/kvm/sys_regs.c` (`struct sys_reg_desc clidr` → `= {0}`). Same class of fix as stable discussions for older KVM tables. |

## When to remove

1. Upstream `vauxite` (or whatever `default_ref` is) already contains the init / rework, **or**
2. Patch no longer applies cleanly (hunk reject) because the tree moved past the issue, **or**
3. You change `default_ref` to a tree that builds with LLVM 22 without this line.

Then:

1. Delete the patch file and update `vauxite/series` (or remove the dir).
2. Set `source_patches.enabled` to `false` in `config/kernel-sources.json` for `pa-gr`, or drop the block.
3. Re-run a pa-gr smoke build.

Do **not** broaden these patches to other kernel presets.
