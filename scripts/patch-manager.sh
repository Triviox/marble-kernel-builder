#!/usr/bin/env bash
set -euo pipefail

MANAGER="${MANAGER:-none}"
KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
RESOLVED_REFS_FILE="${RESOLVED_REFS_FILE:-release/resolved-refs.env}"

if [[ "${MANAGER}" == "none" ]]; then
  echo "No manager selected"
  echo "manager_setup_sha256=" >> "${RESOLVED_REFS_FILE}"
  exit 0
fi

source "${RESOLVED_REFS_FILE}"

if [[ -z "${manager_repo}" || -z "${manager_commit}" || -z "${manager_setup_path}" ]]; then
  echo "::error::Manager resolution missing repo, commit, or setup path"
  exit 1
fi

setup_script="${RUNNER_TEMP:-/tmp}/manager-setup.sh"
setup_url="https://raw.githubusercontent.com/${manager_repo}/${manager_commit}/${manager_setup_path}"
echo "Applying ${MANAGER} from ${manager_repo}@${manager_commit}"
curl -fsSL --retry 3 --retry-delay 5 "${setup_url}" -o "${setup_script}"

# This script is fetched at a pinned commit and then executed, so record what
# was actually run.
setup_sha256="$(sha256sum "${setup_script}" | awk '{print $1}')"
echo "manager_setup_sha256=${setup_sha256}" >> "${RESOLVED_REFS_FILE}"
echo "Manager setup.sh sha256: ${setup_sha256}"

pushd "${KERNEL_DIR}" >/dev/null
bash "${setup_script}" "${manager_commit}"
popd >/dev/null
