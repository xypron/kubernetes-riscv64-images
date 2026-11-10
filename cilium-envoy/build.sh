#!/bin/bash
# Build cilium-envoy on riscv64 (run on the riscv64 host).
# Needs: clang-18 llvm-18 lld-18 libc++-18-dev libc++abi-18-dev cmake
# ninja-build patchelf autoconf automake libtool python-is-python3
# and Bazel 7.7.1 (see bazel-bootstrap.sh).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-riscv64
export PATH=/usr/lib/llvm-18/bin:/home/llm/bin:$PATH
export PKG_BUILD=1 EMAIL=root@localhost
cd /home/llm/k8s/cilium-proxy
make -C proxylib all
# bazel needs the rdcycle->rdtime binary patch, see RESULT.md.
BAZELRC_FILE=$PWD/clang.bazelrc bazel/setup_clang.sh /usr/lib/llvm-18
git rev-parse HEAD >SOURCE_VERSION
make BAZEL_OPTS="--bazelrc=$HERE/riscv64.bazelrc" bazel-bin/cilium-envoy
