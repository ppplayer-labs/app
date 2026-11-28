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

# 3. Build Portable tar.gz (including bundled libmpv + transitive non-core libs,
#    upstream desktop metadata, 512x512 icon, and sandbox preflight wrapper)
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

PORTABLE_BUNDLER="$SCRIPT_DIR/bundle_linux_portable_libs.py"
if [ ! -f "$PORTABLE_BUNDLER" ]; then
    PORTABLE_BUNDLER="packaging/linux/scripts/bundle_linux_portable_libs.py"
fi
if [ -f "$PORTABLE_BUNDLER" ]; then
    echo "Bundling portable native libraries (libmpv + compatible transitive deps) into tarball..."
    python3 "$PORTABLE_BUNDLER" --bundle-dir "$TARBALL_STAGE_DIR"
fi

# Portable launcher wrapper with CWD-independent library resolution and
# non-destructive Ubuntu AppArmor user-namespace diagnostic for Chromium/CEF.
cat <<'EOF' > "$TARBALL_STAGE_DIR/ppplayer-portable"
#!/bin/sh
set -eu
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
if [ -f "${HERE}/lib/libmpv.so.2" ] && [ -z "${LIBMPV_LIBRARY_PATH:-}" ]; then
    export LIBMPV_LIBRARY_PATH="${HERE}/lib/libmpv.so.2"
fi
export CEF_SYSTEM_MEDIA_CONTROLS="${CEF_SYSTEM_MEDIA_CONTROLS:-0}"

# Non-destructive preflight diagnostic: launching PPPlayer and local media
# playback work without user namespaces, whereas Chromium's sandboxed web
# renderer requires unprivileged user namespaces on Ubuntu 24.04+/26.04.
if [ -z "${SNAP:-}" ] && [ -z "${FLATPAK_ID:-}" ] && [ -r /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
    if [ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" = "1" ]; then
        if command -v unshare >/dev/null 2>&1 && ! unshare -Ur true >/dev/null 2>&1; then
            echo "[PPPlayer] Notice: Ubuntu AppArmor restricts unprivileged user namespaces for portable binaries." >&2
            echo "[PPPlayer]   - App UI and local audio/video playback work normally." >&2
            echo "[PPPlayer]   - Chromium/YouTube web video requires a scoped AppArmor profile (included automatically in the official .deb) or strict Snap confinement." >&2
            echo "[PPPlayer]   - Recommended on Ubuntu 24.04+/26.04: install the official .deb or Snap package (see README-LINUX.txt)." >&2
        fi
    fi
fi

exec "${HERE}/ppplayer" "$@"
EOF
chmod 0755 "$TARBALL_STAGE_DIR/ppplayer-portable"

cat <<'EOF' > "$TARBALL_STAGE_DIR/README-LINUX.txt"
PPPlayer — Portable Linux x86_64 Distribution
=============================================

Quick Start
-----------
Run from any working directory:
  ./ppplayer-portable
or directly:
  ./ppplayer

Bundled Native Libraries & Licenses
-----------------------------------
libmpv.so.2 and its compatible non-core media dependencies are bundled under
lib/ with $ORIGIN RUNPATH resolution. Third-party library copyright notices
are located under share/licenses/bundled/.

Chromium / YouTube Sandbox Notice (Ubuntu 24.04+ / 26.04+)
----------------------------------------------------------
PPPlayer preserves Chromium's native OS sandbox and does NOT disable AppArmor
or pass unrestricted --no-sandbox flags outside verified Snap/Flatpak containers.

On Ubuntu 24.04+ / 26.04+ with kernel.apparmor_restrict_unprivileged_userns=1:
  * App startup, browsing, and local audio/video playback (MediaKit/libmpv)
    work out-of-the-box with zero elevated permissions.
  * Chromium/YouTube web playback requires unprivileged user namespaces.
    Because portable archives do not have a fixed system install path, we
    strongly recommend installing either:
      1. The official Debian package (ppplayer_*_amd64.deb), which installs a
         narrowly scoped /etc/apparmor.d/ppplayer profile automatically, OR
      2. The official strict-confined Snap package (sudo snap install ppplayer).
EOF
chmod 0644 "$TARBALL_STAGE_DIR/README-LINUX.txt"

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

# Create Launcher symlink
ln -s /opt/ppplayer/ppplayer "$DEB_BUILD_DIR/usr/bin/ppplayer"

# Copy Desktop and Icon
install -m 0644 packaging/linux/com.ppplayer.app.desktop "$DEB_BUILD_DIR/usr/share/applications/com.ppplayer.app.desktop"
install -m 0644 assets/logo.png "$DEB_BUILD_DIR/usr/share/icons/hicolor/256x256/apps/com.ppplayer.app.png"

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

# Normalize deterministic directory/file permissions (0755 dirs & executables, 0644 data/metadata/icons)
find "$DEB_BUILD_DIR" -type d -exec chmod 0755 {} +
find "$DEB_BUILD_DIR/opt/ppplayer" "$DEB_BUILD_DIR/usr" "$DEB_BUILD_DIR/etc" -type f -exec chmod 0644 {} +
chmod 0755 "$DEB_BUILD_DIR/opt/ppplayer/ppplayer"
if [ -f "$DEB_BUILD_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess" ]; then
    chmod 0755 "$DEB_BUILD_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess"
fi
chmod 0644 "$DEB_BUILD_DIR/etc/apparmor.d/ppplayer" "$DEB_BUILD_DIR/DEBIAN/control"
chmod 0755 "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/DEBIAN/postinst" "$DEB_BUILD_DIR/DEBIAN/postrm"

# Workaround for WSL filesystem permission issues with dpkg-deb:
# Build the deb in an isolated temp directory, preserving symlinks, with root:root ownership.
DEB_TMP_PARENT=$(mktemp -d)
DEB_TMP_DIR="$DEB_TMP_PARENT/ppplayer_${DEB_VERSION}_amd64"
cp -R -P "$DEB_BUILD_DIR" "$DEB_TMP_DIR"
find "$DEB_TMP_DIR" -type d -exec chmod 0755 {} +
find "$DEB_TMP_DIR/opt/ppplayer" "$DEB_TMP_DIR/usr" "$DEB_TMP_DIR/etc" -type f -exec chmod 0644 {} +
chmod 0755 "$DEB_TMP_DIR/opt/ppplayer/ppplayer"
if [ -f "$DEB_TMP_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess" ]; then
    chmod 0755 "$DEB_TMP_DIR/opt/ppplayer/lib/flutter_chromium_webview_subprocess"
fi
chmod 0755 "$DEB_TMP_DIR/DEBIAN" "$DEB_TMP_DIR/DEBIAN/postinst" "$DEB_TMP_DIR/DEBIAN/postrm"
chmod 0644 "$DEB_TMP_DIR/DEBIAN/control" "$DEB_TMP_DIR/etc/apparmor.d/ppplayer"
dpkg-deb --root-owner-group --build "$DEB_TMP_DIR"
mv "$DEB_TMP_DIR.deb" "$DIST_DIR/$DEB_NAME"
rm -rf "$DEB_TMP_PARENT"

# Automated DEB archive audit (runs when real dpkg-deb -c is supported)
if dpkg-deb -c "$DIST_DIR/$DEB_NAME" >/dev/null 2>&1; then
    echo "Auditing Debian archive ownership and permissions..."
    DEB_LISTING=$(dpkg-deb -c "$DIST_DIR/$DEB_NAME")
    if printf '%s\n' "$DEB_LISTING" | awk '$2 != "root/root" {print; exit 1}' | grep -q .; then
        echo "Error: Non-root ownership detected in $DIST_DIR/$DEB_NAME" >&2
        printf '%s\n' "$DEB_LISTING" | awk '$2 != "root/root"' >&2
        exit 1
    fi
    for non_exec in \
        "./etc/apparmor.d/ppplayer" \
        "./usr/share/applications/com.ppplayer.app.desktop" \
        "./usr/share/icons/hicolor/256x256/apps/com.ppplayer.app.png"; do
        if ! printf '%s\n' "$DEB_LISTING" | grep -Eq "^-rw-r--r-- root/root .* ${non_exec}$"; then
            echo "Error: Expected 0644 root/root on $non_exec in $DIST_DIR/$DEB_NAME" >&2
            exit 1
        fi
    done
    if ! printf '%s\n' "$DEB_LISTING" | grep -Eq '^-rwxr-xr-x root/root .* \./opt/ppplayer/ppplayer$'; then
        echo "Error: Expected 0755 root/root on ./opt/ppplayer/ppplayer in $DIST_DIR/$DEB_NAME" >&2
        exit 1
    fi
    if [ -f "$BUNDLE_DIR/lib/flutter_chromium_webview_subprocess" ]; then
        if ! printf '%s\n' "$DEB_LISTING" | grep -Eq '^-rwxr-xr-x root/root .* \./opt/ppplayer/lib/flutter_chromium_webview_subprocess$'; then
            echo "Error: Expected 0755 root/root on ./opt/ppplayer/lib/flutter_chromium_webview_subprocess in $DIST_DIR/$DEB_NAME" >&2
            exit 1
        fi
    fi
    echo "DEB audit passed: all entries root/root with verified file modes."
fi

# 5. Build AppImage (pinned maintained AppImage/appimagetool 1.9.1 + static FUSE3 type2-runtime 20251108)
APPIMAGE_NAME="PPPlayer-Linux-x86_64.AppImage"
echo "Building AppImage: $APPIMAGE_NAME"
APPDIR="build/linux/x64/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy bundle & portable libmpv + compatible transitive libraries + third-party licenses
cp -r "$BUNDLE_DIR/"* "$APPDIR/"
chmod 0755 "$APPDIR/ppplayer"
if [ -f "$APPDIR/lib/flutter_chromium_webview_subprocess" ]; then
    chmod 0755 "$APPDIR/lib/flutter_chromium_webview_subprocess"
fi
if [ -f "$PORTABLE_BUNDLER" ]; then
    echo "Bundling portable native libraries (libmpv + compatible transitive deps) into AppDir..."
    python3 "$PORTABLE_BUNDLER" --bundle-dir "$APPDIR"
fi

# Copy Desktop and Icon into root of AppDir
install -m 0644 packaging/linux/com.ppplayer.app.desktop "$APPDIR/com.ppplayer.app.desktop"
install -m 0644 assets/logo.png "$APPDIR/com.ppplayer.app.png"
install -m 0644 assets/logo.png "$APPDIR/.DirIcon"

# Create AppRun with CWD-independent library resolution and non-destructive userns diagnostic
cat <<'EOF' > "$APPDIR/AppRun"
#!/bin/sh
set -eu
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
if [ -f "${HERE}/lib/libmpv.so.2" ] && [ -z "${LIBMPV_LIBRARY_PATH:-}" ]; then
    export LIBMPV_LIBRARY_PATH="${HERE}/lib/libmpv.so.2"
fi
export CEF_SYSTEM_MEDIA_CONTROLS="${CEF_SYSTEM_MEDIA_CONTROLS:-0}"

# Non-destructive preflight diagnostic for Ubuntu 24.04+/26.04+ unprivileged userns restriction.
# AppImage launches and plays local media without user namespaces; Chromium's sandboxed web
# renderer requires a host AppArmor profile (.deb) or strict Snap confinement.
if [ -z "${SNAP:-}" ] && [ -z "${FLATPAK_ID:-}" ] && [ -r /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
    if [ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 0)" = "1" ]; then
        if command -v unshare >/dev/null 2>&1 && ! unshare -Ur true >/dev/null 2>&1; then
            echo "[PPPlayer] Notice: Ubuntu AppArmor restricts unprivileged user namespaces for AppImage binaries." >&2
            echo "[PPPlayer]   - App UI and local audio/video playback work normally." >&2
            echo "[PPPlayer]   - Chromium/YouTube web video requires a scoped AppArmor profile (.deb) or strict Snap confinement." >&2
            echo "[PPPlayer]   - Recommended on Ubuntu 24.04+/26.04: install the official .deb or Snap package." >&2
        fi
    fi
fi

exec "${HERE}/ppplayer" "$@"
EOF
chmod 0755 "$APPDIR/AppRun"

# Pinned, immutable upstream AppImage tooling & static FUSE3-compatible type2-runtime
APPIMAGETOOL_VERSION="1.9.1"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"

APPIMAGE_RUNTIME_VERSION="20251108"
APPIMAGE_RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/${APPIMAGE_RUNTIME_VERSION}/runtime-x86_64"
APPIMAGE_RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

verify_sha256() {
    local file_path="$1"
    local expected_sha="$2"
    local actual_sha=""
    if command -v sha256sum >/dev/null 2>&1; then
        actual_sha=$(sha256sum "$file_path" | awk '{print $1}')
    else
        actual_sha=$(shasum -a 256 "$file_path" | awk '{print $1}')
    fi
    if [ "$actual_sha" != "$expected_sha" ]; then
        echo "Error: SHA-256 verification failed for $file_path (expected=$expected_sha, actual=$actual_sha)" >&2
        rm -f "$file_path"
        exit 1
    fi
}

download_pinned() {
    local url="$1"
    local dest="$2"
    local expected_sha="$3"
    if [ -f "$dest" ]; then
        if verify_sha256 "$dest" "$expected_sha"; then
            return 0
        fi
    fi
    echo "Downloading pinned artifact: $url"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$dest" "$url"
    else
        wget -q -O "$dest" "$url"
    fi
    verify_sha256 "$dest" "$expected_sha"
}

APPIMAGE_TOOLS_DIR="build/linux/x64/appimage-tools"
mkdir -p "$APPIMAGE_TOOLS_DIR"
RUNTIME_ARGS=""

if ! command -v appimagetool >/dev/null 2>&1; then
    APPIMAGETOOL_BIN="$APPIMAGE_TOOLS_DIR/appimagetool-${APPIMAGETOOL_VERSION}-x86_64.AppImage"
    download_pinned "$APPIMAGETOOL_URL" "$APPIMAGETOOL_BIN" "$APPIMAGETOOL_SHA256"
    chmod 0755 "$APPIMAGETOOL_BIN"
    APPIMAGETOOL="$APPIMAGETOOL_BIN --appimage-extract-and-run"

    RUNTIME_BIN="${PPPLAYER_APPIMAGE_RUNTIME:-$APPIMAGE_TOOLS_DIR/runtime-${APPIMAGE_RUNTIME_VERSION}-x86_64}"
    if [ -z "${PPPLAYER_APPIMAGE_RUNTIME:-}" ]; then
        download_pinned "$APPIMAGE_RUNTIME_URL" "$RUNTIME_BIN" "$APPIMAGE_RUNTIME_SHA256"
    fi
    RUNTIME_ARGS="--runtime-file $RUNTIME_BIN"
else
    APPIMAGETOOL="appimagetool"
    if [ -n "${PPPLAYER_APPIMAGE_RUNTIME:-}" ] && [ -f "${PPPLAYER_APPIMAGE_RUNTIME}" ]; then
        RUNTIME_ARGS="--runtime-file ${PPPLAYER_APPIMAGE_RUNTIME}"
    fi
fi

# Run appimagetool with explicit x86_64 architecture and pinned static FUSE3 runtime
# shellcheck disable=SC2086
ARCH=x86_64 $APPIMAGETOOL --no-appstream $RUNTIME_ARGS "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"
chmod 0755 "$DIST_DIR/$APPIMAGE_NAME"

# Verify resulting AppImage architecture when real ELF output is generated
if command -v file >/dev/null 2>&1 && head -c 4 "$DIST_DIR/$APPIMAGE_NAME" | grep -q $'\x7fELF'; then
    if ! file "$DIST_DIR/$APPIMAGE_NAME" | grep -q 'x86-64'; then
        echo "Error: Unexpected AppImage architecture: $(file "$DIST_DIR/$APPIMAGE_NAME")" >&2
        exit 1
    fi
fi

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

