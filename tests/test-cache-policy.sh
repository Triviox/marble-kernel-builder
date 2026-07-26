#!/usr/bin/env bash
# Guards the v5 cache design. GitHub allows 10 GB of Actions cache per
# repository (LRU-evicted, 7-day idle expiry), which is roughly one build's
# worth, so every rule here exists to stop the budget being blown.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

core=.github/workflows/build-core.yml
fail() { echo "FAIL: $*" >&2; exit 1; }

# ── Key shape ────────────────────────────────────────────────────────────────

keys_file="$(mktemp)"
trap 'rm -f "${keys_file}"' EXIT

CACHE_KEYS_FILE="${keys_file}" \
KERNEL_SOURCE=lineageos TOOLCHAIN=llvm-22.1.8 LTO=thin \
RUNNER_OS=Linux RUNNER_ARCH=X64 CACHE_WEEK=2026W30 \
  bash scripts/generate-cache-keys.sh >/dev/null

get() { sed -n "s/^$1=//p" "${keys_file}"; }

ccache_key="$(get ccache_key)"
thinlto_key="$(get thinlto_key)"
[[ -n "${ccache_key}" ]] || fail "generate-cache-keys.sh produced no ccache_key"
[[ -n "${thinlto_key}" ]] || fail "generate-cache-keys.sh produced no thinlto_key"

for token in marble-ccache-v5 Linux X64 llvm-22.1.8 ltothin lineageos w2026W30; do
  [[ "${ccache_key}" == *"${token}"* ]] || fail "ccache key missing '${token}': ${ccache_key}"
done
[[ "${thinlto_key}" == marble-thinlto-v5-* ]] || fail "thinlto key is not v5: ${thinlto_key}"

# The v4 key embedded moving commit SHAs, so the primary key missed on every run
# and each run uploaded a fresh multi-GiB entry. Nothing run-varying may return.
for banned in source_commit manager_commit susfs_commit; do
  grep -Fq "${banned}" scripts/generate-cache-keys.sh && \
    fail "cache key must not depend on ${banned} (it changes every run)"
done
[[ "${ccache_key}" =~ [0-9a-f]{40} ]] && fail "cache key contains a 40-char commit SHA: ${ccache_key}"

# Restore chain: most specific first, and no bucket-wide fallback that would
# pull a different kernel source's cache over the network for near-zero hits.
[[ "$(get ccache_restore_1)" == "marble-ccache-v5-Linux-X64-llvm-22.1.8-ltothin-lineageos-$(get code_hash)-" ]] || \
  fail "ccache restore key 1 should drop only the week"
[[ "$(get ccache_restore_2)" == "marble-ccache-v5-Linux-X64-llvm-22.1.8-ltothin-lineageos-" ]] || \
  fail "ccache restore key 2 should drop only the code hash"
[[ "$(get ccache_restore_2)" == *lineageos* ]] || \
  fail "broadest restore key must stay scoped to the kernel source"

# Different targets must not collide.
other="$(mktemp)"
CACHE_KEYS_FILE="${other}" KERNEL_SOURCE=melt TOOLCHAIN=android-r416183b LTO=none \
  RUNNER_OS=Linux RUNNER_ARCH=X64 CACHE_WEEK=2026W30 \
  bash scripts/generate-cache-keys.sh >/dev/null
[[ "$(sed -n 's/^ccache_key=//p' "${other}")" != "${ccache_key}" ]] || \
  fail "different toolchain/LTO/source must produce a different key"
rm -f "${other}"

# The code hash must cover compilation semantics but not the preset catalogue:
# adding a kernel source must not invalidate every cache in the repository.
grep -Fq 'sha256sum scripts/build-kernel.sh config/marble.env' scripts/generate-cache-keys.sh || \
  fail "code hash must cover build-kernel.sh and marble.env"
grep -Fq 'kernel-sources.json' scripts/generate-cache-keys.sh && \
  fail "code hash must not cover kernel-sources.json"

# ── Size caps ────────────────────────────────────────────────────────────────

grep -Fq 'ccache -M "${MARBLE_CCACHE_SIZE:-2G}"' scripts/build-kernel.sh || \
  fail "ccache must be capped at 2G by default"
grep -Eq 'ccache -M .*(4G|6G|12G)' scripts/build-kernel.sh && \
  fail "ccache cap larger than 2G would evict the toolchain caches"

grep -Fq 'thinlto-cache-policy' scripts/build-kernel.sh || \
  fail "ThinLTO cache must be bounded (LLVM defaults to cache_size=75% of free disk)"
grep -Fq 'cache_size_bytes=${THINLTO_CACHE_MAX:-1g}' scripts/build-kernel.sh || \
  fail "ThinLTO cache must default to a 1g byte cap"
grep -Fq 'prune_after=${THINLTO_CACHE_PRUNE_AFTER:-168h}' scripts/build-kernel.sh || \
  fail "ThinLTO cache must set an explicit prune_after"

# ── ccache tuning ────────────────────────────────────────────────────────────

grep -Fq 'CCACHE_COMPILERCHECK=content' scripts/build-kernel.sh || \
  fail "ccache compiler validation must stay content-based"
grep -Fq 'CCACHE_COMPILERCHECK=none' scripts/build-kernel.sh && \
  fail "unsafe ccache compiler checking must stay disabled"
grep -Fq 'compression=true' scripts/build-kernel.sh || \
  fail "ccache compression must stay enabled"
grep -Fq 'compression_level="${MARBLE_CCACHE_COMPRESS_LEVEL:-1}"' scripts/build-kernel.sh || \
  fail "ccache compression_level must default to 1 (high levels slow compilation noticeably)"

# The kernel tree is re-cloned every run, so include mtimes are always fresh and
# ccache would otherwise refuse direct mode on every build.
for slop in include_file_mtime include_file_ctime time_macros; do
  grep -Fq "${slop}" scripts/build-kernel.sh || fail "ccache sloppiness must include ${slop}"
done

# Rejected on purpose — see docs/ARCHITECTURE.md section 11.
grep -Fq 'CCACHE_FILE_CLONE' scripts/build-kernel.sh && \
  fail "file_clone disables compression and inflates the cache past the budget"
grep -Fq 'CCACHE_BASEDIR' scripts/build-kernel.sh && \
  fail "base_dir is documented as brittle and breaks dependency files"

# ── Save policy ──────────────────────────────────────────────────────────────

for step in 'Save ccache' 'Save ThinLTO cache'; do
  block="$(grep -A4 "name: ${step}" "${core}" | head -n2)"
  [[ "${block}" == *'inputs.cache_writer'* ]] || \
    fail "'${step}' must be gated on cache_writer so parallel managers do not race one immutable key"
  [[ "${block}" == *'!cancelled()'* ]] || \
    fail "'${step}' should persist partial work from a failed build"
  [[ "${block}" == *"cache-hit != 'true'"* ]] || \
    fail "'${step}' must skip when the exact key already hit (Actions keys are immutable)"
done

grep -Fq 'cache_writer:' "${core}" || fail "build-core must accept a cache_writer input"
grep -A10 '^      cache_writer:' "${core}" | grep -Fq 'default: true' || \
  fail "cache_writer must default to true for direct callers such as the weekly smoke"

# ── Matrix election ──────────────────────────────────────────────────────────

matrix_json="$(BUILD_NONE=true BUILD_KERNELSU_NEXT=true BUILD_RESUKISU=true \
  GITHUB_OUTPUT=/dev/null bash scripts/generate-build-matrix.sh)"
writers="$(grep -o '"cache_writer":"true"' <<<"${matrix_json}" | wc -l | tr -d ' ')"
[[ "${writers}" == "1" ]] || fail "matrix must elect exactly one cache writer, got ${writers}"
entries="$(grep -o '"manager":' <<<"${matrix_json}" | wc -l | tr -d ' ')"
[[ "${entries}" == "3" ]] || fail "expected 3 matrix entries, got ${entries}"

single="$(BUILD_SUKISU_ULTRA=true GITHUB_OUTPUT=/dev/null bash scripts/generate-build-matrix.sh)"
[[ "$(grep -o '"cache_writer":"true"' <<<"${single}" | wc -l | tr -d ' ')" == "1" ]] || \
  fail "a single-manager matrix must still elect one cache writer"

echo "Cache policy tests passed"
