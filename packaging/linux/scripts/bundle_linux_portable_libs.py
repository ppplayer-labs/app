#!/usr/bin/env python3
"""Bundle portable non-core native shared libraries (libmpv.so.2 + transitive closure)
into PPPlayer Linux portable distributions (AppImage AppDir and portable tar.gz).

Design goals:
- Dynamically discover the real ELF dependency graph via readelf + ldd rather than
  hardcoding distro-specific FFmpeg/codec sonames.
- Exclude core OS, glibc, C++ runtime, GPU/EGL/GL/DRM/GBM, X11/Wayland core,
  GTK/GLib/font, and host audio daemon libraries (AppImage excludelist baseline) so
  bundled binaries preserve host ABI compatibility across Linux distributions.
- Patch RUNPATH to '$ORIGIN' on bundled shared libraries so loader resolution works
  independently of the current working directory.
- Collect Debian/Ubuntu third-party license/copyright notices for every bundled
  library into share/licenses/bundled/ to satisfy LGPL/GPL/MIT/BSD redistribution terms.
"""

from __future__ import annotations

import argparse
from collections import deque
import fnmatch
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


# Core host-ABI libraries that MUST NOT be bundled (aligned with the official
# AppImage excludelist). These libraries are either ABI-coupled to the host
# kernel/glibc/GPU drivers/display server or universally present on Linux desktops.
CORE_HOST_EXCLUDELIST: tuple[str, ...] = (
    # Linker / glibc / core C & C++ runtimes
    'ld-linux*.so*',
    'linux-vdso*.so*',
    'libc.so*',
    'libm.so*',
    'libmvec.so*',
    'libdl.so*',
    'librt.so*',
    'libpthread.so*',
    'libresolv.so*',
    'libutil.so*',
    'libnsl.so*',
    'libnss_*.so*',
    'libcrypt.so*',
    'libanl.so*',
    'libBrokenLocale.so*',
    'libcidn.so*',
    'libthread_db.so*',
    'libgcc_s.so*',
    'libstdc++.so*',
    'libatomic.so*',
    'libgomp.so*',
    # Core graphics / GPU / DRM / display protocols (host driver ABI)
    'libGL.so*',
    'libEGL.so*',
    'libGLESv1_CM.so*',
    'libGLESv2.so*',
    'libGLX.so*',
    'libGLdispatch.so*',
    'libOpenGL.so*',
    'libdrm.so*',
    'libdrm_*.so*',
    'libgbm.so*',
    'libvulkan.so*',
    'libepoxy.so*',
    'libX11.so*',
    'libX11-xcb.so*',
    'libXext.so*',
    'libXfixes.so*',
    'libXrender.so*',
    'libXrandr.so*',
    'libXi.so*',
    'libXcursor.so*',
    'libXdamage.so*',
    'libXcomposite.so*',
    'libXinerama.so*',
    'libXau.so*',
    'libXdmcp.so*',
    'libICE.so*',
    'libSM.so*',
    'libxcb.so*',
    'libxcb-*.so*',
    'libxkbcommon.so*',
    'libxkbcommon-*.so*',
    'libwayland-client.so*',
    'libwayland-cursor.so*',
    'libwayland-egl.so*',
    'libwayland-server.so*',
    # Core desktop toolkit / GLib / fonts / DBus / system services
    'libgtk-3.so*',
    'libgdk-3.so*',
    'libgdk_pixbuf-2.0.so*',
    'libglib-2.0.so*',
    'libgobject-2.0.so*',
    'libgio-2.0.so*',
    'libgmodule-2.0.so*',
    'libgthread-2.0.so*',
    'libcairo.so*',
    'libcairo-gobject.so*',
    'libpango-1.0.so*',
    'libpangocairo-1.0.so*',
    'libpangoft2-1.0.so*',
    'libharfbuzz.so*',
    'libfribidi.so*',
    'libatk-1.0.so*',
    'libatk-bridge-2.0.so*',
    'libatspi.so*',
    'libdbus-1.so*',
    'libsystemd.so*',
    'libudev.so*',
    'libfontconfig.so*',
    'libfreetype.so*',
    'libexpat.so*',
    'libuuid.so*',
    'libmount.so*',
    'libblkid.so*',
    'libselinux.so*',
    'libz.so*',
    'libffi.so*',
    'libpcre.so*',
    'libpcre2-8.so*',
    'libcap.so*',
    'libgpg-error.so*',
    'libgcrypt.so*',
    'libsecret-1.so*',
    'libssl.so*',
    'libcrypto.so*',
    'libgnutls.so*',
    'libp11-kit.so*',
    'libtasn1.so*',
    'libnettle.so*',
    'libhogweed.so*',
    'libgmp.so*',
    'libidn2.so*',
    'libunistring.so*',
    'libcom_err.so*',
    'libkrb5.so*',
    'libk5crypto.so*',
    'libgssapi_krb5.so*',
    'libkeyutils.so*',
    # Host audio daemons (ABI tied to system sound server sockets/modules)
    'libasound.so*',
    'libpulse.so*',
    'libpulse-simple.so*',
    'libpulsecommon-*.so*',
    'libpipewire-0.3.so*',
    'libspa-0.2.so*',
)

LDD_LINE_RE = re.compile(r'^\s*([^\s]+)\s+=>\s+([^\s]+)\s+\(0x')
LDD_MISSING_RE = re.compile(r'^\s*([^\s]+)\s+=>\s+not found')
DT_NEEDED_RE = re.compile(r'\(NEEDED\)\s+Shared library:\s+\[([^\]]+)\]')


def is_excluded_host_library(soname: str) -> bool:
    """Return True if soname belongs to the excluded host-ABI base library set."""
    return any(fnmatch.fnmatch(soname, pattern) for pattern in CORE_HOST_EXCLUDELIST)


def is_elf_file(path: Path) -> bool:
    """Check ELF magic header without invoking external tools."""
    try:
        with path.open('rb') as f:
            return f.read(4) == b'\x7fELF'
    except OSError:
        return False


def parse_dt_needed(elf_path: Path) -> list[str]:
    """Extract direct DT_NEEDED sonames via readelf -d."""
    if not shutil.which('readelf') or not is_elf_file(elf_path):
        return []
    res = subprocess.run(
        ['readelf', '-d', str(elf_path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if res.returncode != 0:
        return []
    return DT_NEEDED_RE.findall(res.stdout)


def resolve_ldd(elf_path: Path, lib_dir: Path) -> tuple[dict[str, Path], list[str]]:
    """Run ldd on elf_path with LD_LIBRARY_PATH including lib_dir.

    Returns (resolved_map: soname -> real Path, missing_sonames).
    """
    if not shutil.which('ldd') or not is_elf_file(elf_path):
        return {}, []
    env = dict(os.environ)
    existing = env.get('LD_LIBRARY_PATH', '')
    env['LD_LIBRARY_PATH'] = f'{lib_dir}:{existing}' if existing else str(lib_dir)
    res = subprocess.run(
        ['ldd', str(elf_path)],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    resolved: dict[str, Path] = {}
    missing: list[str] = []
    for line in res.stdout.splitlines():
        m_miss = LDD_MISSING_RE.match(line)
        if m_miss:
            missing.append(m_miss.group(1))
            continue
        m_ok = LDD_LINE_RE.match(line)
        if m_ok:
            soname, target = m_ok.group(1), m_ok.group(2)
            p = Path(target)
            if p.exists():
                resolved[soname] = p.resolve()
    return resolved, missing


def patch_runpath(elf_path: Path, rpath: str) -> bool:
    """Set ELF DT_RUNPATH via patchelf if available."""
    patchelf = shutil.which('patchelf')
    if not patchelf or not is_elf_file(elf_path):
        return False
    res = subprocess.run(
        [patchelf, '--set-rpath', rpath, str(elf_path)],
        capture_output=True,
        text=True,
        check=False,
    )
    return res.returncode == 0


def resolve_ldd_no_env(elf_path: Path) -> tuple[dict[str, Path], list[str]]:
    """Run ldd on elf_path with an empty LD_LIBRARY_PATH to verify pure RUNPATH resolution."""
    if not shutil.which('ldd') or not is_elf_file(elf_path):
        return {}, []
    env = dict(os.environ)
    env.pop('LD_LIBRARY_PATH', None)
    res = subprocess.run(
        ['ldd', str(elf_path)],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    resolved: dict[str, Path] = {}
    missing: list[str] = []
    for line in res.stdout.splitlines():
        m_miss = LDD_MISSING_RE.match(line)
        if m_miss:
            missing.append(m_miss.group(1))
            continue
        m_ok = LDD_LINE_RE.match(line)
        if m_ok:
            soname, target = m_ok.group(1), m_ok.group(2)
            p = Path(target)
            if p.exists():
                resolved[soname] = p.resolve()
    return resolved, missing


def find_owning_deb_package(lib_real_path: Path) -> str | None:
    """Resolve the Debian/Ubuntu package owning a bundled shared library."""
    dpkg_query = shutil.which('dpkg-query')
    if not dpkg_query:
        return None
    candidates = [str(lib_real_path)]
    # Handle merged-/usr paths where dpkg records /lib/... or /usr/lib/...
    raw = str(lib_real_path)
    if raw.startswith('/usr/lib/'):
        candidates.append(raw[len('/usr'):])
    elif raw.startswith('/lib/'):
        candidates.append('/usr' + raw)
    for cand in candidates:
        res = subprocess.run(
            [dpkg_query, '-S', cand],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0 and ':' in res.stdout:
            pkg = res.stdout.splitlines()[0].split(':', 1)[0].strip()
            if pkg:
                return pkg
    return None


def get_deb_package_version(pkg: str) -> str:
    dpkg_query = shutil.which('dpkg-query')
    if not dpkg_query:
        return 'unknown'
    res = subprocess.run(
        [dpkg_query, '-W', '-f=${Version}', pkg],
        capture_output=True,
        text=True,
        check=False,
    )
    return res.stdout.strip() if res.returncode == 0 and res.stdout.strip() else 'unknown'


def collect_bundled_licenses(
    bundled_sources: dict[str, Path],
    licenses_dir: Path,
) -> Path:
    """Copy /usr/share/doc/<pkg>/copyright files and emit THIRD_PARTY_LICENSES.txt."""
    licenses_dir.mkdir(parents=True, exist_ok=True)
    pkg_to_libs: dict[str, list[str]] = {}
    unowned: list[tuple[str, Path]] = []

    for soname, src_real in sorted(bundled_sources.items()):
        pkg = find_owning_deb_package(src_real)
        if pkg:
            pkg_to_libs.setdefault(pkg, []).append(soname)
        else:
            unowned.append((soname, src_real))

    manifest_lines = [
        'PPPlayer Linux Portable Distribution — Bundled Native Library Notices',
        '=====================================================================',
        '',
        'The following native shared libraries are bundled under lib/ for',
        'portable Linux execution (AppImage and portable tar.gz).',
        'Corresponding Debian/Ubuntu package copyright notices are included',
        'in this directory. For LGPL/GPL-licensed components, corresponding',
        'source packages are available from the distribution archive matching',
        'the listed package version.',
        '',
    ]

    for pkg in sorted(pkg_to_libs):
        ver = get_deb_package_version(pkg)
        libs_csv = ', '.join(sorted(pkg_to_libs[pkg]))
        copyright_src = Path('/usr/share/doc') / pkg / 'copyright'
        if not copyright_src.is_file() and ':' in pkg:
            copyright_src = Path('/usr/share/doc') / pkg.split(':', 1)[0] / 'copyright'
        safe_pkg = pkg.replace(':', '_')
        copied_note = '(copyright file not found on build host)'
        if copyright_src.is_file():
            dest_name = f'{safe_pkg}.copyright'
            shutil.copy2(copyright_src, licenses_dir / dest_name)
            os.chmod(licenses_dir / dest_name, 0o644)
            copied_note = dest_name
        manifest_lines.append(f'- {pkg} ({ver}): {libs_csv} -> {copied_note}')

    for soname, src_real in unowned:
        manifest_lines.append(f'- {soname} (source: {src_real}) -> (unowned by dpkg)')

    manifest_path = licenses_dir / 'THIRD_PARTY_LICENSES.txt'
    manifest_path.write_text('\n'.join(manifest_lines) + '\n', encoding='utf-8')
    os.chmod(manifest_path, 0o644)
    return manifest_path


def bundle_portable_libs(
    bundle_dir: Path,
    *,
    require_mpv: bool = True,
    patch_rpath: bool = True,
) -> dict[str, Path]:
    """Bundle non-core shared libraries needed by bundle_dir/ppplayer & lib/*.so*."""
    lib_dir = bundle_dir / 'lib'
    exe_path = bundle_dir / 'ppplayer'
    if not exe_path.is_file():
        raise FileNotFoundError(f'Missing executable: {exe_path}')
    if not lib_dir.is_dir():
        raise FileNotFoundError(f'Missing lib directory: {lib_dir}')

    # Record pre-existing bundled files (e.g., libcef.so, libapp.so, libflutter_linux_gtk.so,
    # libvulkan.so.1, libEGL.so, libGLESv2.so) so we never overwrite them.
    preexisting_names = {p.name for p in lib_dir.iterdir()}

    # Seed BFS with ppplayer + pre-existing ELF plugins/binaries in lib/.
    # Skip libcef.so itself because CEF already ships its own complete runtime
    # and only relies on standard host desktop libraries.
    queue: deque[Path] = deque()
    if is_elf_file(exe_path):
        queue.append(exe_path)
    for entry in sorted(lib_dir.iterdir()):
        if entry.name == 'libcef.so' or entry.is_dir():
            continue
        if (entry.name.endswith('.so') or '.so.' in entry.name or os.access(entry, os.X_OK)) and is_elf_file(entry):
            queue.append(entry)

    visited_elfs: set[Path] = set()
    bundled_sources: dict[str, Path] = {}

    while queue:
        current = queue.popleft()
        resolved_cur = current.resolve()
        if resolved_cur in visited_elfs:
            continue
        visited_elfs.add(resolved_cur)

        ldd_map, _missing = resolve_ldd(current, lib_dir)
        # Union direct DT_NEEDED (readelf) with ldd-resolved transitive names so
        # we don't miss anything loaded via RUNPATH/ld.so.cache.
        needed_names = set(parse_dt_needed(current)) | set(ldd_map.keys())

        for soname in sorted(needed_names):
            if soname in preexisting_names:
                continue
            if is_excluded_host_library(soname):
                continue
            src_real = ldd_map.get(soname)
            if src_real is None or not src_real.is_file():
                continue
            # Never copy something already inside bundle_dir/lib
            try:
                src_real.relative_to(lib_dir.resolve())
                continue
            except ValueError:
                pass

            dest = lib_dir / soname
            if not dest.exists():
                shutil.copy2(src_real, dest)
                os.chmod(dest, 0o644)
                bundled_sources[soname] = src_real
                queue.append(dest)

    # Verify libmpv.so.2 is present if required and ppplayer is a real ELF binary.
    mpv_present = any((lib_dir / name).is_file() for name in ('libmpv.so.2', 'libmpv.so.1'))
    if require_mpv and is_elf_file(exe_path) and not mpv_present:
        raise RuntimeError(
            f'libmpv.so.2 was not bundled into {lib_dir}. '
            'Ensure libmpv2/libmpv-dev is installed on the Linux build host.'
        )

    # Verify zero newly bundled libraries violate the core host-ABI excludelist.
    leaked = [name for name in bundled_sources if is_excluded_host_library(name)]
    if leaked:
        raise RuntimeError(f'Core host-ABI libraries leaked into bundle: {leaked}')

    # Patch DT_RUNPATH on newly bundled shared libraries AND Flutter plugin .so files
    # (which otherwise embed the build-host ephemeral directory) so loader resolution
    # works via $ORIGIN independently of CWD and without requiring LD_LIBRARY_PATH.
    if patch_rpath and shutil.which('patchelf'):
        for soname in sorted(bundled_sources):
            patch_runpath(lib_dir / soname, '$ORIGIN')
        for entry in sorted(lib_dir.iterdir()):
            if entry.is_file() and entry.name.endswith('_plugin.so') and is_elf_file(entry):
                patch_runpath(entry, '$ORIGIN')
        if is_elf_file(exe_path):
            patch_runpath(exe_path, '$ORIGIN/lib')

    # Verify loader resolution (pure RUNPATH when patchelf ran, otherwise with lib_dir).
    verify_pure = patch_rpath and bool(shutil.which('patchelf'))
    if is_elf_file(exe_path):
        _, exe_missing = resolve_ldd_no_env(exe_path) if verify_pure else resolve_ldd(exe_path, lib_dir)
        if exe_missing:
            raise RuntimeError(f'Unresolved libraries on {exe_path.name}: {exe_missing}')
    mpv_dest = lib_dir / 'libmpv.so.2'
    if mpv_dest.is_file() and is_elf_file(mpv_dest):
        _, mpv_missing = resolve_ldd_no_env(mpv_dest) if verify_pure else resolve_ldd(mpv_dest, lib_dir)
        if mpv_missing:
            raise RuntimeError(f'Unresolved libraries on libmpv.so.2: {mpv_missing}')
    mk_video_plugin = lib_dir / 'libmedia_kit_video_plugin.so'
    if mk_video_plugin.is_file() and is_elf_file(mk_video_plugin):
        _, mk_missing = resolve_ldd_no_env(mk_video_plugin) if verify_pure else resolve_ldd(mk_video_plugin, lib_dir)
        if mk_missing:
            raise RuntimeError(f'Unresolved libraries on libmedia_kit_video_plugin.so: {mk_missing}')

    # Collect third-party copyright notices for all newly bundled libraries.
    if bundled_sources:
        collect_bundled_licenses(bundled_sources, bundle_dir / 'share' / 'licenses' / 'bundled')

    return bundled_sources


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description='Bundle portable non-core native libraries (including libmpv.so.2) into a Linux PPPlayer directory.'
    )
    parser.add_argument('--bundle-dir', required=True, type=Path, help='Target PPPlayer portable/AppDir root')
    parser.add_argument(
        '--allow-missing-mpv',
        action='store_true',
        help='Do not fail if ppplayer is a non-ELF test stub or libmpv is absent',
    )
    parser.add_argument('--no-patchelf', action='store_true', help='Skip patchelf RUNPATH updates')
    args = parser.parse_args(argv)

    bundled = bundle_portable_libs(
        args.bundle_dir,
        require_mpv=not args.allow_missing_mpv,
        patch_rpath=not args.no_patchelf,
    )
    print(f'Bundled {len(bundled)} portable shared libraries into {args.bundle_dir / "lib"}')
    if 'libmpv.so.2' in bundled:
        print(f'  libmpv.so.2 <- {bundled["libmpv.so.2"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
