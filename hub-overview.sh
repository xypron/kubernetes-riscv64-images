#!/bin/bash
# Set the description and the overview of the Docker Hub repositories.
# The text is generated from images.tsv, so it names the published tag.
# Needs: curl, python3. Use a personal access token with write
# permission (https://hub.docker.com/settings/personal-access-tokens).
# Usage: HUBUSER=<user> HUBTOKEN=<token> [DRY=1] ./hub-overview.sh [name...]
#   DRY=1   only print the texts, change nothing (no login needed)
#   name    only these hub repositories (default: all)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HUBUSER="${HUBUSER:?set HUBUSER to your Docker Hub user name}"
DRY="${DRY:-}"
WANT=" $* "
SITE="https://github.com/xypron/kubernetes-riscv64-images"

if [ -z "$DRY" ]; then
  HUBTOKEN="${HUBTOKEN:?set HUBTOKEN to a Docker Hub access token}"
  jwt=$(python3 -c '
import json, sys, urllib.request
req = urllib.request.Request(
    "https://hub.docker.com/v2/users/login",
    json.dumps({"username": sys.argv[1], "password": sys.argv[2]}).encode(),
    {"Content-Type": "application/json"})
print(json.load(urllib.request.urlopen(req))["token"])
' "$HUBUSER" "$HUBTOKEN")
fi

short() {
  case "$1" in
  pause) echo "Kubernetes pause 3.10 for riscv64" ;;
  coredns) echo "CoreDNS 1.14.7 rock for riscv64 (Canonical Kubernetes)" ;;
  cilium) echo "Cilium 1.20.0 with embedded Envoy for riscv64 (Canonical Kubernetes)" ;;
  cilium-operator-generic) echo "Cilium operator 1.20.0 for riscv64 (Canonical Kubernetes)" ;;
  metrics-server) echo "metrics-server 0.9.0 rock for riscv64 (Canonical Kubernetes)" ;;
  rawfile-localpv) echo "rawfile-localpv 0.8.3 for riscv64 (Canonical Kubernetes)" ;;
  csi-*) echo "${1} CSI sidecar rock for riscv64 (Canonical Kubernetes)" ;;
  metallb-*) echo "MetalLB ${1#metallb-} v0.16.1 for riscv64 (Canonical Kubernetes)" ;;
  frr) echo "FRR 10.4.3 rock for riscv64 (Canonical Kubernetes)" ;;
  frr-k8s) echo "frr-k8s v0.0.25 rock for riscv64 (Canonical Kubernetes)" ;;
  *) echo "riscv64 image for Canonical Kubernetes" ;;
  esac
}

long() {
  local repo="$1" ref="$2" tag="$3"
  cat <<EOF
# $repo for riscv64

Unofficial riscv64 build of \`$ref\` for the
[Canonical Kubernetes](https://github.com/canonical/k8s-snap) snap. It is
not an image of Canonical.

Tag: \`$tag\`. A tag is never changed after it is published.

Use \`fetch.sh\` of the repository to pull the images and to tag them with the
names that the snap asks for. Do not run the image by hand.

Recipes, patches, build scripts, the published digests and the
instructions: $SITE
EOF
  case "$repo" in
  cilium)
    cat <<EOF

The agent starts the Envoy proxy of its own image
(\`external-envoy-proxy=false\`). Tags that end in \`riscv64.1\` do not contain
\`cilium-envoy\`, so gateway and ingress do not work with them. Use a later
tag.
EOF
    ;;
  esac
}

fail=0
while IFS=$'\t' read -r repo tar ref tag; do
  case "$repo" in ''|'#'*) continue ;; esac
  [ "$WANT" = "  " ] || case "$WANT" in *" $repo "*) ;; *) continue ;; esac
  desc=$(short "$repo")
  text=$(long "$repo" "$ref" "$tag")
  if [ -n "$DRY" ]; then
    echo "=== $HUBUSER/$repo: $desc (${#desc} characters)"
    echo "$text"
    echo
    continue
  fi
  body=$(python3 -c '
import json, sys
print(json.dumps({"description": sys.argv[1], "full_description": sys.argv[2]}))
' "$desc" "$text")
  code=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
    -H "Authorization: JWT $jwt" -H 'Content-Type: application/json' \
    -d "$body" "https://hub.docker.com/v2/repositories/$HUBUSER/$repo/")
  if [ "$code" = 200 ]; then
    echo "ok    $HUBUSER/$repo"
  else
    echo "FAIL  $HUBUSER/$repo (HTTP $code)" >&2
    fail=1
  fi
done <"$HERE/images.tsv"
exit $fail
