#!/bin/bash
# Download the riscv64 images from Docker Hub into the containerd of the
# k8s snap, under the names the snap and its charts ask for.
# Run on the riscv64 node after 'sudo k8s bootstrap' (containerd of the
# snap runs from then on) and BEFORE the cluster features are enabled:
# if kubelet pulls first, the CRI caches the index without riscv64
# (PLAN.md 7.6). Bootstrap with network, dns, gateway and metrics-server
# disabled, see README.md.
# Needs: skopeo, sudo. The images must be public.
# Usage: [HUBUSER=<user>] [DRY=1] ./fetch.sh [name...]
#   HUBUSER Docker Hub user, default xypron
#   DRY=1   only check that the images exist, import nothing
# If published.tsv has a digest for an image, that digest is fetched.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HUBUSER="${HUBUSER:-xypron}"
DRY="${DRY:-}"
WANT=" $* "
CTR=(sudo /snap/k8s/current/bin/ctr
  --address /run/containerd/containerd.sock -n k8s.io)
SOCK=/run/containerd/containerd.sock
if [ -z "$DRY" ] && ! sudo test -S "$SOCK"; then
  cat >&2 <<MSG
containerd of the k8s snap is not running ($SOCK is missing).
On a new node it starts with 'sudo k8s bootstrap'. Bootstrap first with
the features disabled and the pause image of Docker Hub (README.md),
then run this script.
MSG
  exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
while IFS=$'\t' read -r repo tar ref tag; do
  case "$repo" in ''|'#'*) continue ;; esac
  [ "$WANT" = "  " ] || case "$WANT" in *" $repo "*) ;; *) continue ;; esac
  src="docker.io/$HUBUSER/$repo:$tag"
  if [ -f "$HERE/published.tsv" ]; then
    digest=$(awk -F'\t' -v d="$src" '$2 == d { x = $3 } END { print x }' \
      "$HERE/published.tsv")
    [ -z "$digest" ] || src="docker.io/$HUBUSER/$repo@$digest"
  fi
  if [ -n "$DRY" ]; then
    if skopeo inspect --override-arch riscv64 --override-os linux \
         --format '{{.Architecture}} {{.Digest}}' "docker://$src"; then
      echo "ok    $src"
    else
      echo "FAIL  $src" >&2; fail=1
    fi
    continue
  fi
  echo "fetch $src -> $ref"
  skopeo copy --override-arch riscv64 --override-os linux \
    "docker://$src" "docker-archive:$TMP/img.tar:$ref" || { fail=1; continue; }
  "${CTR[@]}" images import "$TMP/img.tar" || fail=1
  rm -f "$TMP/img.tar"
done <"$HERE/images.tsv"
exit $fail
