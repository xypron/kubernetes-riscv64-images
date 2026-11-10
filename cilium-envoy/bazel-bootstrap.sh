#!/bin/bash
# Bootstrap Bazel 7.7.1 from the source distribution on riscv64.
# The release has no riscv64 binary and Ubuntu has only Bazel 4.2.3.
# Needs: openjdk-21-jdk-headless (not the default JDK 25), build-essential,
# zip, unzip, python3. No root is needed for the build itself.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="${1:-$HOME/bazel}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
[ -f bazel-7.7.1-dist.zip ] || curl -fsSL -O \
  https://github.com/bazelbuild/bazel/releases/download/7.7.1/bazel-7.7.1-dist.zip
rm -rf src
mkdir src
(cd src && unzip -q ../bazel-7.7.1-dist.zip)
cd src

# rules_java 7.6.5 has ":include/linux" for riscv64 (stray colon), so
# jni_md.h is not found.
cp "$HERE/rules_java_riscv64_jni.patch" third_party/
python3 - <<'PY'
p = "MODULE.bazel"
s = open(p).read()
old = 'single_version_override(\n    module_name = "rules_jvm_external",'
new = ('single_version_override(\n    module_name = "rules_java",\n'
       '    patch_strip = 1,\n'
       '    patches = ["//third_party:rules_java_riscv64_jni.patch"],\n)\n\n')
assert old in s
open(p, "w").write(s.replace(old, new + old, 1))
p = "BUILD"
s = open(p).read()
old = '        "//third_party:rules_jvm_external_6.0.patch",\n'
assert old in s
new = old + '        "//third_party:rules_java_riscv64_jni.patch",\n'
open(p, "w").write(s.replace(old, new, 1))
PY

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-riscv64
export PATH=$JAVA_HOME/bin:$PATH
# The bootstrap Bazel has no version information. bazel_features then
# assumes a development version and enables the Bazel 8 global "macro"
# (https://github.com/bazelbuild/bazel/issues/27349).
export BAZEL_DEV_VERSION_OVERRIDE=7.7.1
export EMBED_LABEL=7.7.1
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
ls -l output/bazel
