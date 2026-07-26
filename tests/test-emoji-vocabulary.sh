#!/usr/bin/env bash
# The docs and generated summaries use six emoji and no others, so meaning stays
# attached to each symbol instead of decorating every heading.
#
#   📱 device   ⚙️ build   🔑 manager   🛡️ SUSFS   📦 artifacts   ⚠️ warning
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

allowed=('📱' '⚙️' '🔑' '🛡️' '📦' '⚠️')

mapfile -t targets < <(
  printf '%s\n' README.md
  find docs -name '*.md' -not -path 'docs/builds/*' | sort
  printf '%s\n' scripts/generate-build-summary.sh scripts/generate-matrix-summary.sh scripts/lib/summary-common.sh
)

# U+1F300–U+1FAFF pictographs, U+2600–U+27BF symbols/dingbats, and the U+2B00
# block arrows/stars that read as emoji in rendered markdown.
emoji_re='[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}\x{FE0F}\x{2049}\x{203C}]'

failed=0
for file in "${targets[@]}"; do
  [[ -f "${file}" ]] || continue

  # Strip the six approved symbols (with and without the variation selector),
  # then anything left in the emoji ranges is a violation.
  stripped="$(cat "${file}")"
  for symbol in "${allowed[@]}"; do
    stripped="${stripped//${symbol}/}"
  done
  # Bare forms, in case a variation selector was dropped somewhere.
  for bare in '⚙' '🛡' '⚠'; do
    stripped="${stripped//${bare}/}"
  done

  found="$(printf '%s' "${stripped}" | grep -oP "${emoji_re}" | sort -u | tr -d '\n' || true)"
  if [[ -n "${found}" ]]; then
    echo "FAIL: ${file} uses emoji outside the approved vocabulary: ${found}" >&2
    failed=1
  fi
done

if (( failed )); then
  echo "Approved vocabulary: ${allowed[*]}" >&2
  exit 1
fi

# The vocabulary is only useful if it is actually defined in one place.
for name in EMOJI_DEVICE EMOJI_BUILD EMOJI_MANAGER EMOJI_SUSFS EMOJI_ARTIFACT EMOJI_WARNING; do
  grep -Fq "${name}=" scripts/lib/summary-common.sh || {
    echo "FAIL: summary-common.sh does not define ${name}" >&2
    exit 1
  }
done

echo "Emoji vocabulary tests passed"
