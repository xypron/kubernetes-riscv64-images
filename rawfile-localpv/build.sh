#!/bin/bash
# Build the rawfile-localpv rock for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/rawfile-localpv
COMMIT=b79640c8f6ffe1597f9921561d13d8e64104cfd0
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d rawfile-localpv ] || git clone "$REPO"
cd rawfile-localpv
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-platform-and-no-fips-module.patch"
git apply "$HERE/0002-link-grpcio-with-libatomic.patch"

# rockcraft needs a terminal
script -qfec 'rockcraft pack --verbosity=verbose' /tmp/rock-rawfile.out
ls -l rawfile-localpv_0.8.3_riscv64.rock
