# Pipeline, Cache, and Docs Overhaul — Design

**Date:** 2026-07-26
**Branch:** `feature/pipeline-cache-docs-overhaul` (base `origin/main` @ `600d978`)
**Status:** Approved

Goal: make the CI pipeline measurably faster and the cache actually effective, simplify
the scripts, and rewrite the user-facing markdown. No kernel source is touched — every
change lives in this builder repo.

---

## 1. Problem statement

### 1.1 The cache does not work

Four independent facts combine into a cache that is effectively always cold.

| Fact | Source | Consequence |
|---|---|---|
| A repository gets **10 GB total** of Actions cache, LRU-evicted, 7-day idle expiry | [GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) | The whole allowance is roughly one build's worth |
| The ThinLTO cache has no `--thinlto-cache-policy`; LLVM's default is `cache_size = 75%` of free disk | [`CachePruning.h`](https://github.com/llvm/llvm-project/blob/main/llvm/include/llvm/Support/CachePruning.h) — `MaxSizePercentageOfAvailableSpace = 75` | A single save can be tens of GB and evict everything else |
| The ccache primary key embeds `source_commit`, `manager_commit`, `susfs_commit` — all moving branches | `build-core.yml` "Generate ccache key" | The primary key **misses every run**, so every run uploads a fresh 4–6 GiB entry |
| The matrix runs up to five managers in parallel, each saving its own ccache | `build-matrix.yml` | 20–30 GB pushed into a 10 GB budget per run |

Two smaller ccache problems compound it:

- `ccache -o compression_level=6`. The ccache manual notes higher levels "may slow down
  compilations noticeably"; the default is 1.
- No `sloppiness`. Direct mode is disabled when an include file's modification time is
  "too new" — and `fetch-depth: 1` gives every file a fresh mtime on every run.

### 1.2 Redundant work in the pipeline

| Where | Redundancy |
|---|---|
| `resolve-refs.sh` → `apply-susfs.sh` | susfs4ksu is cloned twice; the second clone is not shallow |
| `resolve-toolchain.sh` | Re-runs `resolve-kernel-source.sh`, which build-core already ran, doubling `GITHUB_ENV` lines |
| `build-core.yml` disk cleanup | Blocking `sudo rm -rf` of dotnet/android/ghc before compile starts |
| `build-core.yml` apt | Installs `clang`, `llvm`, `lld` that the pinned toolchain already provides |
| `build-matrix.yml` aggregate | Downloads every multi-hundred-MB ZIP to read ~20 KB of metadata |
| `resolve-kernel-source.sh` | `eval "$(python3 …)"` swallows a Python failure; the script dies later with a confusing "unbound variable" |

### 1.3 Docs and scripts

- README is 428 lines with three overlapping preset tables and roughly sixty distinct emoji.
- The two summary generators (336 + 490 lines) duplicate six whole sections.
- `package-anykernel.sh` spends twenty lines on a `_caller_*`/`_preset_*` save-restore dance.
- `generate-matrix-summary.sh` re-greps each `build-info.txt` four to six times per manager.
- The memory bank is stale: it records `main @ 2ce4092` and knows nothing about pa-gr or PR #8.

---

## 2. Cache design (v5)

### 2.1 Key shape

One bucket per *(toolchain, LTO mode, kernel source)*, rotated weekly.

```text
bucket  = marble-{kind}-v5-{os}-{arch}-{toolchain}-lto{mode}-{kernel_source}
key     = {bucket}-{code_hash}-w{isoweek}
restore = {bucket}-{code_hash}-
          {bucket}-
```

- `{kind}` is `ccache` or `thinlto`.
- `{isoweek}` is `date -u +%GW%V`, e.g. `2026W30`.
- `{code_hash}` is the first eight hex characters of a SHA-256 over
  `scripts/build-kernel.sh` and `config/marble.env` — the only two files that change
  compilation semantics.

Dropped from the key:

| Dropped | Rationale |
|---|---|
| `source_commit` | Moves per run; guarantees a primary-key miss |
| `manager`, `manager_commit` | Manager objects are a rounding error against the kernel tree |
| `susfs_commit` | Same |
| `build_scope` | `full` is a superset of `image-only`; sharing helps both |
| `managers.json`, `susfs-refs.json`, `kernel-sources.json`, `resolve-kernel-source.sh`, `patches/**` from `code_hash` | Adding a preset must not invalidate every cache in the repo |

The two-level restore chain is deliberate. There is **no** broad `marble-ccache-v5-` fallback,
because restoring a different kernel source's cache costs a multi-GB download for near-zero hits.

Expected live entries: one to three, against dozens today.

### 2.2 Single writer per matrix

`generate-build-matrix.sh` sets `cache_writer: "true"` on exactly one include entry — the
first selected manager in the canonical order `none, kernelsu, kernelsu-next, sukisu-ultra,
resukisu`. `build-core.yml` gains a `cache_writer` input (default `true`, so direct callers
such as the weekly smoke still save) and gates both save steps on it.

### 2.3 Sizes and tuning

Set once, in `build-kernel.sh`:

| Setting | Before | After | Reason |
|---|---|---|---|
| `max_size` | 4G / 6G | **2G** | Fits the 10 GB budget alongside both toolchain caches |
| `compression_level` | 6 | **1** | ccache manual: high levels slow compilation noticeably |
| `sloppiness` | unset | `include_file_mtime,include_file_ctime,time_macros,locale,system_headers` | Re-enables direct mode on a freshly cloned tree |
| `inode_cache` | unset | `true` | Reduces include-hashing time |
| `compiler_check` | `content` | `content` | Unchanged |
| `hash_dir` | `false` | `false` | Unchanged |

ThinLTO wrapper gains `--thinlto-cache-policy=cache_size_bytes=1g:prune_after=168h`.

### 2.4 Explicitly rejected WildKernels settings

WildKernels' `.github/actions/cache-ccache-setup` sets three things this design refuses:

| Setting | Why not |
|---|---|
| `CCACHE_FILE_CLONE=true` | ccache manual: cloned files "cannot be compressed, so the cache size will likely be significantly larger" — wrong for a 10 GB budget |
| `CCACHE_BASEDIR` | The manual calls it "a brittle hack" that breaks dependency files; `hash_dir=false` already covers us and the workspace path is stable on hosted runners |
| `CCACHE_MAXSIZE=12G` | One entry would consume the entire repository allowance |

`CCACHE_DEPEND` is also left off. Wild enables it; the ccache manual lists "lower hit rate"
as the explicit downside. Not worth trading blind. Hit-rate reporting (§3.9) makes it a
measurable decision later.

### 2.5 Toolchain caches

Unchanged (`clang-v3`, `llvm-v1`). Their keys are already stable, they are touched every
run so LRU keeps them warm, and bumping the version prefix would discard working caches for
no benefit.

---

## 3. Pipeline changes

### 3.1 Single SUSFS clone

`resolve-refs.sh` keeps its blobless clone at `susfs4ksu/` instead of deleting it;
`apply-susfs.sh` reuses that checkout rather than performing a second, non-shallow clone.
The `resolve-refs.sh` cleanup trap stays for the failure path.

### 3.2 Drop the duplicate preset resolve

`resolve-toolchain.sh` re-resolves only when `release/kernel-source.env` is absent or
records a different `KERNEL_SOURCE` than the caller's. In CI the file is always fresh, so
the second resolve disappears; the standalone and test paths keep working.

### 3.3 Background disk cleanup

Replace the blocking `sudo rm -rf` with the WildKernels pattern: `mv` targets into a trash
directory (space is freed immediately) and purge in the background under `nice -n 19
ionice -c 3`, overlapping the compile.

### 3.4 Trim apt, add a toolchain completeness check

Drop `clang`, `llvm`, `lld`, `libncurses-dev`. The pinned toolchain supplies `clang`,
`ld.lld` and the `llvm-*` binutils that `LLVM=1` requires; ncurses is only needed for
`menuconfig`. The "Select active toolchain" step gains an assertion that
`clang ld.lld llvm-ar llvm-nm llvm-objcopy llvm-strip llvm-readelf llvm-objdump` all exist
in the selected bin directory, so a gap fails in seconds instead of mid-link.

### 3.5 Metadata artifact

Each build additionally uploads `marble-meta-<label>-<scope>-r<run>` containing only the
text metadata. `aggregate-summary` downloads that pattern instead of `marble-flash-*`.
`marble-flash-*` keeps its current contents, so the release path is untouched and
`prepare-promoted-release.sh` still re-verifies real checksums against real ZIPs.

`zip-name.env` gains `zip_size_bytes` so the matrix summary can report size without the ZIP
present.

### 3.6 Fail-fast on Python

`resolve-kernel-source.sh` and `apply-kernel-source-patches.sh` capture Python output into a
variable, check the exit status and non-emptiness, and emit a clear `::error::` before
`eval`.

### 3.7 Preflight on all branches

`preflight.yml` `push:` drops its `branches: [main]` filter. Concurrency already cancels
in-progress runs, so the cost is roughly one minute per push.

### 3.8 Provenance

`patch-manager.sh` records the SHA-256 of the fetched manager `setup.sh` into
`resolved-refs.env` → `build-info.txt` → `build-info.json`.

### 3.9 Reproducible timestamps

`SOURCE_DATE_EPOCH` is derived from the kernel source commit date
(`git -C kernel-source log -1 --format=%ct`); `KBUILD_BUILD_TIMESTAMP` follows. Identical
inputs then produce a byte-identical `Image`.

Trade-off, documented in README and ARCHITECTURE: `uname -a` shows the source commit date,
not the CI run date. The real build time remains in the summary, the AnyKernel banner, and
`build-info`.

### 3.10 Extract the build-info writer

The forty-line inline heredoc in `build-core.yml` moves to
`scripts/write-build-info-txt.sh`, matching the repo's "scripts over mega-YAML" principle
and making it testable.

### 3.11 Cache hit-rate reporting

`build-kernel.sh` computes hit rate and direct-hit rate from `ccache -s` (the WildKernels
`cache-ccache-stats` calculation) and writes them to `resolved-refs.env`. Summaries show
percentages; the raw `ccache -s` text stays as an artifact and in the per-build summary only.

---

## 4. Simplification

| Target | Change |
|---|---|
| `package-anykernel.sh` | Replace the twelve-variable `_caller_*`/`_preset_*` dance with capture-before-source |
| `generate-build-summary.sh`, `generate-matrix-summary.sh` | Extract the six duplicated sections (config table, SUSFS, install, credits, warning, cache) into `lib/summary-common.sh` emitters |
| `generate-matrix-summary.sh` | Read each `build-info.txt` once into an associative array instead of four to six `grep`s per manager |
| `read-manager-version.sh` | Collapse three near-identical sed-inject branches into one loop |

---

## 5. Documentation

### 5.1 Emoji vocabulary

Exactly six, used consistently and nowhere else:

| Emoji | Meaning |
|---|---|
| 📱 | Device |
| ⚙️ | Build / configuration |
| 🔑 | Manager / root |
| 🛡️ | SUSFS |
| 📦 | Artifacts / packaging |
| ⚠️ | Warning |

`tests/test-emoji-vocabulary.sh` enforces the allowlist across `README.md`, `docs/**.md`,
and the summary generators so drift cannot creep back.

### 5.2 Files

| File | Action |
|---|---|
| `README.md` | Rewrite, 428 → ~230 lines. One preset table instead of three. Pin detail defers to `versions.md`. GitHub alert callouts for warnings. |
| `docs/ARCHITECTURE.md` | Update **in place**, keep the length. §8 pipeline, §11 caching, §17 script catalog rewritten. |
| `docs/versions.md` | Cache and toolchain tables updated. |
| `docs/manager-matrix.md` | Emoji vocabulary. |
| `memory-bank/*.md` | Refresh — currently records `main @ 2ce4092`, unaware of pa-gr and PR #8. |
| Summary generators | Six-emoji vocabulary; hit-rate percentages; drop duplicated raw `ccache -s` dumps from the matrix summary. |

---

## 6. Tests

| Test | Covers |
|---|---|
| `test-cache-policy.sh` (new) | v5 key shape, no commit SHAs in the primary key, restore-key ordering and count, `cache_writer` gating, ThinLTO policy string, ccache size cap, rejected settings absent |
| `test-emoji-vocabulary.sh` (new) | Only the six approved emoji appear in docs and summary output |
| `test-matrix-generator.sh` | Exactly one `cache_writer=true` per matrix |
| `test-build-info-json.sh` | New fields: timestamps, setup digest, zip size, hit rates |
| `test-summary-format.sh`, `test-matrix-summary.sh` | Section presence with the new emitters |
| `test-workflow-policy.sh` | apt list free of `clang`/`llvm`/`lld`; preflight unfiltered on push; aggregate downloads `marble-meta-*`; toolchain completeness check present |

Gate: `bash -n`, `shellcheck`, `actionlint`, and the full `tests/test-*.sh` suite must pass.

---

## 7. Out of scope

- Any change to a kernel source repository.
- GitHub Releases as a cache store. Considered and rejected: it needs a PAT secret and
  roughly 300 lines of custom action code, and WildKernels themselves have that path
  disabled behind `if: false` in favour of native Actions cache.
- `CCACHE_DEPEND`, `CCACHE_FILE_CLONE`, `CCACHE_BASEDIR` — see §2.4.
- Re-boot-testing LOS + manager + SUSFS on device. Still an open gap from `progress.md`.

---

## 8. Verification and honest limits

The speedup cannot be quantified before a CI run. Today's warm runs are effectively cold —
the primary key misses every time — so there is no honest baseline to measure against. The
hit-rate reporting added in §3.11 makes the next run the first measurable one.

Claims that hold without a CI run: the key no longer contains a value that changes every
run; the ThinLTO cache is bounded where it previously was not; five parallel jobs no longer
race for one immutable key; susfs4ksu is cloned once instead of twice; the preset resolver
runs once instead of twice.
