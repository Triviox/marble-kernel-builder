#!/usr/bin/env bash
# Reclaim disk on a GitHub-hosted runner before a kernel build.
#
# `rm -rf` over the hosted SDKs costs roughly a minute of wall clock before the
# compile can start. Relocating them into a trash directory is a same-filesystem
# rename, so it returns at once and the purge runs in the background at idle
# priority. Space then frees progressively during the early part of the build,
# well before the link stage needs it — rather than the build waiting for it.
set -euo pipefail

available_gib="$(df --output=avail -BG / | tail -n1 | tr -dc '0-9')"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "available_gib=${available_gib}" >> "${GITHUB_OUTPUT}"
fi
echo "Free space before cleanup: ${available_gib} GiB (lto=${LTO:-thin})"

trash="${RUNNER_TEMP:-/tmp}/marble-trash"
mkdir -p "${trash}"

# Never needed by a kernel build. Ordered roughly by size.
targets=(
  /usr/share/dotnet
  /usr/local/lib/android
  /opt/ghc
  /usr/local/share/boost
  /usr/share/swift
  /opt/hostedtoolcache/CodeQL
  /usr/local/lib/node_modules
  /usr/local/share/powershell
  /usr/local/share/chromium
  /usr/share/miniconda
  /usr/local/aws-sam-cli
  /usr/local/aws-cli
  /usr/share/gradle
)

moved=0
for target in "${targets[@]}"; do
  [[ -e "${target}" ]] || continue
  if sudo mv "${target}" "${trash}/" 2>/dev/null; then
    moved=$((moved + 1))
  fi
done

# Detached so the delete overlaps the compile rather than blocking it.
sudo nohup nice -n 19 ionice -c 3 rm -rf "${trash}" >/dev/null 2>&1 &
disown || true

echo "Relocated ${moved} director(ies); purging in the background"
df -h /
