# riscv64 container images (rocks)

Exact, repeatable recipes for the container images that the k8s snap
deploys. Every directory holds the patch for the upstream rock
repository, a build script and a record of the verified result.

Build host: titan2vm1 (Ubuntu 26.04, riscv64, 6 cores, 24 GiB RAM +
24 GiB swap), rockcraft 1.21.2 (snap, classic), LXD from snap, user in
the lxd group. rockcraft needs a tty, so run it under `script`.

| Image | Directory | Status on titan2vm1 |
|---|---|---|
| coredns 1.14.7-ck0 | coredns/ | running |
| metrics-server 0.9.0-ck0 | metrics-server/ | running |
| cilium-operator-generic 1.20.0-ck0 | cilium-operator-generic/ | running; no Delve on riscv64 |
| cilium 1.20.0-ck0 | cilium/ | running; riscv64-only variant on ubuntu@26.04 (no zig), BPF alignment patch, cilium-envoy embedded; gateway tested |
| pause 3.10 | pause/ | no rock; docker.io/xypron/pause:3.10 retagged as ghcr.io/canonical/k8s-snap/pause:3.10 |
| csi-node-driver-registrar, csi-provisioner, csi-resizer, csi-snapshotter | csi/ | running (rawfile CSI node 4/4, controller 2/2); the volume test passed |
| metallb controller/speaker | metallb/ | running |
| frr, frr-k8s | metallb/ | built and imported; not started (frr and frr-k8s are for the BGP mode) |
| rawfile-localpv 0.8.3-ck5 | rawfile-localpv/ | running; grpcio needs libatomic (2h20 first build, 1h15 later) |
| cilium-envoy | cilium/ | built into the cilium rock (part cilium-envoy, Bazel built from source); HTTP gateway traffic tested, Wasm/ingress not |

The snap pins the image names in its images.txt
(/snap/k8s/current/images.txt); a rock must carry exactly that
reference. Cilium is 1.20.0 because the snap (k8sd chart cilium-1.20.0)
and the newest cilium-rocks recipe use it; upstream is at 1.20.4.

## Make a tar and import it

    skopeo copy oci-archive:<name>_<ver>_riscv64.rock \
      docker-archive:<name>.tar:ghcr.io/canonical/<name>:<tag>
    sudo /snap/k8s/current/bin/ctr \
      --address /run/containerd/containerd.sock \
      -n k8s.io images import <name>.tar

A tar copied to /var/snap/k8s/common/images was not picked up.

## Lessons

* Patch form for the Pro-only package: `- on riscv64: []` and
  `- else: [openssl-fips-module-3]`. craft-grammar `try:` does not work.
* Recipes download Go modules and git sources at build time. Transient
  git errors (early EOF) happen: just rerun.
* Builds take 30-40 minutes; use a background job and poll the
  `script` output file: `tr '\r' '\n' < out | grep -av '(.*s)$'`.

## Layout

Each image directory holds the patches, `build.sh` and `RESULT.md`.
The built tar files are in `<name>/build/` and are not tracked by git
(see `.gitignore`). The tar name is the image name; the reference
inside is the one that the snap expects.
