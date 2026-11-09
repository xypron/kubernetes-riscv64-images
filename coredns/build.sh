#!/bin/bash
# Build the CoreDNS rock for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/coredns-rock
COMMIT=c11431d841731829dc83d41f68450febd4d65ece
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d coredns-rock ] || git clone "$REPO"
cd coredns-rock
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-platform-and-no-fips-module.patch"

cd 1.14.7
# rockcraft needs a terminal
script -qfec 'rockcraft pack --verbosity=verbose' /tmp/rock-coredns.out
ls -l coredns_1.14.7_riscv64.rock
