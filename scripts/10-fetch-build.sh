#!/bin/bash
# Clone orangepi-build at a pinned commit and apply the native-arm64 patch/fixes.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$HERE/orangepi-build}"
COMMIT="${COMMIT:-a05b3b4d5fc0dd4eb859f64c8a60f9b2c9e33cb1}"
if [ ! -d "$WORK" ]; then
  git clone https://github.com/orangepi-xunlong/orangepi-build.git "$WORK"
fi
cd "$WORK"
git fetch --all --tags
git checkout "$COMMIT"
if ! grep -q "native arm64 build support" scripts/general.sh 2>/dev/null; then
  patch -p1 < "$HERE/patches/native-arm64.patch"
fi
"$HERE/scripts/apply-fixes.sh" "$WORK"
echo "==> orangepi-build ready at $WORK (patched for native arm64)"
