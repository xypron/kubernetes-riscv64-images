# cilium-operator-generic rock on riscv64: verified result

Source: https://github.com/canonical/cilium-rocks
Commit: 15659e5e1dbcc05b0939f7bd0894350ca51db82f (recipe 1.20.0)

Changes (0001-riscv64-platform-and-no-fips-module.patch):
* platforms: add riscv64.
* openssl part: skip openssl-fips-module-3 on riscv64 only (Ubuntu Pro
  archive has no riscv64), `- on riscv64: []` / `- else:`.
* debug-wrapper part: do not install the Delve debugger (dlv) on
  riscv64. Delve does not support the architecture and the build fails
  with "your_linux_architecture_is_not_supported_by_delve". The rock has
  no /usr/bin/dlv on riscv64.

The recipe is otherwise unchanged. It builds with the go/1.26-fips snap,
protoc from source (cmake) and downloads Go modules at build time, see
PLAN.md 6.1. A first attempt failed with a transient git "early EOF"
while cloning protobuf; a retry succeeded.

Build on titan2vm1: about 35 minutes for the successful run.

Output: cilium-operator-generic_1.20.0_riscv64.rock (89445888 bytes)
sha256 5ac69615292deb1b30fb67f96afc4c65622fbd414556c54f49741dced7561174

Checked with skopeo: architecture riscv64, os linux.
Not yet checked: running the image as a pod.

Import (see ../coredns/RESULT.md), reference from images.txt:
  skopeo copy oci-archive:cilium-operator-generic_1.20.0_riscv64.rock \
    docker-archive:cilium-operator-generic.tar:ghcr.io/canonical/cilium-operator-generic:1.20.0-ck0
