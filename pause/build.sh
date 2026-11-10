#!/bin/bash
# Build the pause image for riscv64 on a riscv64 host, without docker.
# Needs: gcc, tar, python3, skopeo.
# Usage: ./build.sh [reference]
# Output: build/pause.tar (docker-archive, importable with ctr) and
#         build/oci (OCI layout, pushable with skopeo).
set -euo pipefail

REF="${1:-ghcr.io/canonical/k8s-snap/pause:3.10}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/build"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

rm -rf "$OUT"
mkdir -p "$OUT"

# Same flags as build/pause/Makefile in kubernetes (v1.37.1, TAG 3.10.2).
gcc -Os -Wall -Werror -static -DVERSION=v3.10 -o "$TMP/pause" "$HERE/pause.c"
strip "$TMP/pause"

mkdir "$TMP/root"
install -m 0555 "$TMP/pause" "$TMP/root/pause"
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
  -C "$TMP/root" -cf "$TMP/layer.tar" pause

# Hand-made OCI layout: one uncompressed layer, one config, one manifest.
python3 - "$TMP" "$OUT/oci" <<'PY'
import hashlib, json, os, shutil, sys
tmp, out = sys.argv[1:3]
blobs = os.path.join(out, "blobs", "sha256")
os.makedirs(blobs)

def put(data):
    d = hashlib.sha256(data).hexdigest()
    with open(os.path.join(blobs, d), "wb") as f:
        f.write(data)
    return "sha256:" + d, len(data)

layer = open(os.path.join(tmp, "layer.tar"), "rb").read()
layer_digest, layer_size = put(layer)
config = {
    "architecture": "riscv64",
    "os": "linux",
    "config": {
        "User": "65535:65535",
        "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],
        "Entrypoint": ["/pause"],
        "WorkingDir": "/",
    },
    "rootfs": {"type": "layers", "diff_ids": [layer_digest]},
}
cfg_digest, cfg_size = put(json.dumps(config).encode())
manifest = {
    "schemaVersion": 2,
    "mediaType": "application/vnd.oci.image.manifest.v1+json",
    "config": {"mediaType": "application/vnd.oci.image.config.v1+json",
               "digest": cfg_digest, "size": cfg_size},
    "layers": [{"mediaType": "application/vnd.oci.image.layer.v1.tar",
                "digest": layer_digest, "size": layer_size}],
}
m_digest, m_size = put(json.dumps(manifest).encode())
index = {"schemaVersion": 2, "manifests": [{
    "mediaType": "application/vnd.oci.image.manifest.v1+json",
    "digest": m_digest, "size": m_size,
    "platform": {"architecture": "riscv64", "os": "linux"}}]}
with open(os.path.join(out, "index.json"), "w") as f:
    json.dump(index, f)
with open(os.path.join(out, "oci-layout"), "w") as f:
    json.dump({"imageLayoutVersion": "1.0.0"}, f)
PY

skopeo copy "oci:$OUT/oci" "docker-archive:$OUT/pause.tar:$REF"
echo "built $OUT/pause.tar as $REF"
