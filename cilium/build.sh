#!/bin/bash
# Build the cilium agent rock for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/cilium-rocks
COMMIT=15659e5e1dbcc05b0939f7bd0894350ca51db82f
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d cilium-rocks ] || git clone "$REPO"
cd cilium-rocks
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-build.patch"

cd 1.20.0/cilium
cp "$HERE/0002-riscv64-bpf-any-alignment.patch" .
# rockcraft needs a terminal
script -qfec 'rockcraft pack --verbosity=verbose' /tmp/rock-cilium.out
ls -l cilium_1.20.0_riscv64.rock
