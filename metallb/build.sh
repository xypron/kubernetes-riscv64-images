#!/bin/bash
# Build the metallb, frr and frr-k8s rocks for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/metallb-rocks
COMMIT=68eda59067fec0ea8e1030a9973f9a854ec14fa9
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d metallb-rocks ] || git clone "$REPO"
cd metallb-rocks
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-platform-and-no-fips-module.patch"

for d in metallb/v0.16.1/controller metallb/v0.16.1/speaker \
         frr/10.4.3 frr-k8s/v0.0.25; do
  (cd "$d"
   # rockcraft needs a terminal
   script -qfec 'rockcraft pack --verbosity=verbose' \
     "/tmp/rock-$(echo "$d" | tr / -).out"
   ls -l ./*.rock)
done
