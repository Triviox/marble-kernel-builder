#!/usr/bin/env bash
# Resolve TOOLCHAIN=auto to the kernel preset's recommended_toolchain.
#
# build-core.yml runs resolve-kernel-source.sh in the previous step, so this
# reuses release/kernel-source.env and only re-resolves when that file is
# missing or describes a different preset than the caller asked for. Resolving
# twice used to duplicate every line this appends to GITHUB_ENV.
set -euo pipefail

env_file="release/kernel-source.env"
cached_source=""
if [[ -f "${env_file}" ]]; then
  # shellcheck disable=SC1090
  cached_source="$(source "${env_file}" >/dev/null 2>&1; printf '%s' "${KERNEL_SOURCE:-}")"
fi

if [[ -z "${cached_source}" ]] || { [[ -n "${KERNEL_SOURCE:-}" ]] && [[ "${cached_source}" != "${KERNEL_SOURCE}" ]]; }; then
  KERNEL_SOURCE="${KERNEL_SOURCE:-melt}" SOURCE_REF="${SOURCE_REF:-}" \
    bash scripts/resolve-kernel-source.sh >/dev/null
fi

# shellcheck disable=SC1090
source "${env_file}"

TOOLCHAIN="${TOOLCHAIN:-auto}"
if [[ "${TOOLCHAIN}" == "auto" || -z "${TOOLCHAIN}" ]]; then
  TOOLCHAIN="${RECOMMENDED_TOOLCHAIN:-android-r416183b}"
fi

case "${TOOLCHAIN}" in
  android-r416183b|llvm-22.1.8) ;;
  *)
    echo "::error::Unsupported TOOLCHAIN=${TOOLCHAIN}" >&2
    exit 1
    ;;
esac

echo "TOOLCHAIN=${TOOLCHAIN}"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "TOOLCHAIN=${TOOLCHAIN}" >> "${GITHUB_ENV}"
fi
