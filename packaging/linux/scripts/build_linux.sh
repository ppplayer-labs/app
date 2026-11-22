#!/bin/bash
set -euo pipefail

# Usage:
#   build_linux.sh [--build-flatpak] [--flatpak-manifest PATH] [PROJECT_ROOT]
#
# Environment variables:
#   PPPLAYER_BUILD_FLATPAK=1      Explicitly request an optional local Flatpak
#                                 bundle build (disabled by default so normal
#                                 Linux packaging never depends on unpublished
#                                 Flathub release URLs or conceals build errors).
#   PPPLAYER_FLATPAK_MANIFEST     Optional manifest override when building Flatpak.
BUILD_FLATPAK="${PPPLAYER_BUILD_FLATPAK:-0}"
FLATPAK_MANIFEST_OVERRIDE="${PPPLAYER_FLATPAK_MANIFEST:-}"
PROJECT_ROOT=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-flatpak)
            BUILD_FLATPAK="1"
            shift
            ;;
        --flatpak-manifest)
            if [ "$#" -lt 2 ]; then
                echo "Error: --flatpak-manifest requires a file path." >&2
                exit 1
            fi
            FLATPAK_MANIFEST_OVERRIDE="$2"
            shift 2
            ;;
        --flatpak-manifest=*)
            FLATPAK_MANIFEST_OVERRIDE="${1#*=}"
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [ -n "$PROJECT_ROOT" ]; then
                echo "Error: Unexpected extra argument: $1" >&2
                exit 1
            fi
            PROJECT_ROOT="$1"
            shift
            ;;
    esac
done

# Default to current directory if not specified
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
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
flutter pub get
flutter build linux --release

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

# 3. Build Portable tar.gz (including upstream desktop metadata & 512x512 icon)
TAR_NAME="PPPlayer-Linux-x86_64.tar.gz"
echo "Building portable tarball: $TAR_NAME"
TARBALL_STAGE_DIR="build/linux/x64/tarball/PPPlayer"
rm -rf "$TARBALL_STAGE_DIR"
mkdir -p "$TARBALL_STAGE_DIR"
cp -r "$BUNDLE_DIR/"* "$TARBALL_STAGE_DIR/"
chmod 0755 "$TARBALL_STAGE_DIR/ppplayer"
if [ -f "$TARBALL_STAGE_DIR/lib/flutter_chromium_webview_subprocess" ]; then
    chmod 0755 "$TARBALL_STAGE_DIR/lib/flutter_chromium_webview_subprocess"
fi

# Package upstream desktop entry, AppStream MetaInfo, and 512x512 icon inside
# standard share/ paths while keeping executable and lib/ in their portable root.
for meta_file in \
    "packaging/linux/flatpak/com.ppplayer.PPPlayer.desktop" \
    "packaging/linux/flatpak/com.ppplayer.PPPlayer.metainfo.xml" \
    "packaging/linux/flatpak/com.ppplayer.PPPlayer.png"; do
    if [ ! -f "$meta_file" ]; then
        echo "Error: Missing required upstream desktop metadata asset: $meta_file" >&2
        exit 1
    fi
done
mkdir -p \
    "$TARBALL_STAGE_DIR/share/applications" \
    "$TARBALL_STAGE_DIR/share/metainfo" \
    "$TARBALL_STAGE_DIR/share/icons/hicolor/512x512/apps"
install -m 0644 "packaging/linux/flatpak/com.ppplayer.PPPlayer.desktop" \
    "$TARBALL_STAGE_DIR/share/applications/com.ppplayer.PPPlayer.desktop"
install -m 0644 "packaging/linux/flatpak/com.ppplayer.PPPlayer.metainfo.xml" \
    "$TARBALL_STAGE_DIR/share/metainfo/com.ppplayer.PPPlayer.metainfo.xml"
install -m 0644 "packaging/linux/flatpak/com.ppplayer.PPPlayer.png" \
    "$TARBALL_STAGE_DIR/share/icons/hicolor/512x512/apps/com.ppplayer.PPPlayer.png"

if tar --help 2>&1 | grep -q -- '--sort'; then
    tar --sort=name --owner=0 --group=0 --numeric-owner \
        -czf "$DIST_DIR/$TAR_NAME" -C "build/linux/x64/tarball" "PPPlayer"
else
    tar -czf "$DIST_DIR/$TAR_NAME" -C "build/linux/x64/tarball" "PPPlayer"
fi

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
mkdir -p "$DEB_BUILD_DIR/etc/apparmor.d"

# Copy App Files
cp -r "$BUNDLE_DIR/"* "$DEB_BUILD_DIR/opt/ppplayer/"
if [ -f "$DEB_BUILD_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess" ]; then
    chmod +x "$DEB_BUILD_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess"
fi

# Create Launcher symlink
ln -s /opt/ppplayer/ppplayer "$DEB_BUILD_DIR/usr/bin/ppplayer"

# Copy Desktop and Icon
cp packaging/linux/com.ppplayer.app.desktop "$DEB_BUILD_DIR/usr/share/applications/"
cp assets/logo.png "$DEB_BUILD_DIR/usr/share/icons/hicolor/256x256/apps/com.ppplayer.app.png"

# Install a narrowly scoped AppArmor profile permitting unprivileged user
# namespaces ONLY for PPPlayer's installed binaries so Chromium's native
# sandbox works on Ubuntu 24.04+ without relaxing system-wide sysctl settings.
cat <<'EOF' > "$DEB_BUILD_DIR/etc/apparmor.d/ppplayer"
abi <abi/4.0>,
include <tunables/global>

profile ppplayer /opt/ppplayer/{ppplayer,lib/flutter_chromium_webview_subprocess} flags=(unconfined) {
  userns,

  include if exists <local/ppplayer>
}
EOF

cat <<'EOF' > "$DEB_BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
if [ "$1" = "configure" ] && command -v apparmor_parser >/dev/null 2>&1 && [ -f /etc/apparmor.d/ppplayer ]; then
    if [ -d /sys/kernel/security/apparmor ]; then
        apparmor_parser -r -T -W /etc/apparmor.d/ppplayer || true
    fi
fi
exit 0
EOF
chmod 0755 "$DEB_BUILD_DIR/DEBIAN/postinst"

cat <<'EOF' > "$DEB_BUILD_DIR/DEBIAN/postrm"
#!/bin/sh
set -e
if [ "$1" = "purge" ] || [ "$1" = "remove" ]; then
    if command -v apparmor_parser >/dev/null 2>&1 && [ -d /sys/kernel/security/apparmor ]; then
        apparmor_parser -R /etc/apparmor.d/ppplayer 2>/dev/null || true
    fi
fi
exit 0
EOF
chmod 0755 "$DEB_BUILD_DIR/DEBIAN/postrm"

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
Depends: libgtk-3-0, libgl1, libegl1, libx11-6, libxcb1, libstdc++6, libvulkan1, libsecret-1-0, libmpv1 | libmpv2, libepoxy0
EOF

chmod -R 755 "$DEB_BUILD_DIR/opt/ppplayer" "$DEB_BUILD_DIR/usr"
chmod 0644 "$DEB_BUILD_DIR/etc/apparmor.d/ppplayer" "$DEB_BUILD_DIR/DEBIAN/control"
chmod 0755 "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/DEBIAN/postinst" "$DEB_BUILD_DIR/DEBIAN/postrm"
# Workaround for WSL filesystem permission issues with dpkg-deb:
# Build the deb in an isolated temp directory, preserving symlinks, then move it out.
DEB_TMP_PARENT=$(mktemp -d)
DEB_TMP_DIR="$DEB_TMP_PARENT/ppplayer_${DEB_VERSION}_amd64"
cp -R -P "$DEB_BUILD_DIR" "$DEB_TMP_DIR"
chmod 0755 "$DEB_TMP_DIR/DEBIAN" "$DEB_TMP_DIR/DEBIAN/postinst" "$DEB_TMP_DIR/DEBIAN/postrm"
chmod 0644 "$DEB_TMP_DIR/DEBIAN/control" "$DEB_TMP_DIR/etc/apparmor.d/ppplayer"
dpkg-deb --build "$DEB_TMP_DIR"
mv "$DEB_TMP_DIR.deb" "$DIST_DIR/$DEB_NAME"
rm -rf "$DEB_TMP_PARENT"

# 5. Build AppImage
APPIMAGE_NAME="PPPlayer-Linux-x86_64.AppImage"
echo "Building AppImage: $APPIMAGE_NAME"
APPDIR="build/linux/x64/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy bundle
cp -r "$BUNDLE_DIR/"* "$APPDIR/"
if [ -f "$APPDIR/lib/flutter_chromium_webview_subprocess" ]; then
    chmod +x "$APPDIR/lib/flutter_chromium_webview_subprocess"
fi

# Copy Desktop and Icon into root of AppDir
cp packaging/linux/com.ppplayer.app.desktop "$APPDIR/"
cp assets/logo.png "$APPDIR/com.ppplayer.app.png"
cp assets/logo.png "$APPDIR/.DirIcon"

# Create AppRun
cat <<'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH}"
export CEF_SYSTEM_MEDIA_CONTROLS="${CEF_SYSTEM_MEDIA_CONTROLS:-0}"
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

# 6. Prepare Flathub / Flatpak Metadata & Optional Local Flatpak Bundle Build
echo "Preparing Flathub / Flatpak metadata artifacts..."
FLATPAK_DIST_DIR="$DIST_DIR/flatpak"
rm -rf "$FLATPAK_DIST_DIR"
mkdir -p "$FLATPAK_DIST_DIR"

if command -v sha256sum &> /dev/null; then
    TAR_SHA256=$(sha256sum "$DIST_DIR/$TAR_NAME" | awk '{print $1}')
else
    TAR_SHA256=$(shasum -a 256 "$DIST_DIR/$TAR_NAME" | awk '{print $1}')
fi
echo "Tarball SHA-256 for Flatpak staging: $TAR_SHA256"

# Copy upstream Flatpak metadata assets
cp packaging/linux/flatpak/com.ppplayer.PPPlayer.desktop "$FLATPAK_DIST_DIR/"
cp packaging/linux/flatpak/com.ppplayer.PPPlayer.metainfo.xml "$FLATPAK_DIST_DIR/"
cp packaging/linux/flatpak/com.ppplayer.PPPlayer.png "$FLATPAK_DIST_DIR/"
for patch_file in packaging/linux/flatpak/*.patch; do
    if [ -f "$patch_file" ]; then
        cp "$patch_file" "$FLATPAK_DIST_DIR/"
    fi
done

# Deterministically update ONLY the PPPlayer archive URL and SHA-256 while
# preserving every third-party dependency checksum unchanged.
MANIFEST_UPDATER="$SCRIPT_DIR/update_flatpak_manifest.py"
if [ ! -f "$MANIFEST_UPDATER" ]; then
    MANIFEST_UPDATER="packaging/linux/scripts/update_flatpak_manifest.py"
fi
python3 "$MANIFEST_UPDATER" \
    --input "packaging/linux/flatpak/com.ppplayer.PPPlayer.yml" \
    --output "$FLATPAK_DIST_DIR/com.ppplayer.PPPlayer.yml" \
    --version "$VERSION" \
    --sha256 "$TAR_SHA256" \
    --archive-name "$TAR_NAME"

# Optional Flatpak bundle build:
#   - Not requested (default): skip normally; Linux packaging succeeds.
#   - Explicitly requested + tooling missing: fail with a clear nonzero exit.
#   - Explicitly requested + tooling available: execute strictly (never mask errors),
#     preserve logs, verify non-empty output bundle, and include in SHA256SUMS.
FLATPAK_BUNDLE_NAME="PPPlayer-Linux-x86_64.flatpak"
if [ "$BUILD_FLATPAK" != "1" ]; then
    echo "Flatpak bundle build not requested (pass --build-flatpak or set PPPLAYER_BUILD_FLATPAK=1 to enable); staged Flatpak metadata only."
else
    MISSING_FLATPAK_TOOLS=()
    if ! command -v flatpak-builder &> /dev/null; then
        MISSING_FLATPAK_TOOLS+=("flatpak-builder")
    fi
    if ! command -v flatpak &> /dev/null; then
        MISSING_FLATPAK_TOOLS+=("flatpak")
    fi
    if [ "${#MISSING_FLATPAK_TOOLS[@]}" -gt 0 ]; then
        echo "Error: Flatpak build was explicitly requested, but required tooling is missing: ${MISSING_FLATPAK_TOOLS[*]}." >&2
        exit 1
    fi

    FLATPAK_MANIFEST_TO_BUILD="${FLATPAK_MANIFEST_OVERRIDE:-$FLATPAK_DIST_DIR/com.ppplayer.PPPlayer.yml}"
    if [ ! -f "$FLATPAK_MANIFEST_TO_BUILD" ]; then
        echo "Error: Requested Flatpak manifest does not exist: $FLATPAK_MANIFEST_TO_BUILD" >&2
        exit 1
    fi
    echo "Building Flatpak bundle ($FLATPAK_BUNDLE_NAME) from $FLATPAK_MANIFEST_TO_BUILD..."
    FLATPAK_BUILD_DIR="build/linux/x64/flatpak"
    rm -rf "$FLATPAK_BUILD_DIR"
    mkdir -p "$FLATPAK_BUILD_DIR"
    flatpak-builder --force-clean --repo="$FLATPAK_BUILD_DIR/repo" \
        "$FLATPAK_BUILD_DIR/build" "$FLATPAK_MANIFEST_TO_BUILD" \
        2>&1 | tee "$FLATPAK_BUILD_DIR/flatpak-builder.log"
    flatpak build-bundle "$FLATPAK_BUILD_DIR/repo" \
        "$DIST_DIR/$FLATPAK_BUNDLE_NAME" com.ppplayer.PPPlayer \
        2>&1 | tee "$FLATPAK_BUILD_DIR/flatpak-bundle.log"
    if [ ! -s "$DIST_DIR/$FLATPAK_BUNDLE_NAME" ]; then
        echo "Error: Flatpak build-bundle did not produce a non-empty bundle: $DIST_DIR/$FLATPAK_BUNDLE_NAME" >&2
        exit 1
    fi
fi

# 7. Generate Checksums
echo "Generating Checksums..."
cd "$DIST_DIR"
HASH_TARGETS=("$APPIMAGE_NAME" "$DEB_NAME" "$TAR_NAME")
if [ -f "$FLATPAK_BUNDLE_NAME" ]; then
    HASH_TARGETS+=("$FLATPAK_BUNDLE_NAME")
fi
if command -v sha256sum &> /dev/null; then
    sha256sum "${HASH_TARGETS[@]}" > SHA256SUMS
else
    shasum -a 256 "${HASH_TARGETS[@]}" > SHA256SUMS
fi
cd ..

echo "Done! Artifacts are in $DIST_DIR/"
ls -lh "$DIST_DIR/$APPIMAGE_NAME" "$DIST_DIR/$DEB_NAME" "$DIST_DIR/$TAR_NAME" "$DIST_DIR/SHA256SUMS"
if [ -f "$DIST_DIR/$FLATPAK_BUNDLE_NAME" ]; then
    ls -lh "$DIST_DIR/$FLATPAK_BUNDLE_NAME"
fi
ls -lh "$FLATPAK_DIST_DIR"

