#!/usr/bin/env bash
# shellcheck disable=SC2034  # this is a library: its definitions are consumed by the sourcing scripts
# Shared building blocks for the per-build and combined matrix summaries.
#
# Emoji vocabulary is fixed at six symbols, used consistently and nowhere else.
# tests/test-emoji-vocabulary.sh enforces it.
#
#   📱 device   ⚙️ build   🔑 manager   🛡️ SUSFS   📦 artifacts   ⚠️ warning

EMOJI_DEVICE='📱'
EMOJI_BUILD='⚙️'
EMOJI_MANAGER='🔑'
EMOJI_SUSFS='🛡️'
EMOJI_ARTIFACT='📦'
EMOJI_WARNING='⚠️'

# ── Reading build metadata ───────────────────────────────────────────────────

# Load a key=value file once into the named associative array. Replaces the
# per-key `grep` calls that used to re-read build-info.txt six times per
# manager.
#   declare -A info; summary_load_info info path/to/build-info.txt
summary_load_info() {
  local -n _dest="$1"
  local file="$2" key value
  _dest=()
  [[ -f "${file}" ]] || return 0
  while IFS='=' read -r key value; do
    [[ -n "${key}" && "${key}" != \#* ]] || continue
    _dest["${key}"]="${value%$'\r'}"
  done < "${file}"
}

# Kept for callers that only need one field from a file they do not otherwise read.
summary_get_info() {
  local file="$1"
  local key="$2"
  grep -m1 "^${key}=" "${file}" | cut -d= -f2- || true
}

short_commit() {
  local value="$1"
  if [[ -z "${value}" || "${value}" == "unknown" ]]; then
    echo "unknown"
  else
    echo "${value:0:7}"
  fi
}

# Byte count to a compact human string, so summaries can report ZIP size from
# metadata alone when the artifact holds no ZIP.
summary_human_size() {
  local bytes="${1:-}"
  [[ "${bytes}" =~ ^[0-9]+$ ]] || { echo "—"; return; }
  awk -v b="${bytes}" 'BEGIN {
    split("B KiB MiB GiB", unit, " ")
    i = 1
    while (b >= 1024 && i < 4) { b /= 1024; i++ }
    printf (i == 1 ? "%d %s\n" : "%.1f %s\n"), b, unit[i]
  }'
}

# Encode a string for use in shields.io badge path segments.
# spaces → _   |   # → %23   |   - → -- (shields.io convention for literal dash)
badge_encode() {
  echo "$1" | sed 's/ /_/g; s/#/%23/g; s/-/--/g'
}

manager_display() {
  case "$1" in
    none)          echo "No Manager" ;;
    kernelsu)      echo "KernelSU" ;;
    kernelsu-next) echo "KernelSU-Next" ;;
    sukisu-ultra)  echo "SukiSU Ultra" ;;
    resukisu)      echo "ReSukiSU" ;;
    *)             echo "$1" ;;
  esac
}

manager_app_url() {
  case "$1" in
    kernelsu)      echo "https://github.com/tiann/KernelSU/releases" ;;
    kernelsu-next) echo "https://github.com/KernelSU-Next/KernelSU-Next/releases" ;;
    sukisu-ultra)  echo "https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases" ;;
    resukisu)      echo "https://github.com/ReSukiSU/ReSukiSU" ;;
    *)             echo "" ;;
  esac
}

summary_quality_label() {
  local kernel_source="${1:-melt}"
  if [[ "${kernel_source}" == "melt" ]]; then
    echo "melt-stable-candidate"
  else
    echo "los-experimental"
  fi
}

# ── Shared sections ──────────────────────────────────────────────────────────

# Build configuration rows, shared by both summaries. Caller opens the table.
# Arg: name of an associative array loaded by summary_load_info.
summary_emit_config_rows() {
  local -n _info="$1"
  local scope="${2:-image-only}"
  local source_repo="${_info[source_repo]:-}"
  local kernel_id="${_info[kernel_source]:-unknown}"
  local kernel_label="${_info[kernel_source_author]:-${kernel_id}}"

  echo "| ${EMOJI_DEVICE} **Device** | Poco F5 (\`marblein\`) · Redmi Note 12 Turbo (\`marble\`) |"
  if [[ -n "${_info[rom_support]:-}" ]]; then
    echo "| **ROM support** | **${_info[rom_support]}** |"
  fi
  if [[ -n "${source_repo}" ]]; then
    echo "| **Kernel Source** | **${kernel_label}** ([\`${kernel_id}\`](https://github.com/${source_repo})) |"
  else
    echo "| **Kernel Source** | **${kernel_label}** (\`${kernel_id}\`) |"
  fi
  echo "| **Kernel base** | \`android12-5.10\` |"
  echo "| ${EMOJI_BUILD} **Build scope** | \`${scope}\` |"
  [[ -n "${_info[package_family]:-}" ]] && echo "| **Package family** | \`${_info[package_family]}\` |"
  echo "| **Quality** | \`${_info[quality_label]:-$(summary_quality_label "${kernel_id}")}\` |"
  echo "| **LTO** | \`${_info[lto]:-thin}\` |"
  [[ -n "${_info[toolchain]:-}" ]] && echo "| **Toolchain** | \`${_info[toolchain]}\` |"
  echo "| **Source** | [\`${_info[source_ref]:-} @ $(short_commit "${_info[source_commit]:-}")\`](https://github.com/${source_repo}/commit/${_info[source_commit]:-}) |"
  echo "| **Compiler** | \`${_info[android_clang_version]:-clang-r416183b}\` |"
  [[ -n "${_info[android_clang_commit]:-}" ]] && echo "| **Compiler commit** | \`$(short_commit "${_info[android_clang_commit]}")\` |"
  [[ -n "${_info[kbuild_build_timestamp]:-}" ]] && echo "| **Kernel timestamp** | \`${_info[kbuild_build_timestamp]}\` (pinned to the source commit) |"
  return 0
}

# SUSFS table rows. Caller opens the table and decides the heading.
summary_emit_susfs_rows() {
  local -n _info="$1"
  local display="${_info[susfs_reported_version]:-${_info[susfs_version]:-}}"
  echo "| **Version** | \`${display}\` |"
  echo "| **Kernel branch** | \`${_info[susfs_kernel_branch]:-}\` |"
  if [[ -n "${_info[susfs_commit]:-}" ]]; then
    echo "| **Commit** | [\`$(short_commit "${_info[susfs_commit]}")\`](${_info[susfs_url]:-}) |"
  fi
}

summary_susfs_module_note() {
  cat <<EOF
### SUSFS userspace module

A SUSFS kernel needs both halves: flash the kernel ZIP **and** install a matching SUSFS userspace module for your manager, for example [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module/releases). Kernel patches alone do not give you full hide functionality.
EOF
}

summary_emit_flash_warning() {
  cat <<EOF
> [!WARNING]
> Custom kernels can bootloop or lose data. Artifacts are provided **as-is**.
>
> - Back up \`boot.img\` from the **same** ROM and firmware, stored off-device
> - Unlocked bootloader required
> - **Poco F5** (\`marblein\`) or **Redmi Note 12 Turbo** (\`marble\`) only
> - Match **device + ROM family** to the build you flash
> - Verify **SHA-256** before flashing
EOF
}

summary_emit_bootloop_note() {
  cat <<EOF
> [!WARNING]
> **Bootloop?** Flash the original \`boot.img\` from the same ROM and firmware back to the active slot with Kernel Flasher or fastboot. Keep that backup reachable **before** you flash.
EOF
}

# ── Cache section (CI only — stripped from GitHub Release notes) ─────────────

SUMMARY_CACHE_START='<!-- marble-ci-cache-start -->'
SUMMARY_CACHE_END='<!-- marble-ci-cache-end -->'

# Args: ccache_hit thinlto_hit hit_rate direct_rate [path_to_ccache-stats.txt]
summary_emit_cache_section() {
  local ccache_hit="${1:-unknown}"
  local thinlto_hit="${2:-n/a}"
  local hit_rate="${3:-n/a}"
  local direct_rate="${4:-n/a}"
  local stats_file="${5:-}"

  echo "${SUMMARY_CACHE_START}"
  echo "## Cache"
  echo
  echo "> CI diagnostics only — this section is **not** included in GitHub Release notes."
  echo
  echo "| | |"
  echo "|:---|:---|"
  echo "| **Actions ccache hit** | \`${ccache_hit}\` |"
  echo "| **Actions ThinLTO hit** | \`${thinlto_hit}\` |"
  echo "| **ccache hit rate** | \`${hit_rate:-n/a}\` |"
  echo "| **ccache direct rate** | \`${direct_rate:-n/a}\` |"
  echo
  echo "### ccache -s"
  echo
  echo '```text'
  if [[ -n "${stats_file}" && -f "${stats_file}" ]]; then
    cat "${stats_file}"
  else
    echo "(ccache-stats.txt not available)"
  fi
  echo '```'
  echo
  echo "${SUMMARY_CACHE_END}"
}

# Strip CI-only cache section markers from a markdown file.
# Usage: summary_strip_cache_section input.md [output.md]
# If output omitted, prints to stdout.
summary_strip_cache_section() {
  local input="${1:-}"
  local output="${2:-}"
  if [[ -z "${input}" || ! -f "${input}" ]]; then
    echo "::error::summary_strip_cache_section: missing input ${input}" >&2
    return 1
  fi
  local stripped
  stripped="$(
    awk -v start="${SUMMARY_CACHE_START}" -v end="${SUMMARY_CACHE_END}" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "${input}"
  )"
  # Drop extra blank lines left where the section was removed (collapse 3+ → 2).
  stripped="$(printf '%s\n' "${stripped}" | awk 'BEGIN{b=0} /^$/{b++; if(b<=2) print; next} {b=0; print}')"
  if [[ -n "${output}" ]]; then
    printf '%s\n' "${stripped}" > "${output}"
  else
    printf '%s\n' "${stripped}"
  fi
}
