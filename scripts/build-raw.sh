#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../versions.env
source "$ROOT_DIR/versions.env"

BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build}"
SOURCE_DIR="$BUILD_DIR/metacubexd"
STAGE_DIR="$BUILD_DIR/raw"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
OUTPUT_PATH="$DIST_DIR/mihomo_zimaos.raw"

for command_name in curl git gzip mksquashfs node pnpm sha256sum tar xz; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "missing required command: $command_name" >&2
    exit 1
  }
done

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$SOURCE_DIR" "$STAGE_DIR" "$DOWNLOAD_DIR" "$DIST_DIR"
cp -a "$ROOT_DIR/raw/." "$STAGE_DIR/"

git clone --filter=blob:none --depth 1 --branch "$METACUBEXD_VERSION" \
  https://github.com/MetaCubeX/metacubexd.git "$SOURCE_DIR"

actual_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ "$actual_commit" != "$METACUBEXD_COMMIT" ]]; then
  echo "MetaCubeXD commit mismatch: expected $METACUBEXD_COMMIT, got $actual_commit" >&2
  exit 1
fi

pushd "$SOURCE_DIR" >/dev/null
export HUSKY=0
corepack enable
pnpm install --frozen-lockfile
pnpm --filter @metacubexd/ui generate
pnpm --filter @metacubexd/server... build
popd >/dev/null

mkdir -p \
  "$STAGE_DIR/usr/bin" \
  "$STAGE_DIR/usr/lib/mihomo-zimaos" \
  "$STAGE_DIR/usr/share/licenses/mihomo-zimaos"

curl -fL --retry 3 --retry-all-errors \
  "https://github.com/MetaCubeX/mihomo/releases/download/$MIHOMO_VERSION/$MIHOMO_ASSET" \
  -o "$DOWNLOAD_DIR/$MIHOMO_ASSET"
echo "$MIHOMO_SHA256  $DOWNLOAD_DIR/$MIHOMO_ASSET" | sha256sum -c -
gzip -dc "$DOWNLOAD_DIR/$MIHOMO_ASSET" >"$STAGE_DIR/usr/bin/mihomo"
chmod 0755 "$STAGE_DIR/usr/bin/mihomo"

curl -fL --retry 3 --retry-all-errors \
  "https://nodejs.org/dist/$NODE_VERSION/$NODE_ASSET" \
  -o "$DOWNLOAD_DIR/$NODE_ASSET"
echo "$NODE_SHA256  $DOWNLOAD_DIR/$NODE_ASSET" | sha256sum -c -
tar -xJf "$DOWNLOAD_DIR/$NODE_ASSET" -C "$DOWNLOAD_DIR"
cp "$DOWNLOAD_DIR/${NODE_ASSET%.tar.xz}/bin/node" "$STAGE_DIR/usr/lib/mihomo-zimaos/node"
chmod 0755 "$STAGE_DIR/usr/lib/mihomo-zimaos/node"

cp -a "$SOURCE_DIR/apps/server/.output" "$STAGE_DIR/usr/lib/mihomo-zimaos/server"
cp -a "$SOURCE_DIR/packages/ui/.output/public" "$STAGE_DIR/usr/lib/mihomo-zimaos/ui-dist"
cp "$SOURCE_DIR/packages/ui/public/favicon.ico" \
  "$STAGE_DIR/usr/share/casaos/www/modules/mihomo_zimaos/appicon.ico"

cp "$SOURCE_DIR/LICENSE" "$STAGE_DIR/usr/share/licenses/mihomo-zimaos/METACUBEXD-LICENSE"
curl -fsSL "https://raw.githubusercontent.com/MetaCubeX/mihomo/$MIHOMO_VERSION/LICENSE" \
  -o "$STAGE_DIR/usr/share/licenses/mihomo-zimaos/MIHOMO-LICENSE"
cp "$DOWNLOAD_DIR/${NODE_ASSET%.tar.xz}/LICENSE" \
  "$STAGE_DIR/usr/share/licenses/mihomo-zimaos/NODEJS-LICENSE"

sed -i "s/@PACKAGE_VERSION@/$PACKAGE_VERSION/g" \
  "$STAGE_DIR/usr/lib/extension-release.d/extension-release.mihomo_zimaos"

chmod 0755 \
  "$STAGE_DIR/usr/lib/mihomo-zimaos/prepare" \
  "$STAGE_DIR/usr/lib/mihomo-zimaos/run"

mksquashfs "$STAGE_DIR" "$OUTPUT_PATH" -noappend
sha256sum "$OUTPUT_PATH" >"$OUTPUT_PATH.sha256"

echo "built $OUTPUT_PATH"
