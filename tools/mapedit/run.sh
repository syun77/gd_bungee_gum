#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/mapedit.XXXXXXXX")"
trap 'rm -rf -- "$build_dir"' EXIT
xcrun swiftc -module-cache-path "$build_dir/modules" MapDocument.swift Canvas.swift main.swift -o "$build_dir/MapEdit"
"$build_dir/MapEdit"
