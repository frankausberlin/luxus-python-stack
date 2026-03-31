#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Validating shell syntax..."
for shell_file in \
    "$ROOT_DIR/luxuspythonstack/scripts/pyinit.sh" \
    "$ROOT_DIR/luxuspythonstack/scripts/launch_jupyter.sh" \
    "$ROOT_DIR/luxuspythonstack/scripts/install_luxuspythonstack.sh" \
    "$ROOT_DIR/luxuspythonstack/scripts/.bash_lib_luxuspythonstack" \
    "$ROOT_DIR/luxuspythonstack/scripts/validate_luxuspythonstack.sh"
do
    bash -n "$shell_file"
done

echo "Checking for stale documentation references..."
if grep -RInE 'luxurypythonstack|reference directory|source scripts/\.bash_lib_luxuspythonstack' \
    "$ROOT_DIR/README.md" \
    "$ROOT_DIR/luxuspythonstack/references" \
    "$ROOT_DIR/luxuspythonstack/SKILL.md"; then
    echo "Validation failed: stale references found." >&2
    exit 1
fi

echo "Validation passed."
