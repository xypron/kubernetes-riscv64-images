# CoreDNS rock on riscv64: verified result

Source: https://github.com/canonical/coredns-rock
Commit: c11431d841731829dc83d41f68450febd4d65ece (recipe 1.14.7,
CoreDNS v1.14.7)

Changes (0001-riscv64-platform-and-no-fips-module.patch):
* platforms: add riscv64.
* openssl part: openssl-fips-module-3 is a Ubuntu Pro package (archive
  esm.ubuntu.com/fips-updates) and that archive has no riscv64. The
  patch skips it on riscv64 only (`- on riscv64: []` / `- else:`), all
  other architectures stay unchanged. The rock on riscv64 therefore has
  no OpenSSL FIPS module. CoreDNS is still built with the Go 1.26-fips
  toolchain (opensslcrypto).
  Nothing is downloaded at build time besides what rockcraft/craft-parts
  fetch itself (git source, go modules, snap, apt); see PLAN.md 6.1.

NOTE: the verified rock below was built with the first form of the patch
(`to amd64` / `to arm64`), which gives the same package list on riscv64.
Rebuild with the current patch before relying on it (TODO).

Build on titan2vm1: about 35 minutes wall clock including the one-time
creation of the rockcraft base container.

Output: coredns_1.14.7_riscv64.rock (OCI archive, 35645952 bytes)
sha256 b1dafb6071a167af80c17c3ff8d0b557a9cbada8719702ea5a6021624bace603

Checked with skopeo:
* config architecture riscv64, os linux
* entrypoint /usr/bin/pebble enter --args coredns

Not yet checked: running the image as a pod, resolving names.

Import into the snap's containerd (verified on titan2vm1):
  skopeo copy oci-archive:coredns_1.14.7_riscv64.rock \
    docker-archive:coredns.tar:ghcr.io/canonical/coredns:1.14.7-ck0
  sudo /snap/k8s/current/bin/ctr --address /run/containerd/containerd.sock \
    -n k8s.io images import coredns.tar
  -> ghcr.io/canonical/coredns:1.14.7-ck0, linux/riscv64, 91.1 MiB.
The tag must equal the reference in /snap/k8s/current/images.txt.
Copying the tar to /var/snap/k8s/common/images alone did not import it.
