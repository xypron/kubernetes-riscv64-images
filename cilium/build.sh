#!/bin/bash
# Build the cilium agent rock for riscv64 on a riscv64 host. The rock
# contains cilium-envoy, built with a Bazel that is built from source
# first (about 6 hours in total on 6 cores, 24 GiB RAM and 24 GiB swap).
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
for f in 0002-riscv64-bpf-any-alignment.patch \
         0003-cilium-proxy-riscv64.patch \
         bazel-from-source.sh bazel-abseil-no-rdcycle.patch \
         bazel-rules-java-jni.patch riscv64.bazelrc; do
  cp "$HERE/$f" .
done
# rockcraft needs a terminal
script -qfec 'rockcraft pack --verbosity=verbose' /tmp/rock-cilium.out
ls -l cilium_1.20.0_riscv64.rock
