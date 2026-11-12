# cilium-envoy on riscv64

Build host: titan2vm1. Source: github.com/cilium/proxy branch v1.37
(Envoy 1.37.7), Bazel 7.7.1, clang-18 from the Ubuntu archive.

## Files

| File | Purpose |
|---|---|
| bazel-bootstrap.sh, rules_java_riscv64_jni.patch | Build Bazel 7.7.1 from the source distribution |
| 0001-riscv64-platform.patch | All changes to cilium/proxy (apply with `git apply`) |
| riscv64.bazelrc | Bazel options for riscv64 (Java runtime) |
| build.sh | Builds libcilium.so and bazel-bin/cilium-envoy |

## Packages needed (root)

    apt install clang-18 llvm-18 lld-18 clang-tools-18 clang-format-18 \
      libc++-18-dev libc++abi-18-dev cmake ninja-build patchelf \
      autoconf automake libtool python-is-python3 virtualenv

plus openjdk-21-jdk-headless, build-essential, zip, unzip for Bazel.

## Problems found, in the order met

1. Bazel client dies with SIGILL once it talks to its server. absl
   `UnscaledCycleClock::Now` uses `rdcycle`, which the Ubuntu 7.0
   kernel does not allow for user space. Binary patch of that one
   instruction in bazel (c0002573 rdcycle -> c0102573 rdtime; the
   offset 0x1e8d44 is specific to this build, find it with the
   faulting address from `strace -f`).
2. cilium/proxy knows only the platforms linux_x86_64 and
   linux_aarch64: add linux_riscv64 (bazel/BUILD,
   bazel/platform_mappings, bazel/toolchains/BUILD). The tools are
   taken from /usr/lib/llvm-18/bin, so no symlinks in /usr/bin.
3. clang.bazelrc: `make` runs `bazel info`, which crashed (1); build.sh
   calls bazel/setup_clang.sh with BAZELRC_FILE set.
4. aspect_bazel_lib has no riscv64 yq and jq (patches/0010). yq is
   built with `go install github.com/mikefarah/yq/v4@v4.24.4` into
   /home/llm/tools; jq is /usr/bin/jq.
5. crate_universe (cargo-bazel) rejects riscv64 hosts. Only the
   dynamic modules Rust SDK uses it: the repository is stubbed.
6. rules_buf has no riscv64 binary (lint only): not registered.
7. toolchains_llvm rejects linux-riscv64: `@llvm_toolchain` is an
   empty stub, //bazel/toolchains is used.
8. Java: envoy.bazelrc asks for remotejdk_11. riscv64.bazelrc selects
   the local JDK 21 and bazel/java/BUILD maps the hard-coded
   remotejdk_21 request of rules_java onto it.
9. rules_python: pip_repository.bzl lacks linux_riscv64 (patches/0011)
   and has no riscv64 python-build-standalone, so pip_parse uses the
   system python3 (patches/0012).
10. A stale `bazel cquery` from debugging blocked the server lock
    ("Another command is running"). Kill it by pid.
11. The bundled pkg-config does not know riscv64 (config.guess):
    rules_foreign_cc_dependencies(register_built_pkgconfig_toolchain =
    False) uses /usr/bin/pkg-config.
12. V8 13.8 BUILD.bazel lists src/codegen/riscv/extension-riscv-inl.h,
    which does not exist. The Wasm runtimes v8, wamr and wasmtime are
    commented out in envoy_build_config/extensions_build_config.bzl.
    The image therefore has no Wasm runtime (the null runtime remains).
13. rules_foreign_cc bootstraps its own CMake (hour long, and it failed
    with exit 11): register_built_tools = False uses the installed
    cmake, ninja and make.
14. cmake 4.2 rejects libevent's cmake_minimum_required:
    --action_env=CMAKE_POLICY_VERSION_MINIMUM=3.5 in riscv64.bazelrc.
15. GCC 15 headers: `<cstdbool> is deprecated` is an error with
    -Werror: --copt and --host_copt -Wno-error=cpp in riscv64.bazelrc.

## State

Built on titan2vm1 (6572 actions, 24 GB RAM, many hours):

    cilium-envoy version: 293ab4c1e2b1.../1.37.7/Distribution/RELEASE/BoringSSL
    ELF 64-bit RISC-V, 49 MB, needs libatomic.so.1
    sha256 6367734a67fd7e4785bf13ec50f403e2f3ac62510add7d9182707a71724ef731

`--version` runs. Not yet tested: a real Cilium run with envoy.enabled,
cilium-envoy-starter and cilium-envoy-healthcheck (not built here yet),
libcilium.so, ingress and gateway.

## Build

    cd ~/k8s && git clone -b v1.37 https://github.com/cilium/proxy cilium-proxy
    cd cilium-proxy && git apply ../images/cilium-envoy/0001-riscv64-platform.patch
    ../images/cilium-envoy/build.sh      # hours; run under script(1)
