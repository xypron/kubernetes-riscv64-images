# rawfile-localpv rock on riscv64

Source: https://github.com/canonical/rawfile-localpv (rockcraft.yaml in
the repository root, version 0.8.3)
Commit: b79640c8f6ffe1597f9921561d13d8e64104cfd0 (main; the SBOM script
of the snap uses main). The snap references ghcr.io/canonical/
rawfile-localpv:0.8.3-ck5.

Changes (0001-riscv64-platform-and-no-fips-module.patch): add the
riscv64 platform and skip openssl-fips-module-3 on riscv64 only.

Status: see the end of this file.

Built on titan2vm1: about 2 hours 20 minutes, most of it compiling the
grpcio and grpcio-tools wheels from source (no riscv64 wheels on PyPI).

Output: rawfile-localpv_0.8.3_riscv64.rock (83843584 bytes)
sha256 df62afa1fbd6185db9282a1135bfb3ea7802fe696e329196e356e1eb9b232b3b

Checked with skopeo: architecture riscv64, os linux.
Not yet checked: running as a pod, btrfsutil wheel import at runtime.

Tar reference: ghcr.io/canonical/rawfile-localpv:0.8.3-ck5

## Fix: grpcio needs libatomic (0002-link-grpcio-with-libatomic.patch)

The first rock crashed at start: `ImportError: cygrpc...so: undefined
symbol: __atomic_exchange_1`. grpcio's setup.py adds -latomic only when
64 bit atomics need it; riscv64 also needs it for 1 and 2 byte atomics.
0002 sets GRPC_PYTHON_LDFLAGS="-lpthread -latomic -static-libgcc" for
the build and stages libatomic1. Rebuilt in about 1h15m.
Checked: cygrpc.so has NEEDED libatomic.so.1, and the image contains
usr/lib/riscv64-linux-gnu/libatomic.so.1.
sha256 dc2c1a40e5d65fd0982ccad9c0319096f6f44abd29351d1b713ef0808eecd169
Run result: see PLAN.md 7.8.

Run result on titan2vm1: CSI controller 2/2 and node 4/4 Running; PVC
provisioned and written by a pod.
