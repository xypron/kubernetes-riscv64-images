#!/bin/bash
# Push the riscv64 image tars to Docker Hub.
# Needs: skopeo. Log in first: skopeo login docker.io -u <user>
# Usage: HUBUSER=<user> [TARDIR=dir] [DRY=1] ./publish.sh [name...]
#   TARDIR  directory of the tars (default /home/llm/images)
#   DRY=1   only check that the tars can be read, push nothing
#   name    push only these hub repositories (default: all)
# Result: one line per image appended to published.tsv:
#   date, hub reference, digest, reference inside the tar
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
HUBUSER="${HUBUSER:?set HUBUSER to your Docker Hub user name}"
TARDIR="${TARDIR:-/home/llm/images}"
DRY="${DRY:-}"
WANT=" $* "

if [ -z "$DRY" ]; then
  skopeo login --get-login docker.io >/dev/null ||
    { echo "not logged in: skopeo login docker.io -u $HUBUSER" >&2; exit 1; }
fi

fail=0
while IFS=$'\t' read -r repo tar ref tag; do
  case "$repo" in ''|'#'*) continue ;; esac
  [ "$WANT" = "  " ] || case "$WANT" in *" $repo "*) ;; *) continue ;; esac
  dest="docker.io/$HUBUSER/$repo:$tag"
  if [ "$tar" = "-" ]; then
    echo "skip  $dest (already on Docker Hub)"
    continue
  fi
  case "$tar" in /*) file="$tar" ;; *) file="$TARDIR/$tar" ;; esac
  if [ ! -f "$file" ]; then
    echo "MISSING $file" >&2; fail=1; continue
  fi
  if [ -n "$DRY" ]; then
    arch=$(skopeo inspect --config "docker-archive:$file" |
      python3 -c 'import json,sys; print(json.load(sys.stdin)["architecture"])')
    echo "dry   $dest  <- $file ($arch)"
    continue
  fi
  echo "push  $dest  <- $file"
  skopeo copy "docker-archive:$file" "docker://$dest"
  digest=$(skopeo inspect --format '{{.Digest}}' "docker://$dest")
  printf '%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$dest" "$digest" "$ref" \
    >>"$HERE/published.tsv"
  echo "      $digest"
done <"$HERE/images.tsv"
exit $fail
