#!/usr/bin/env bash
set -euo pipefail

source config/marble.env
source scripts/lib/summary-common.sh

KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
MANAGER="${MANAGER:-none}"
ENABLE_SUSFS="${ENABLE_SUSFS:-false}"
BUILD_SCOPE="${BUILD_SCOPE:-image-only}"

release_dir="${KERNEL_DIR}/${RELEASE_DIR}"
build_info="${release_dir}/build-info.txt"
zip_env="${release_dir}/zip-name.env"
summary="${release_dir}/summary.md"

if [[ ! -f "${build_info}" || ! -f "${zip_env}" ]]; then
  echo "::error::Missing build metadata for summary generation"
  exit 1
fi

source "${zip_env}"

declare -A info
summary_load_info info "${build_info}"

manager_name="${info[manager]:-}"
manager_repo="${info[manager_repo]:-}"
manager_commit="${info[manager_commit]:-}"
source_repo="${info[source_repo]:-}"
workflow_run="${info[workflow_run]:-}"
rom_support="${info[rom_support]:-Official Xiaomi stock ${SUPPORTED_ROM_LABEL} only}"
susfs_display="${info[susfs_reported_version]:-${info[susfs_version]:-}}"

manager_label="$(manager_display "${manager_name}")"
manager_app_link="$(manager_app_url "${manager_name}")"

zip_sha="$(sha256sum "${release_dir}/${zip_name}" | awk '{print $1}')"
image_sha="$(sha256sum "${release_dir}/Image" | awk '{print $1}')"
zip_size="$(du -h "${release_dir}/${zip_name}" | awk '{print $1}')"
build_date="${info[build_started_utc]:-$(date -u '+%Y-%m-%d %H:%M:%S UTC')}"
run_number="${GITHUB_RUN_NUMBER:-${workflow_run##*/}}"

# ── Badges ───────────────────────────────────────────────────────────────────
if [[ "${manager_name}" == "none" ]]; then
  manager_badge_url="https://img.shields.io/badge/Manager-No_Root-757575?style=for-the-badge&logo=linux&logoColor=white"
  manager_badge_link="https://github.com/${source_repo}"
else
  _version_str="${info[manager_build_version_name]:-${info[manager_build_tag]:-${info[manager_tag]:-unknown}}}"
  _version_code="${info[manager_build_version_code]:-${info[manager_version_code]:-}}"
  [[ -n "${_version_code}" ]] && _version_str="${_version_str} #${_version_code}"
  manager_badge_url="https://img.shields.io/badge/$(badge_encode "${manager_label}")-$(badge_encode "${_version_str}")-4CAF50?style=for-the-badge&logo=linux&logoColor=white"
  manager_badge_link="https://github.com/${manager_repo}"
fi

if [[ "${ENABLE_SUSFS}" == "true" ]]; then
  susfs_badge_url="https://img.shields.io/badge/SUSFS-$(badge_encode "${susfs_display}")-FF6D00?style=for-the-badge&logo=gitlab&logoColor=white"
  susfs_badge_link="${info[susfs_url]:-https://gitlab.com/simonpunk/susfs4ksu}"
else
  susfs_badge_url="https://img.shields.io/badge/SUSFS-Disabled-757575?style=for-the-badge&logo=gitlab&logoColor=white"
  susfs_badge_link="https://gitlab.com/simonpunk/susfs4ksu"
fi

device_badge_url="https://img.shields.io/badge/Poco_F5_%2F_Note_12_Turbo-marble_%7C_marblein-EF5350?style=for-the-badge"
build_badge_url="https://img.shields.io/badge/Build-Passing-2088FF?style=for-the-badge&logo=githubactions&logoColor=white"

{
  echo '<div align="center">'
  echo
  echo "# Marble Kernel"
  echo
  echo "### Poco F5 · Redmi Note 12 Turbo"
  echo
  echo "[![Manager](${manager_badge_url})](${manager_badge_link})"
  echo "[![SUSFS](${susfs_badge_url})](${susfs_badge_link})"
  echo "[![Device](${device_badge_url})](https://github.com/${source_repo})"
  echo "[![Build](${build_badge_url})](${workflow_run})"
  echo
  echo "**${build_date}** &nbsp;·&nbsp; **Run #${run_number}** &nbsp;·&nbsp; [View workflow](${workflow_run})"
  echo
  echo '</div>'
  echo
  echo "---"
  echo

  echo "## ${EMOJI_BUILD} Build Configuration"
  echo
  echo "| | |"
  echo "|:---|:---|"
  summary_emit_config_rows info "${BUILD_SCOPE}"
  echo
  echo "---"
  echo

  summary_emit_cache_section \
    "${info[ccache_hit]:-unknown}" \
    "${info[thinlto_cache_hit]:-n/a}" \
    "${info[ccache_hit_rate]:-n/a}" \
    "${info[ccache_direct_rate]:-n/a}" \
    "${release_dir}/ccache-stats.txt"
  echo "---"
  echo

  if [[ "${manager_name}" == "none" ]]; then
    echo "## ${EMOJI_MANAGER} Manager — Baseline (No Root)"
    echo
    echo "No root manager is integrated. This is a vanilla kernel build for testing and baseline comparison."
  else
    echo "## ${EMOJI_MANAGER} Manager — ${manager_label}"
    echo
    echo "| | |"
    echo "|:---|:---|"
    echo "| **Repository** | [\`${manager_repo} @ ${info[manager_ref]:-}\`](https://github.com/${manager_repo}) |"
    [[ -n "${info[manager_build_version_name]:-}" ]] && \
      echo "| **Version name** | \`${info[manager_build_version_name]}\` |"
    _tag="${info[manager_build_tag]:-${info[manager_tag]:-}}"
    _code="${info[manager_build_version_code]:-${info[manager_version_code]:-}}"
    if [[ -n "${_tag}" && -n "${_code}" ]]; then
      echo "| **Version** | \`${_tag}\` &nbsp;·&nbsp; code \`${_code}\` |"
    elif [[ -n "${_tag}" ]]; then
      echo "| **Version** | \`${_tag}\` |"
    elif [[ -n "${_code}" ]]; then
      echo "| **Version code** | \`${_code}\` |"
    fi
    echo "| **Commit** | [\`$(short_commit "${manager_commit}")\`](https://github.com/${manager_repo}/commit/${manager_commit}) |"
    [[ -n "${info[manager_setup_sha256]:-}" ]] && \
      echo "| **setup.sh sha256** | \`${info[manager_setup_sha256]}\` |"
    [[ -n "${info[manager_signature_size]:-}" ]] && \
      echo "| **Signature size** | \`${info[manager_signature_size]}\` |"
    [[ -n "${info[manager_signature_hash]:-}" ]] && \
      echo "| **Signature hash** | \`${info[manager_signature_hash]}\` |"
    [[ -n "${info[manager_supported_line]:-}" ]] && \
      echo "| **Supported managers** | ${info[manager_supported_line]//,/, } |"
    if [[ "${manager_name}" == "kernelsu-next" && "${ENABLE_SUSFS}" == "true" ]]; then
      echo "| **Note** | Non-SUSFS builds use official \`KernelSU-Next/KernelSU-Next@dev\`; SUSFS builds use \`pershoot/dev-susfs\` |"
    fi
  fi
  echo
  echo "---"
  echo

  echo "## ${EMOJI_SUSFS} SUSFS"
  echo
  if [[ "${ENABLE_SUSFS}" == "true" ]]; then
    echo "| | |"
    echo "|:---|:---|"
    summary_emit_susfs_rows info
    echo
    summary_susfs_module_note
  else
    echo "SUSFS is not enabled for this build."
  fi
  echo
  echo "---"
  echo

  echo "## Installation"
  echo
  echo "<details>"
  echo "<summary><b>Prerequisites</b> — read before flashing</summary>"
  echo "<br>"
  echo
  echo "- Unlocked bootloader"
  echo "- Poco F5 (\`marblein\`) or Redmi Note 12 Turbo (\`marble\`) **only**"
  echo "- **${rom_support}** — flash only on a matching ROM family"
  echo "- Stock \`boot.img\` from the **same ROM and firmware**, stored off-device"
  [[ "${manager_name}" != "none" && -n "${manager_app_link}" ]] && \
    echo "- [${manager_label} manager app](${manager_app_link})"
  [[ "${ENABLE_SUSFS}" == "true" ]] && \
    echo "- [KSU SUSFS module](https://github.com/sidex15/susfs4ksu-module/releases) matching \`${susfs_display}\`"
  echo
  echo "</details>"
  echo
  echo "<details>"
  echo "<summary><b>Flash Steps</b></summary>"
  echo "<br>"
  echo
  echo "1. Download \`${zip_name}\`"
  echo "2. Verify it against the SHA-256 in this summary"
  echo "3. Flash the ZIP to the active slot with [Kernel Flasher](https://github.com/fatalcoder524/KernelFlasher/releases)"
  echo "4. AnyKernel3 verifies your device codename and **backs up** the current boot image to \`/sdcard/marble-kernel-backup/\` before writing"
  [[ "${manager_name}" != "none" ]] && echo "5. Reboot, then install or open the **${manager_label}** manager app"
  [[ "${ENABLE_SUSFS}" == "true" ]] && echo "6. Install the **KSU SUSFS module**, configure hiding rules, reboot"
  echo
  echo "</details>"
  echo
  summary_emit_bootloop_note
  echo
  echo "---"
  echo

  echo "## ${EMOJI_ARTIFACT} Artifacts & Checksums"
  echo
  echo "| File | Size | Notes |"
  echo "|:---|:---:|:---|"
  echo "| \`${zip_name}\` | ${zip_size} | Flashable AnyKernel3 zip |"
  echo "| \`${zip_name}.sha256\` | — | SHA-256 checksum |"
  echo "| \`build-info.txt\` | — | Exact resolved refs and workflow metadata |"
  echo
  echo "<details>"
  echo "<summary><b>SHA256 Checksums</b></summary>"
  echo "<br>"
  echo
  echo "| Artifact | SHA-256 |"
  echo "|:---|:---|"
  echo "| \`Image\` | \`${image_sha}\` |"
  echo "| \`.zip\` | \`${zip_sha}\` |"
  echo
  echo "</details>"
  echo
  echo "---"
  echo

  # Credits are derived from build-info — never hardcode a maintainer name.
  echo "## Credits"
  echo
  echo "| | |"
  echo "|:---|:---|"
  credit_author="${info[kernel_source_author]:-${info[kernel_source]:-kernel}}"
  if [[ -n "${source_repo}" ]]; then
    echo "| **Kernel source** | [${credit_author}](https://github.com/${source_repo}) (\`${source_repo}\`) |"
  else
    echo "| **Kernel source** | ${credit_author} |"
  fi
  echo "| **AnyKernel3** | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) |"
  if [[ "${manager_name}" != "none" && -n "${manager_repo}" ]]; then
    echo "| **${manager_label}** | [\`${manager_repo}\`](https://github.com/${manager_repo}) |"
  elif [[ "${manager_name}" != "none" ]]; then
    echo "| **${manager_label}** | ${manager_label} |"
  fi
  [[ "${ENABLE_SUSFS}" == "true" ]] && \
    echo "| **SUSFS** | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) |"
  echo
  echo "---"
  echo
  echo '<div align="center">'
  echo
  echo "Built with **GitHub Actions**"
  echo
  echo '</div>'
} > "${summary}"

cat "${summary}"
