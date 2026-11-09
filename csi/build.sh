#!/bin/bash
# Build the four CSI sidecar rocks for riscv64 on a riscv64 host.
# Usage: ./build.sh [workdir]
set -euo pipefail

WORKDIR="${1:-$HOME/rocks}"
REPO=https://github.com/canonical/csi-rocks
COMMIT=b69dc01e55663dd226074cc6171f643cae3f0d94
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -d csi-rocks ] || git clone "$REPO"
cd csi-rocks
git fetch --depth 1 origin "$COMMIT" 2>/dev/null || git fetch origin
git checkout -q -B riscv64 "$COMMIT"
git apply "$HERE/0001-riscv64-platform-and-no-fips-module.patch"

for d in csi-node-driver-registrar/2.17.0 csi-provisioner/6.3.0 \
         csi-resizer/2.2.1 csi-snapshotter/8.6.0; do
  (cd "$d"
   # rockcraft needs a terminal
   script -qfec 'rockcraft pack --verbosity=verbose' \
     "/tmp/rock-$(basename "$(dirname "$d")").out"
   ls -l ./*.rock)
done
