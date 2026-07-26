#!/usr/bin/env bash
# Generate Actions cache keys for ccache and the ThinLTO object cache.
#
# One bucket per (toolchain, LTO mode, kernel source), rotated weekly:
#
#   bucket  = marble-<kind>-v5-<os>-<arch>-<toolchain>-lto<mode>-<kernel_source>
#   key     = <bucket>-<code_hash>-w<isoweek>
#   restore = <bucket>-<code_hash>-   (any week, identical build semantics)
#             <bucket>-               (any code_hash, same build target)
#
# Commit SHAs are deliberately absent. The previous v4 key embedded
# source/manager/susfs commits, so the primary key missed on every run and each
# run uploaded a fresh multi-GiB entry into a 10 GB repository-wide budget.
# Managers share one bucket because their object sets differ by a rounding
# error against the kernel tree. See docs/ARCHITECTURE.md section 11.
set -euo pipefail

CACHE_KEY_VERSION="v5"
CACHE_KEYS_FILE="${CACHE_KEYS_FILE:-release/cache-keys.env}"

toolchain="${ACTIVE_TOOLCHAIN_ID:-${TOOLCHAIN:-android-r416183b}}"
lto_mode="${LTO:-thin}"
kernel_source="${KERNEL_SOURCE:-melt}"
runner_os="${RUNNER_OS:-Linux}"
runner_arch="${RUNNER_ARCH:-X64}"
# CACHE_WEEK exists so tests can pin the rotation window.
cache_week="${CACHE_WEEK:-$(date -u +%GW%V)}"

for required in scripts/build-kernel.sh config/marble.env; do
  if [[ ! -f "${required}" ]]; then
    echo "::error::generate-cache-keys.sh must run from the builder root (missing ${required})"
    exit 1
  fi
done

# Only files that change compilation semantics belong in this hash. Adding a
# kernel preset or a manager entry must not invalidate every cache in the repo.
code_hash="$(sha256sum scripts/build-kernel.sh config/marble.env | sha256sum | cut -c1-8)"

emit_bucket() {
  local kind="$1"
  local bucket="marble-${kind}-${CACHE_KEY_VERSION}-${runner_os}-${runner_arch}-${toolchain}-lto${lto_mode}-${kernel_source}"
  printf '%s_key=%s-%s-w%s\n' "${kind}" "${bucket}" "${code_hash}" "${cache_week}"
  printf '%s_restore_1=%s-%s-\n' "${kind}" "${bucket}" "${code_hash}"
  printf '%s_restore_2=%s-\n' "${kind}" "${bucket}"
}

mkdir -p "$(dirname "${CACHE_KEYS_FILE}")"
{
  emit_bucket ccache
  emit_bucket thinlto
  printf 'code_hash=%s\n' "${code_hash}"
  printf 'cache_week=%s\n' "${cache_week}"
} > "${CACHE_KEYS_FILE}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  cat "${CACHE_KEYS_FILE}" >> "${GITHUB_OUTPUT}"
fi

echo "Cache keys ${CACHE_KEY_VERSION} (week ${cache_week}, code ${code_hash}):"
sed 's/^/  /' "${CACHE_KEYS_FILE}"
