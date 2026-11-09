# metrics-server rock on riscv64: verified result

Source: https://github.com/canonical/metrics-server-rock
Commit: f111a4b484af84f079c4073ec9d3bbd4ac03b84e (recipe 0.9.0)

Changes (0001-riscv64-platform-and-no-fips-module.patch):
* platforms: add riscv64.
* openssl part: skip openssl-fips-module-3 on riscv64 only (Ubuntu Pro
  archive has no riscv64), `- on riscv64: []` / `- else:`.
* drop the final `snap refresh go --channel 1.25-fips/stable`; that
  channel does not exist on riscv64. The recipe still builds with the
  go/1.26-fips snap and the Makefile unchanged (ARCH=riscv64 works).

Build on titan2vm1: about 30 minutes including pulling pebble.

Output: metrics-server_0.9.0_riscv64.rock (OCI archive, 40233472 bytes)
sha256 accc0e870fc1dd47bad54ce85101889835ddd3f51c1634da982704b45279506a

Checked with skopeo: architecture riscv64, os linux.
Not yet checked: running the image as a pod.

Import (see ../coredns/RESULT.md):
  skopeo copy oci-archive:metrics-server_0.9.0_riscv64.rock \
    docker-archive:metrics-server.tar:ghcr.io/canonical/metrics-server:0.9.0-ck0
  sudo /snap/k8s/current/bin/ctr --address /run/containerd/containerd.sock \
    -n k8s.io images import metrics-server.tar
