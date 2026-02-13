#!/usr/bin/env bash
set -euo pipefail

APP_NAME="sdui"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APPDIR="$BUILD_DIR/${APP_NAME}.AppDir"
APPIMAGE_TOOL="$BUILD_DIR/appimagetool-x86_64.AppImage"
BUNDLE_DIR="$BUILD_DIR/linux/x64/release/bundle"

echo "==> Building Flutter linux release..."
cd "$PROJECT_DIR"
flutter build linux --release

echo "==> Preparing AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"

# Copy Flutter bundle
cp -r "$BUNDLE_DIR"/. "$APPDIR/usr/bin/"

# Copy icon
cp "$PROJECT_DIR/web/icons/Icon-512.png" "$APPDIR/${APP_NAME}.png"

# Create .desktop file
cat > "$APPDIR/${APP_NAME}.desktop" <<EOF
[Desktop Entry]
Name=SDUI
Exec=sdui
Icon=sdui
Type=Application
Categories=Utility;
EOF

# Create AppRun
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/sdui" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
if [ ! -f "$APPIMAGE_TOOL" ]; then
    echo "==> Downloading appimagetool..."
    wget -q -O "$APPIMAGE_TOOL" \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOL"
fi

echo "==> Building AppImage..."
ARCH=x86_64 "$APPIMAGE_TOOL" "$APPDIR" "$BUILD_DIR/${APP_NAME}-x86_64.AppImage"

echo ""
echo "Done! AppImage created at:"
echo "  $BUILD_DIR/${APP_NAME}-x86_64.AppImage"
