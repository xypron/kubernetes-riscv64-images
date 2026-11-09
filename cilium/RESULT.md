# cilium agent rock on riscv64: verified result

Source: https://github.com/canonical/cilium-rocks
Commit: 15659e5e1dbcc05b0939f7bd0894350ca51db82f (recipe 1.20.0)

Changes (0001-riscv64-build.patch), a riscv64-only variant of the recipe:
* platforms: riscv64 only; base and build-base ubuntu@24.04. The jammy
  suites do not carry clang-19/llvm-19 for riscv64 and apt.llvm.org has
  no riscv64 (Architectures: amd64 i386 s390x arm64). noble-updates has
  clang-19 and llvm-19 for riscv64.
* package-repositories removed (all were jammy or apt.llvm.org).
* bazelisk and cilium-envoy parts removed: no Bazel for riscv64 yet
  (PLAN.md 3.2). Envoy is disabled in the snap by default.
* zig part removed: the Go build uses the native gcc instead of
  `zig cc -target ...2.31`. This also removes a download at build time.
* llvm part: stage clang-19 and llvm-19 from the archive and link
  clang, llc, llvm-objcopy, llvm-strip into /usr/local/bin, instead of
  building LLVM 19 from source.
* openssl part: no openssl-fips-module-3 (Ubuntu Pro, no riscv64).

This is not mergeable as is: it drops amd64/arm64. A merge request has
to make the changes per architecture.

Build on titan2vm1: about 65 minutes.

Output: cilium_1.20.0_riscv64.rock (370200064 bytes)
sha256 744aa0218f019d57e32ea312d90a2af90aaafbbba398f41bc37e6934fbf1f812

Checked with skopeo: architecture riscv64, os linux, 4 layers.
Not yet checked: BPF programs compile with clang-19 in the image, the
agent starts, connectivity.

Import reference: ghcr.io/canonical/cilium:1.20.0-ck0

## Run on titan2vm1 (kernel 7.0.0-42)

With 0001 only, the agent started but the verifier rejected the datapath
(`misaligned packet access`). 0002-riscv64-bpf-any-alignment.patch adds
BPF_F_ANY_ALIGNMENT on riscv64. With it the agent is Running 1/1, so
clang-19 compiles the BPF programs and the kernel loads them, and CoreDNS
starts. See PLAN.md 7.7.

rock sha256 313fdf088ca6df5f24ce9946a23124a1255dd1af177816a5a1176e5aa816d58a
