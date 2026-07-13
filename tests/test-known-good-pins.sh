#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("config/known-good-pins.json").read_text(encoding="utf-8"))
assert "susfs" in data
assert "gki-android12-5.10" in data["susfs"]
assert "v2.2.0" in data["susfs"]["gki-android12-5.10"]
assert "managers" in data
assert "sources" in data
assert "melt" in data["sources"]
assert "lineageos" in data["sources"]
assert "pa-gr" in data["sources"]
assert data["sources"]["pa-gr"]["repo"] == "pa-gr/android_kernel_xiaomi_sm8450"
assert data["sources"]["pa-gr"]["ref"] == "vauxite"
print("known-good-pins ok")
PY

echo "Known-good pins tests passed"
