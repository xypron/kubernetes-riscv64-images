#!/bin/bash
# Build Bazel 7.7.2 for riscv64 from the source distribution and install
# it as /usr/local/bin/bazel. Needs no Bazel. Called by rockcraft.yaml
# (part bazel), the patch files are next to this script.
# Needs: openjdk-21-jdk-headless build-essential zip unzip python3 patch
# curl
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION=7.7.2
SHA256=f40c88b52da292746b6ccf742a0e3f0897a7e4ac24d0143b860f1857f220d5ec
WORK="${WORK:-$(mktemp -d)}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-riscv64}"

cd "$WORK"
curl -fsSL -O \
  "https://github.com/bazelbuild/bazel/releases/download/$VERSION/bazel-$VERSION-dist.zip"
echo "$SHA256  bazel-$VERSION-dist.zip" | sha256sum -c -
mkdir src
cd src
unzip -q "../bazel-$VERSION-dist.zip"

# 1. rules_java 7.6.5 has ":include/linux" for riscv64 (stray colon), so
#    jni_md.h is not found.
# 2. abseil-cpp 20230125.1 uses rdcycle on riscv64, which user space may
#    not use since Linux 6.6 (SIGILL). Upstream abseil commit 7335a36d0b5c
#    removes it.
cp "$HERE/bazel-rules-java-jni.patch" third_party/rules_java_riscv64_jni.patch
cp "$HERE/bazel-abseil-no-rdcycle.patch" \
  third_party/abseil_riscv64_cycleclock.patch
python3 - <<'PY'
p = "MODULE.bazel"
s = open(p).read()
old = 'single_version_override(\n    module_name = "rules_jvm_external",'
new = (
    'single_version_override(\n    module_name = "rules_java",\n'
    '    patch_strip = 1,\n'
    '    patches = ["//third_party:rules_java_riscv64_jni.patch"],\n)\n\n'
    'single_version_override(\n    module_name = "abseil-cpp",\n'
    '    patch_strip = 1,\n'
    '    patches = ["//third_party:abseil_riscv64_cycleclock.patch"],\n)\n\n')
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new + old, 1))
p = "BUILD"
s = open(p).read()
old = '        "//third_party:rules_jvm_external_6.0.patch",\n'
assert s.count(old) == 1
new = (old + '        "//third_party:rules_java_riscv64_jni.patch",\n'
       '        "//third_party:abseil_riscv64_cycleclock.patch",\n')
open(p, "w").write(s.replace(old, new, 1))
PY

export PATH="$JAVA_HOME/bin:$PATH"
# The bootstrap Bazel has no version information. bazel_features then
# assumes a development version and enables the Bazel 8 global "macro"
# (https://github.com/bazelbuild/bazel/issues/27349).
export BAZEL_DEV_VERSION_OVERRIDE="$VERSION"
export EMBED_LABEL="$VERSION"
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
install -m 0755 output/bazel /usr/local/bin/bazel
cd /
rm -rf "$WORK" /root/.cache/bazel
bazel --version
