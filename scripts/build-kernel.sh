#!/usr/bin/env bash
set -euo pipefail

source config/marble.env

KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
BUILD_SCOPE="${BUILD_SCOPE:-image-only}"
MANAGER="${MANAGER:-none}"
ENABLE_SUSFS="${ENABLE_SUSFS:-false}"
JOBS="${JOBS:-$(nproc)}"
USE_CCACHE="${USE_CCACHE:-true}"
TOOLCHAIN="${TOOLCHAIN:-android-r416183b}"
builder_root="$(pwd)"
RESOLVED_REFS_FILE="${RESOLVED_REFS_FILE:-release/resolved-refs.env}"

# Percentages from `ccache -s`, so summaries can report cache effectiveness
# without re-parsing the raw stats blob. Never fails the build.
write_ccache_hit_rates() {
  local stats="$1" out="$2" cacheable hits direct
  [[ -f "${stats}" ]] || return 0
  cacheable="$(awk '/Cacheable calls:/ { match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH); exit }' "${stats}")"
  hits="$(awk '/^[[:space:]]+Hits:/ { match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH); exit }' "${stats}")"
  direct="$(awk '/Direct:/ { match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH); exit }' "${stats}")"
  if [[ "${cacheable:-0}" =~ ^[0-9]+$ ]] && (( cacheable > 0 )); then
    {
      awk -v h="${hits:-0}" -v c="${cacheable}" 'BEGIN{printf "ccache_hit_rate=%.1f%%\n", (h/c)*100}'
      awk -v d="${direct:-0}" -v c="${cacheable}" 'BEGIN{printf "ccache_direct_rate=%.1f%%\n", (d/c)*100}'
    } >> "${out}"
  fi
}

# Free GitHub-hosted runners (~7 GiB) often OOM (exit 137) while linking vmlinux
# with LLVM 22 at full -j$(nproc). Cap parallelism for the heavy toolchain.
# Free defaults: LLVM JOBS<=2, THINLTO_JOBS=2 (see ThinLTO wrapper below).
# Self-hosted override examples:
#   JOBS_FORCE=1 JOBS=8 THINLTO_JOBS=4
if [[ -z "${JOBS_FORCE:-}" ]]; then
  if [[ "${TOOLCHAIN}" == "llvm-22.1.8" ]] && (( JOBS > 2 )); then
    echo "Capping JOBS from ${JOBS} to 2 for ${TOOLCHAIN} (OOM-safe on free runners)"
    JOBS=2
  fi
fi

pushd "${KERNEL_DIR}" >/dev/null
mkdir -p "${OUT_DIR}" "${RELEASE_DIR}"

export ARCH
export SUBARCH="${ARCH}"
export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-marble}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-github-actions}"

# Reproducible builds: identical inputs must produce a byte-identical Image, so
# the embedded timestamp comes from the kernel source commit rather than the
# wall clock. `uname -a` therefore shows the source date; the real CI build time
# stays in build-info, the summary, and the AnyKernel banner.
if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  SOURCE_DATE_EPOCH="$(git log -1 --format=%ct 2>/dev/null || true)"
fi
if [[ ! "${SOURCE_DATE_EPOCH}" =~ ^[0-9]+$ ]]; then
  echo "::warning::Could not read the source commit date; falling back to the current time (build will not be reproducible)"
  SOURCE_DATE_EPOCH="$(date -u +%s)"
fi
export SOURCE_DATE_EPOCH
export KBUILD_BUILD_TIMESTAMP="${KBUILD_BUILD_TIMESTAMP:-$(date -u -d "@${SOURCE_DATE_EPOCH}" '+%a %b %d %H:%M:%S UTC %Y')}"
echo "Build timestamp pinned to ${KBUILD_BUILD_TIMESTAMP} (epoch ${SOURCE_DATE_EPOCH})"
# Only the epoch goes into resolved-refs.env: package-anykernel.sh `source`s that
# file, and the formatted timestamp contains spaces. write-build-info-txt.sh
# formats it for the human-readable record.
echo "source_date_epoch=${SOURCE_DATE_EPOCH}" >> "${builder_root}/${RESOLVED_REFS_FILE}"

export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.ccache}"
export CCACHE_COMPILERCHECK=content
export CCACHE_NOHASHDIR=true

if [[ -n "${ANDROID_CLANG_BIN:-}" ]]; then
  if [[ ! -x "${ANDROID_CLANG_BIN}/clang" ]]; then
    echo "::error::ANDROID_CLANG_BIN does not contain clang: ${ANDROID_CLANG_BIN}"
    exit 1
  fi
  export PATH="${ANDROID_CLANG_BIN}:${PATH}"
fi

if [[ "${USE_CCACHE}" == "true" ]] && command -v ccache >/dev/null 2>&1; then
  export CC="ccache clang"
  # 2 GiB per bucket. GitHub allows 10 GB of Actions cache per repository, shared
  # with both toolchain caches and the ThinLTO cache, so a larger ccache would
  # evict everything else instead of surviving between runs.
  ccache -M "${MARBLE_CCACHE_SIZE:-2G}"
  ccache -o compression=true
  # ccache manual: high compression levels "may slow down compilations
  # noticeably". Level 1 is the upstream default.
  ccache -o compression_level="${MARBLE_CCACHE_COMPRESS_LEVEL:-1}" 2>/dev/null || true
  # The kernel tree is re-cloned every run, so every include file has a fresh
  # mtime. ccache disables direct mode when an include mtime is "too new", which
  # would cost us direct hits on every single build.
  ccache -o sloppiness="${MARBLE_CCACHE_SLOPPINESS:-include_file_mtime,include_file_ctime,time_macros,locale,system_headers}"
  ccache -o inode_cache=true 2>/dev/null || true
  ccache -z || true
else
  export CC="clang"
fi

clang --version | tee "${RELEASE_DIR}/build.log"

DEFCONFIG_MODE="${DEFCONFIG_MODE:-single}"
case "${DEFCONFIG_MODE}" in
  single)
    active_defconfig="${DEFCONFIG:-marble_defconfig}"
    echo "Using single defconfig: ${active_defconfig}" | tee -a "${RELEASE_DIR}/build.log"
    make O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 CC="${CC}" "${active_defconfig}" 2>&1 | tee -a "${RELEASE_DIR}/build.log"
    ;;
  gki_fragments)
    base_defconfig="${BASE_DEFCONFIG:-gki_defconfig}"
    echo "Using GKI base defconfig: ${base_defconfig}" | tee -a "${RELEASE_DIR}/build.log"
    make O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 CC="${CC}" "${base_defconfig}" 2>&1 | tee -a "${RELEASE_DIR}/build.log"

    if [[ -z "${CONFIG_FRAGMENTS:-}" ]]; then
      echo "::error::DEFCONFIG_MODE=gki_fragments requires CONFIG_FRAGMENTS"
      exit 1
    fi

    fragment_paths=()
    # shellcheck disable=SC2206
    fragment_list=(${CONFIG_FRAGMENTS})
    for fragment in "${fragment_list[@]}"; do
      fragment_path="arch/${ARCH}/configs/${fragment}"
      if [[ ! -f "${fragment_path}" ]]; then
        echo "::error::Missing config fragment: ${fragment_path}"
        exit 1
      fi
      fragment_paths+=("${fragment_path}")
      echo "  + fragment ${fragment_path}" | tee -a "${RELEASE_DIR}/build.log"
    done

    if [[ ! -x scripts/kconfig/merge_config.sh ]]; then
      echo "::error::scripts/kconfig/merge_config.sh is missing or not executable"
      exit 1
    fi
    ./scripts/kconfig/merge_config.sh -O "${OUT_DIR}" -m "${OUT_DIR}/.config" "${fragment_paths[@]}" 2>&1 | tee -a "${RELEASE_DIR}/build.log"
    ;;
  *)
    echo "::error::Unsupported DEFCONFIG_MODE: ${DEFCONFIG_MODE}"
    exit 1
    ;;
esac

if [[ "${MANAGER}" != "none" ]]; then
  scripts/config --file "${OUT_DIR}/.config" -e KSU
fi
if [[ "${ENABLE_SUSFS}" == "true" ]]; then
  scripts/config --file "${OUT_DIR}/.config" -e KSU_SUSFS
fi

# Apply selectable Clang LTO for all presets (including gki_fragments / Melt).
# Default thin is free-runner safe with swap + thinlto job caps; full needs more RAM.
LTO="${LTO:-thin}"
echo "Applying LTO mode: ${LTO}" | tee -a "${RELEASE_DIR}/build.log"
case "${LTO}" in
  none)
    scripts/config --file "${OUT_DIR}/.config" \
      -d LTO_CLANG -d LTO_CLANG_THIN -d LTO_CLANG_FULL -e LTO_NONE || true
    # Also clear common Android synonyms if present
    scripts/config --file "${OUT_DIR}/.config" -e LTO_CLANG_NONE 2>/dev/null || true
    ;;
  thin)
    scripts/config --file "${OUT_DIR}/.config" \
      -d LTO_NONE -d LTO_CLANG_NONE -d LTO_CLANG_FULL -e LTO_CLANG -e LTO_CLANG_THIN || true
    ;;
  full)
    scripts/config --file "${OUT_DIR}/.config" \
      -d LTO_NONE -d LTO_CLANG_NONE -d LTO_CLANG_THIN -e LTO_CLANG -e LTO_CLANG_FULL || true
    echo "::warning::LTO=full is memory-heavy on free GitHub runners; prefer thin unless on high-RAM hosts"
    ;;
  *)
    echo "::error::Unsupported LTO=${LTO}"
    exit 1
    ;;
esac

make O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 CC="${CC}" olddefconfig 2>&1 | tee -a "${RELEASE_DIR}/build.log"

if [[ "${MANAGER}" != "none" ]] && ! grep -q '^CONFIG_KSU=y$' "${OUT_DIR}/.config"; then
  echo "::error::CONFIG_KSU is not enabled in the final kernel config"
  exit 1
fi
if [[ "${ENABLE_SUSFS}" == "true" ]] && ! grep -q '^CONFIG_KSU_SUSFS=y$' "${OUT_DIR}/.config"; then
  echo "::error::CONFIG_KSU_SUSFS is not enabled in the final kernel config"
  exit 1
fi

targets=(Image)
if [[ "${BUILD_SCOPE}" == "full" ]]; then
  targets+=(modules dtbs)
fi

if [[ "${LTO}" == "thin" ]]; then
  # Cap ThinLTO parallel codegen on free runners (~7 GiB) to avoid OOM during link.
  THINLTO_JOBS="${THINLTO_JOBS:-2}"
  # Durable ThinLTO cache, restored and saved by the workflow.
  THINLTO_CACHE_DIR="${THINLTO_CACHE_DIR:-${HOME}/.cache/thinlto}"
  # LLVM's default pruning policy is cache_size=75% of free disk, which on a
  # hosted runner means tens of GiB — far past the 10 GB Actions cache budget
  # for the whole repository. Bound it explicitly.
  THINLTO_CACHE_POLICY="${THINLTO_CACHE_POLICY:-cache_size_bytes=${THINLTO_CACHE_MAX:-1g}:prune_after=${THINLTO_CACHE_PRUNE_AFTER:-168h}}"
  mkdir -p "${THINLTO_CACHE_DIR}"
  wrapper="$(pwd)/${RELEASE_DIR}/ld-thinlto-wrapper"
  {
    printf '#!/bin/bash\n'
    printf 'exec ld.lld "$@" --thinlto-jobs=%s --thinlto-cache-dir=%q --thinlto-cache-policy=%q\n' \
      "${THINLTO_JOBS}" "${THINLTO_CACHE_DIR}" "${THINLTO_CACHE_POLICY}"
  } > "${wrapper}"
  chmod +x "${wrapper}"
  export LD="${wrapper}"
  export HOSTLD="${wrapper}"
  export THINLTO_CACHE_DIR
  echo "ThinLTO jobs=${THINLTO_JOBS} cache=${THINLTO_CACHE_DIR} policy=${THINLTO_CACHE_POLICY}" | tee -a "${RELEASE_DIR}/build.log"
fi

make -j"${JOBS}" O="${OUT_DIR}" ARCH="${ARCH}" LLVM=1 LLVM_IAS=1 CC="${CC}" "${targets[@]}" 2>&1 | tee -a "${RELEASE_DIR}/build.log"

image_path="${OUT_DIR}/arch/arm64/boot/Image"
if [[ ! -s "${image_path}" ]]; then
  echo "::error::Built Image not found at ${image_path}"
  exit 1
fi

image_size="$(stat -c%s "${image_path}")"
if [[ "${image_size}" -lt 5000000 ]]; then
  echo "::error::Built Image is unexpectedly small: ${image_size} bytes"
  exit 1
fi

if command -v file >/dev/null 2>&1; then
  file "${image_path}" | tee -a "${RELEASE_DIR}/build.log"
fi

cp "${image_path}" "${RELEASE_DIR}/Image"
for file in System.map vmlinux; do
  if [[ -s "${OUT_DIR}/${file}" ]]; then
    cp "${OUT_DIR}/${file}" "${RELEASE_DIR}/${file}"
  fi
done

if [[ "${BUILD_SCOPE}" == "full" ]]; then
  if find "${OUT_DIR}/arch/arm64/boot/dts" -name '*.dtb' -print -quit | grep -q .; then
    find "${OUT_DIR}/arch/arm64/boot/dts" -name '*.dtb' -print0 | tar --null -T - -czf "${RELEASE_DIR}/dtbs.tar.gz"
  fi
  if find "${OUT_DIR}" -name '*.ko' -print -quit | grep -q .; then
    find "${OUT_DIR}" -name '*.ko' -print0 | tar --null -T - -czf "${RELEASE_DIR}/modules.tar.gz"
  fi
fi

if [[ "${USE_CCACHE}" == "true" ]] && command -v ccache >/dev/null 2>&1; then
  ccache -s | tee "${RELEASE_DIR}/ccache-stats.txt" || true
  write_ccache_hit_rates "${RELEASE_DIR}/ccache-stats.txt" "${builder_root}/${RESOLVED_REFS_FILE}"
fi

popd >/dev/null
