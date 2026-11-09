# CSI sidecar rocks on riscv64

Source: https://github.com/canonical/csi-rocks
Commit: b69dc01e55663dd226074cc6171f643cae3f0d94

Versions (from /snap/k8s/current/images.txt): csi-node-driver-registrar
2.17.0, csi-provisioner 6.3.0, csi-resizer 2.2.1, csi-snapshotter 8.6.0,
all tagged -ck0.

Changes (0001-riscv64-platform-and-no-fips-module.patch): add the riscv64
platform and skip openssl-fips-module-3 on riscv64 only. The recipes
already run `snap refresh go --channel=1.26-fips/stable`.

Also needed on riscv64: `build-snaps: [go/1.26-fips/stable]` on the Go
part. The recipe takes Go from the pebble part's dependency chain on
the other architectures; on riscv64 the build failed with "'go' not
found and part does not depend on a part named 'go-deps'".

build.sh builds the four rocks one after another, about 15 minutes each.

All four: architecture riscv64, os linux (skopeo). Not yet run as pods.

| rock | sha256 |
|---|---|
| csi-node-driver-registrar_2.17.0 | 1d209521062699c82cd0e42eff181939d0a6235b9ea34fbd02ef8c6ee63700a8 |
| csi-provisioner_6.3.0 | 72f8ea4968130635d3fb1526be40f33d912131a97f885d4b1d0faaceb6bffe02 |
| csi-resizer_2.2.1 | 3a2076f96a45858d43eb7f0cce9adfa88792ff90d6cf3af4c621e9f0ec816f6b |
| csi-snapshotter_8.6.0 | d0473f99a446ea2ec959156f30edc18cc0580fd6db2c7caef3c662b2b120829d |

Tars with the snap's references are in ~/images on titan2vm1, for example
ghcr.io/canonical/csi-provisioner:6.3.0-ck0.
