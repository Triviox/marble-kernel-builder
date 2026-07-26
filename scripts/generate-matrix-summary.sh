#!/usr/bin/env bash
set -euo pipefail

source config/marble.env
source scripts/lib/summary-common.sh

MATRIX_ARTIFACTS_DIR="${MATRIX_ARTIFACTS_DIR:-matrix-artifacts}"
MATRIX_SUMMARY="${MATRIX_SUMMARY:-matrix-summary.md}"
BUILD_SCOPE="${BUILD_SCOPE:-image-only}"

if [[ ! -d "${MATRIX_ARTIFACTS_DIR}" ]]; then
  echo "::error::Matrix artifacts directory not found: ${MATRIX_ARTIFACTS_DIR}"
  exit 1
fi

# Accepts both marble-meta-* (aggregate job: metadata only) and marble-flash-*
# (release job: metadata plus the ZIP), or a single flat directory.
artifact_dirs=()
if [[ -f "${MATRIX_ARTIFACTS_DIR}/build-info.txt" && -f "${MATRIX_ARTIFACTS_DIR}/zip-name.env" ]]; then
  artifact_dirs+=("${MATRIX_ARTIFACTS_DIR}")
fi
while IFS= read -r candidate; do
  [[ -f "${candidate}/build-info.txt" && -f "${candidate}/zip-name.env" ]] || continue
  artifact_dirs+=("${candidate}")
done < <(find "${MATRIX_ARTIFACTS_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ "${#artifact_dirs[@]}" -eq 0 ]]; then
  echo "::error::No matrix flash artifact metadata found in ${MATRIX_ARTIFACTS_DIR}"
  exit 1
fi

# Read every build-info.txt and zip-name.env exactly once.
declare -a MANAGERS=()
declare -A INFO_BLOB=()
declare -A ZIP_BLOB=()
for artifact_dir in "${artifact_dirs[@]}"; do
  MANAGERS+=("${artifact_dir}")
  INFO_BLOB["${artifact_dir}"]="$(cat "${artifact_dir}/build-info.txt")"
  ZIP_BLOB["${artifact_dir}"]="$(cat "${artifact_dir}/zip-name.env")"
done

# Populate `info` and `zipinfo` for one artifact directory.
declare -A info=() zipinfo=()
load_artifact() {
  local dir="$1" key value
  info=(); zipinfo=()
  while IFS='=' read -r key value; do
    [[ -n "${key}" && "${key}" != \#* ]] || continue
    info["${key}"]="${value%$'\r'}"
  done <<< "${INFO_BLOB[${dir}]}"
  while IFS='=' read -r key value; do
    [[ -n "${key}" && "${key}" != \#* ]] || continue
    zipinfo["${key}"]="${value%$'\r'}"
  done <<< "${ZIP_BLOB[${dir}]}"
}

manager_version_only() {
  local version="${info[manager_build_version_name]:-${info[manager_build_tag]:-${info[manager_tag]:-}}}"
  if [[ -z "${version}" && -n "${info[manager_commit]:-}" ]]; then
    version="$(short_commit "${info[manager_commit]}")"
  fi
  echo "${version:-unknown}"
}

manager_code_only() {
  echo "${info[manager_build_version_code]:-${info[manager_version_code]:-—}}"
}

manager_version_label() {
  local version code
  version="$(manager_version_only)"
  code="${info[manager_build_version_code]:-${info[manager_version_code]:-}}"
  if [[ -n "${code}" ]]; then
    echo "${version} · code ${code}"
  else
    echo "${version}"
  fi
}

# Run-wide values come from the first artifact; they are identical across the matrix.
load_artifact "${MANAGERS[0]}"
declare -A first_info=()
for key in "${!info[@]}"; do first_info["${key}"]="${info[${key}]}"; done

source_repo="${first_info[source_repo]:-}"
workflow_run="${first_info[workflow_run]:-}"
susfs_display="${first_info[susfs_reported_version]:-${first_info[susfs_version]:-}}"
susfs_enabled="${first_info[enable_susfs]:-false}"
lto_mode="${first_info[lto]:-thin}"
build_date="${first_info[build_started_utc]:-$(date -u '+%Y-%m-%d %H:%M:%S UTC')}"
run_number="${SOURCE_RUN_NUMBER:-${GITHUB_RUN_NUMBER:-unknown}}"
manager_count="${#MANAGERS[@]}"

builder_repo="${GITHUB_REPOSITORY:-mohdakil2426/marble-kernel-builder}"
banner_url="https://raw.githubusercontent.com/${builder_repo}/${GITHUB_SHA:-main}/docs/assets/marble-banner.svg"

matrix_badge_url="https://img.shields.io/badge/Matrix-${manager_count}_managers_passed-4CAF50?logo=githubactions&logoColor=white"
if [[ "${susfs_enabled}" == "true" && -n "${susfs_display}" ]]; then
  susfs_badge_url="https://img.shields.io/badge/SUSFS-$(badge_encode "${susfs_display}")-FF6D00?logo=gitlab&logoColor=white"
else
  susfs_badge_url="https://img.shields.io/badge/SUSFS-Disabled-757575?logo=gitlab&logoColor=white"
fi
device_badge_url="https://img.shields.io/badge/Device-Poco_F5_%2F_RN12_Turbo-EF5350"
scope_badge_url="https://img.shields.io/badge/Scope-$(badge_encode "${BUILD_SCOPE}")-2088FF"
lto_badge_url="https://img.shields.io/badge/LTO-$(badge_encode "${lto_mode}")-9C27B0"

{
  echo '<div align="center">'
  echo
  echo "<img src=\"${banner_url}\" alt=\"Marble Kernel\" width=\"720\" />"
  echo
  echo "# Marble Kernel · Matrix Build"
  echo
  echo "**Combined summary for a multi-manager CI run**"
  echo
  echo "\`marble\` · \`marblein\` · \`${BUILD_SCOPE}\`"
  echo
  echo "[![Matrix](${matrix_badge_url})](${workflow_run})"
  echo "[![LTO](${lto_badge_url})](${workflow_run})"
  echo "[![SUSFS](${susfs_badge_url})](${first_info[susfs_url]:-https://gitlab.com/simonpunk/susfs4ksu})"
  echo "[![Device](${device_badge_url})](https://github.com/${source_repo})"
  echo "[![Scope](${scope_badge_url})](${workflow_run})"
  echo
  echo "**${build_date}** &nbsp;·&nbsp; **Run #${run_number}** &nbsp;·&nbsp; [View workflow](${workflow_run})"
  echo
  echo '</div>'
  echo
  echo "---"
  echo

  echo "## ${EMOJI_WARNING} Before you flash"
  echo
  summary_emit_flash_warning
  echo
  echo "---"
  echo

  echo "## ${EMOJI_BUILD} Matrix configuration"
  echo
  echo "| | |"
  echo "|:---|:---|"
  summary_emit_config_rows first_info "${BUILD_SCOPE}"
  if [[ "${susfs_enabled}" == "true" && -n "${susfs_display}" ]]; then
    echo "| ${EMOJI_SUSFS} **SUSFS** | \`${susfs_display}\` · \`${first_info[susfs_kernel_branch]:-}\` · [\`$(short_commit "${first_info[susfs_commit]:-}")\`](${first_info[susfs_url]:-}) |"
  else
    echo "| ${EMOJI_SUSFS} **SUSFS** | Disabled |"
  fi
  echo "| **Result** | **${manager_count} / ${manager_count}** manager builds passed |"
  echo
  echo "---"
  echo

  # Cache: one table for the whole matrix. The raw `ccache -s` text stays in the
  # per-build summary and the ccache-stats.txt artifact rather than being
  # duplicated N times here.
  echo "${SUMMARY_CACHE_START}"
  echo "## Cache"
  echo
  echo "> CI diagnostics only — this section is **not** included in GitHub Release notes."
  echo
  echo "| Manager | Actions ccache hit | Actions ThinLTO hit | ccache hit rate | Direct rate | Cache writer |"
  echo "|:---|:---:|:---:|:---:|:---:|:---:|"
  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    echo "| **$(manager_display "${info[manager]:-}")** | \`${info[ccache_hit]:-unknown}\` | \`${info[thinlto_cache_hit]:-n/a}\` | \`${info[ccache_hit_rate]:-n/a}\` | \`${info[ccache_direct_rate]:-n/a}\` | \`${info[cache_writer]:-false}\` |"
  done
  echo
  echo "Raw \`ccache -s\` output is attached to each build as \`ccache-stats.txt\`."
  echo
  echo "${SUMMARY_CACHE_END}"
  echo "---"
  echo

  echo "## ${EMOJI_MANAGER} Managers"
  echo
  echo "| Manager | Version | Code | SUSFS | Status |"
  echo "|:---|:---|:---:|:---:|:---:|"
  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    if [[ "${info[enable_susfs]:-false}" == "true" ]]; then susfs_cell="yes"; else susfs_cell="—"; fi
    echo "| **$(manager_display "${info[manager]:-}")** | \`$(manager_version_only)\` | \`$(manager_code_only)\` | ${susfs_cell} | Passed |"
  done
  echo

  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    manager_name="${info[manager]:-}"
    label="$(manager_display "${manager_name}")"
    manager_repo="${info[manager_repo]:-}"
    app_url="$(manager_app_url "${manager_name}")"

    echo "<details>"
    echo "<summary><b>${label}</b> — $(manager_version_label) · Passed</summary>"
    echo
    echo "| | |"
    echo "|:---|:---|"
    [[ -n "${manager_repo}" ]] && \
      echo "| **Repository** | [\`${manager_repo} @ ${info[manager_ref]:-}\`](https://github.com/${manager_repo}) |"
    [[ -n "${info[manager_build_version_name]:-}" ]] && \
      echo "| **Version name** | \`${info[manager_build_version_name]}\` |"
    _tag="${info[manager_build_tag]:-${info[manager_tag]:-}}"
    [[ -n "${_tag}" ]] && echo "| **Version** | \`${_tag}\` |"
    _code="${info[manager_build_version_code]:-${info[manager_version_code]:-}}"
    [[ -n "${_code}" ]] && echo "| **Version code** | \`${_code}\` |"
    [[ -n "${manager_repo}" && -n "${info[manager_commit]:-}" ]] && \
      echo "| **Commit** | [\`$(short_commit "${info[manager_commit]}")\`](https://github.com/${manager_repo}/commit/${info[manager_commit]}) |"
    [[ -n "${info[manager_setup_sha256]:-}" ]] && \
      echo "| **setup.sh sha256** | \`${info[manager_setup_sha256]}\` |"
    [[ -n "${info[manager_signature_size]:-}" ]] && \
      echo "| **Signature size** | \`${info[manager_signature_size]}\` |"
    [[ -n "${info[manager_signature_hash]:-}" ]] && \
      echo "| **Signature hash** | \`${info[manager_signature_hash]}\` |"
    [[ -n "${info[manager_supported_line]:-}" ]] && \
      echo "| **Supported managers** | ${info[manager_supported_line]//,/, } |"
    if [[ "${manager_name}" == "kernelsu-next" && "${info[enable_susfs]:-false}" == "true" ]]; then
      echo "| **Note** | Non-SUSFS builds use official \`KernelSU-Next/KernelSU-Next@dev\`; SUSFS builds use \`pershoot/dev-susfs\` |"
    fi
    [[ -n "${app_url}" ]] && echo "| **App** | [Manager releases](${app_url}) |"
    echo
    echo "</details>"
    echo
  done
  echo "---"
  echo

  echo "## ${EMOJI_SUSFS} SUSFS"
  echo
  if [[ "${susfs_enabled}" == "true" ]]; then
    echo "| | |"
    echo "|:---|:---|"
    summary_emit_susfs_rows first_info
    echo "| **Userspace module** | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases) |"
    echo
    summary_susfs_module_note
  else
    echo "SUSFS is not enabled for this matrix."
  fi
  echo
  echo "---"
  echo

  echo "## ${EMOJI_ARTIFACT} Artifacts & checksums"
  echo
  echo "| Manager | File | Size | SHA-256 |"
  echo "|:---|:---|:---:|:---|"
  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    zip_name="${zipinfo[zip_name]:-unknown.zip}"
    # Size and hash come from metadata, so this works for metadata-only
    # artifacts and avoids re-hashing hundreds of MB in the release job.
    zip_bytes="${zipinfo[zip_size_bytes]:-}"
    sha_cell="${zipinfo[zip_sha256]:-}"
    zip_path="${artifact_dir}/${zip_name}"
    if [[ -f "${zip_path}" ]]; then
      [[ -n "${zip_bytes}" ]] || zip_bytes="$(stat -c%s "${zip_path}")"
      [[ -n "${sha_cell}" ]] || sha_cell="$(sha256sum "${zip_path}" | awk '{print $1}')"
    fi
    size_cell="$(summary_human_size "${zip_bytes}")"
    sha_cell="${sha_cell:-unknown}"
    echo "| $(manager_display "${info[manager]:-}") | \`${zip_name}\` | ${size_cell} | \`${sha_cell}\` |"
  done
  echo
  echo "---"
  echo

  echo "## Installation"
  echo
  echo "<details>"
  echo "<summary><b>Prerequisites</b></summary>"
  echo "<br/>"
  echo
  echo "- Unlocked bootloader"
  echo "- Poco F5 (\`marblein\`) or Redmi Note 12 Turbo (\`marble\`) only"
  echo "- A kernel build that matches your **device + ROM**"
  echo "- Original \`boot.img\` from the same ROM and firmware, stored off-device"
  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    app_url="$(manager_app_url "${info[manager]:-}")"
    [[ "${info[manager]:-none}" != "none" && -n "${app_url}" ]] && \
      echo "- [$(manager_display "${info[manager]}") manager app](${app_url}) for the matching ZIP"
  done
  [[ "${susfs_enabled}" == "true" ]] && \
    echo "- [KSU SUSFS module](https://github.com/sidex15/susfs4ksu-module/releases) matching \`${susfs_display}\`"
  echo
  echo "</details>"
  echo
  echo "<details>"
  echo "<summary><b>Flash steps</b> (Kernel Flasher recommended)</summary>"
  echo "<br/>"
  echo
  echo "1. Download the ZIP for **one** manager"
  echo "2. Verify **SHA-256** against the table above"
  echo "3. Flash the ZIP to the active slot with [Kernel Flasher](https://github.com/fatalcoder524/KernelFlasher/releases)"
  echo "4. AnyKernel3 verifies the codename (\`marble\` / \`marblein\`) and backs up boot to \`/sdcard/marble-kernel-backup/\`"
  echo "5. Reboot, then install or open the matching manager app"
  [[ "${susfs_enabled}" == "true" ]] && echo "6. Install the SUSFS userspace module, configure rules, reboot"
  echo
  echo "</details>"
  echo
  summary_emit_bootloop_note
  echo
  echo "---"
  echo

  # Credits are derived from build-info — never hardcode a maintainer name.
  echo "## Credits"
  echo
  echo "| | |"
  echo "|:---|:---|"
  credit_author="${first_info[kernel_source_author]:-${first_info[kernel_source]:-kernel}}"
  if [[ -n "${source_repo}" ]]; then
    echo "| **Kernel source** | [${credit_author}](https://github.com/${source_repo}) (\`${source_repo}\`) |"
  else
    echo "| **Kernel source** | ${credit_author} |"
  fi
  echo "| **AnyKernel3** | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) |"
  seen_managers=""
  for artifact_dir in "${MANAGERS[@]}"; do
    load_artifact "${artifact_dir}"
    manager_name="${info[manager]:-none}"
    [[ "${manager_name}" == "none" ]] && continue
    case " ${seen_managers} " in *" ${manager_name} "*) continue ;; esac
    seen_managers="${seen_managers} ${manager_name}"
    label="$(manager_display "${manager_name}")"
    if [[ -n "${info[manager_repo]:-}" ]]; then
      echo "| **${label}** | [\`${info[manager_repo]}\`](https://github.com/${info[manager_repo]}) |"
    else
      echo "| **${label}** | ${label} |"
    fi
  done
  [[ "${susfs_enabled}" == "true" ]] && \
    echo "| **SUSFS** | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) |"
  echo
  echo "---"
  echo
  echo '<div align="center">'
  echo
  echo "Built with **GitHub Actions** · for Marble"
  echo
  echo "\`marble\` · \`marblein\`"
  echo
  echo '</div>'
} > "${MATRIX_SUMMARY}"

cat "${MATRIX_SUMMARY}"
