# cilium-envoy on riscv64 (in progress)

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

## State

Analysis succeeds (about 54000 targets). Compilation started:
1042 of 10717 actions done after a few minutes. Open: whatever fails
in tcmalloc, BoringSSL, QUICHE, V8/Wasm, LuaJIT, ...

## Build

    cd ~/k8s && git clone -b v1.37 https://github.com/cilium/proxy cilium-proxy
    cd cilium-proxy && git apply ../images/cilium-envoy/0001-riscv64-platform.patch
    ../images/cilium-envoy/build.sh      # hours; run under script(1)
