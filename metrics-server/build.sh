#!/bin/bash
# Build the metrics-server rock for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/metrics-server-rock
COMMIT=f111a4b484af84f079c4073ec9d3bbd4ac03b84e
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d metrics-server-rock ] || git clone "$REPO"
cd metrics-server-rock
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-platform-and-no-fips-module.patch"

cd 0.9.0
# rockcraft needs a terminal
script -qfec 'rockcraft pack --verbosity=verbose' /tmp/rock-metrics-server.out
ls -l metrics-server_0.9.0_riscv64.rock
