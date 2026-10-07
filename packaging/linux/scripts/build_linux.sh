#!/bin/bash
set -e

# Default to current directory if not specified
PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

if [ ! -f "pubspec.yaml" ]; then
    echo "Error: Must be run from the Flutter project root."
    exit 1
fi

# Determine version
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //g' | tr -d ' ' | tr -d '\r' | awk -F'+' '{print $1}')
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | awk -F'+' '{print $2}' | tr -d ' ' | tr -d '\r')
if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER="1"
fi
# Debian version format: 1.2.3-1
DEB_VERSION="${VERSION}-${BUILD_NUMBER}"

echo "Building PPPlayer Version $VERSION (Debian: $DEB_VERSION)"

# 1. Build Flutter Linux release
echo "Building Flutter Linux release..."
# flutter pub get
# flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Flutter build failed, bundle directory not found."
    exit 1
fi

# 2. Strip libcef.so to save ~1GB of space
CEF_PATH="$BUNDLE_DIR/lib/libcef.so"
if [ -f "$CEF_PATH" ]; then
    echo "Stripping $CEF_PATH..."
    strip --strip-unneeded "$CEF_PATH" || true
fi

# Prepare output directory
DIST_DIR="dist"
mkdir -p "$DIST_DIR"

# 3. Build Portable tar.gz
TAR_NAME="PPPlayer-Linux-x86_64.tar.gz"
echo "Building portable tarball: $TAR_NAME"
mkdir -p "build/linux/x64/tarball/PPPlayer"
cp -r "$BUNDLE_DIR/"* "build/linux/x64/tarball/PPPlayer/"
tar -czf "$DIST_DIR/$TAR_NAME" -C "build/linux/x64/tarball" "PPPlayer"

# 4. Build Debian Package
DEB_NAME="ppplayer_${DEB_VERSION}_amd64.deb"
echo "Building Debian package: $DEB_NAME"
DEB_BUILD_DIR="build/linux/x64/deb/ppplayer_${DEB_VERSION}_amd64"
rm -rf "$DEB_BUILD_DIR"
mkdir -p "$DEB_BUILD_DIR/DEBIAN"
mkdir -p "$DEB_BUILD_DIR/opt/ppplayer"
mkdir -p "$DEB_BUILD_DIR/usr/bin"
mkdir -p "$DEB_BUILD_DIR/usr/share/applications"
mkdir -p "$DEB_BUILD_DIR/usr/share/icons/hicolor/256x256/apps"

# Copy App Files
cp -r "$BUNDLE_DIR/"* "$DEB_BUILD_DIR/opt/ppplayer/"

# Create Launcher symlink
ln -s /opt/ppplayer/ppplayer "$DEB_BUILD_DIR/usr/bin/ppplayer"

# Copy Desktop and Icon
cp packaging/linux/com.ppplayer.app.desktop "$DEB_BUILD_DIR/usr/share/applications/"
cp assets/logo.png "$DEB_BUILD_DIR/usr/share/icons/hicolor/256x256/apps/com.ppplayer.app.png"

# Generate control file
cat <<EOF > "$DEB_BUILD_DIR/DEBIAN/control"
Package: ppplayer
Version: $DEB_VERSION
Section: video
Priority: optional
Architecture: amd64
Maintainer: Lucas Veneno
Description: Media player powered by Lucas Veneno.
 PPPlayer is a Flutter media player for music discovery, local music and video libraries, network streams, and playlists.
Depends: libgtk-3-0, libgl1, libegl1, libx11-6, libxcb1, libstdc++6, libvulkan1
EOF

chmod -R 755 "$DEB_BUILD_DIR"
# Workaround for WSL filesystem permission issues with dpkg-deb:
# Build the deb in /tmp, then move it to the output directory.
cp -r "$DEB_BUILD_DIR" "/tmp/ppplayer_deb_build"
chmod -R 0755 "/tmp/ppplayer_deb_build"
dpkg-deb --build "/tmp/ppplayer_deb_build"
mv "/tmp/ppplayer_deb_build.deb" "$DIST_DIR/$DEB_NAME"
rm -rf "/tmp/ppplayer_deb_build"

# 5. Build AppImage
APPIMAGE_NAME="PPPlayer-Linux-x86_64.AppImage"
echo "Building AppImage: $APPIMAGE_NAME"
APPDIR="build/linux/x64/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy bundle
cp -r "$BUNDLE_DIR/"* "$APPDIR/"

# Copy Desktop and Icon into root of AppDir
cp packaging/linux/com.ppplayer.app.desktop "$APPDIR/"
cp assets/logo.png "$APPDIR/com.ppplayer.app.png"
cp assets/logo.png "$APPDIR/.DirIcon"

# Create AppRun
cat <<'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/ppplayer" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
if ! command -v appimagetool &> /dev/null; then
    if [ ! -f "appimagetool-x86_64.AppImage" ]; then
        echo "Downloading appimagetool..."
        wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        chmod +x appimagetool-x86_64.AppImage
    fi
    APPIMAGETOOL="./appimagetool-x86_64.AppImage --appimage-extract-and-run"
else
    APPIMAGETOOL="appimagetool"
fi

# Run appimagetool
# ARCH=x86_64 required for appimagetool to set the right architecture internally
ARCH=x86_64 $APPIMAGETOOL "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"

# 6. Generate Checksums
echo "Generating Checksums..."
cd "$DIST_DIR"
# Make sure we only hash the newly generated Linux artifacts (in case old macOS dmg are there, though dist/ has it, let's specify)
sha256sum "$APPIMAGE_NAME" "$DEB_NAME" "$TAR_NAME" > SHA256SUMS
cd ..

echo "Done! Artifacts are in $DIST_DIR/"
ls -lh "$DIST_DIR/$APPIMAGE_NAME" "$DIST_DIR/$DEB_NAME" "$DIST_DIR/$TAR_NAME" "$DIST_DIR/SHA256SUMS"
