# metallb, frr and frr-k8s rocks on riscv64

Source: https://github.com/canonical/metallb-rocks
Commit: 68eda59067fec0ea8e1030a9973f9a854ec14fa9

Versions (from /snap/k8s/current/images.txt): metallb controller and
speaker v0.16.1, frr 10.4.3, frr-k8s v0.0.25, all tagged -ck0.

Changes (0001-riscv64-platform-and-no-fips-module.patch):
* add the riscv64 platform;
* skip openssl-fips-module-3 on riscv64 only (`on riscv64` / `else`);
* `snap refresh go --channel 1.25-fips/stable` uses 1.26-fips on
  riscv64, the 1.25-fips channel does not exist there.

build.sh builds the four rocks one after another. Status: see below.

Built on titan2vm1 (about 25 minutes for metallb, 40 for frr, 10 for
frr-k8s). All four: architecture riscv64, os linux (skopeo). Not yet run
as pods.

| rock | sha256 |
|---|---|
| metallb-controller_v0.16.1 | 211b1dc16fadd6f7049ad3336e9cce0a55c8b0495704fe2820ebada1613c28b6 |
| metallb-speaker_v0.16.1 | 693c2fe15efa9e8bf91cfd809b0c281a41d12a30cfaea950af357758ee54e3b6 |
| frr_10.4.3 | 5577f4997886ea590056d0d968cfd385fc29dc70b7f2d8f517d3dfb94b2278e1 |
| frr-k8s_v0.0.25 | 1e7aaab42486c2c63dcea0efa5d9f251ab347069b767227fcb1d0e08996711a9 |

Tars with the snap's references are in ~/images on titan2vm1, for example
ghcr.io/canonical/frr:10.4.3-ck0.
