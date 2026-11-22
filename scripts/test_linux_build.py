"""Regression tests for Linux packaging, Flatpak manifest SHA-256 integrity,
non-masked Flatpak build modes, and upstream desktop metadata tarball layout."""

import hashlib
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'packaging/linux/scripts/build_linux.sh'
UPDATER = ROOT / 'packaging/linux/scripts/update_flatpak_manifest.py'
TEMPLATE_MANIFEST = ROOT / 'packaging/linux/flatpak/com.ppplayer.PPPlayer.yml'
DESKTOP_FILE = ROOT / 'packaging/linux/flatpak/com.ppplayer.PPPlayer.desktop'
METAINFO_FILE = ROOT / 'packaging/linux/flatpak/com.ppplayer.PPPlayer.metainfo.xml'
ICON_FILE = ROOT / 'packaging/linux/flatpak/com.ppplayer.PPPlayer.png'
DEB_DESKTOP_FILE = ROOT / 'packaging/linux/com.ppplayer.app.desktop'
LOGO_FILE = ROOT / 'assets/logo.png'

sys.path.insert(0, str(ROOT / 'packaging/linux/scripts'))
import update_flatpak_manifest as manifest_updater  # noqa: E402

EXPECTED_THIRD_PARTY_SHA256 = {
    'libass': 'a9afb52bf76a2569263fe2038896774c991b35c0968342a03be708e56ea60c3b',
    'libplacebo': 'd029adbe55bba8aed7aed2c48b0b66081dddfb9d42683a709342e33aa666c544',
    'jinja': 'ed06f67abd2c8b7697dfb714f80715903ab0507e3c5acc11e92477e4ea51033b',
    'glad': '61a70234dc7da467cceb07fcdd6dec1213d6143a1b6b19ccc5d7b64cc247ea47',
    'libmpv': '86d9ef40b6058732f67b46d0bbda24a074fae860b3eaae05bab3145041303066',
}


def _make_fake_project(
    root: Path,
    *,
    version: str = '4.0.2+14',
    flutter_build_exit: int = 0,
    include_flatpak_tools: bool = False,
    flatpak_builder_exit: int = 0,
    flatpak_bundle_exit: int = 0,
) -> tuple[Path, Path]:
    """Create an isolated project fixture with stubbed build tools."""
    (root / 'pubspec.yaml').write_text(f'name: ppplayer\nversion: {version}\n', encoding='utf-8')
    (root / 'assets').mkdir(parents=True, exist_ok=True)
    shutil.copy2(LOGO_FILE, root / 'assets/logo.png')

    flatpak_dir = root / 'packaging/linux/flatpak'
    flatpak_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(DEB_DESKTOP_FILE, root / 'packaging/linux/com.ppplayer.app.desktop')
    shutil.copy2(DESKTOP_FILE, flatpak_dir / DESKTOP_FILE.name)
    shutil.copy2(METAINFO_FILE, flatpak_dir / METAINFO_FILE.name)
    shutil.copy2(ICON_FILE, flatpak_dir / ICON_FILE.name)
    shutil.copy2(TEMPLATE_MANIFEST, flatpak_dir / TEMPLATE_MANIFEST.name)
    for patch in (ROOT / 'packaging/linux/flatpak').glob('*.patch'):
        shutil.copy2(patch, flatpak_dir / patch.name)

    scripts_dir = root / 'packaging/linux/scripts'
    scripts_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(UPDATER, scripts_dir / UPDATER.name)

    fake_bin = root / 'fake_bin'
    fake_bin.mkdir(parents=True, exist_ok=True)
    calls = root / 'calls.log'

    def write_tool(name: str, body: str) -> None:
        tool = fake_bin / name
        tool.write_text('#!/bin/sh\n' + body, encoding='utf-8')
        tool.chmod(0o755)

    # Stub flutter to synthesize a realistic bundle layout on `flutter build linux --release`.
    write_tool(
        'flutter',
        f'echo "flutter $*" >> "{calls}"\n'
        'if [ "$1" = "build" ]; then\n'
        f'  if [ {flutter_build_exit} -ne 0 ]; then exit {flutter_build_exit}; fi\n'
        '  mkdir -p build/linux/x64/release/bundle/lib build/linux/x64/release/bundle/data/flutter_assets\n'
        '  printf "#!/bin/sh\\necho ppplayer\\n" > build/linux/x64/release/bundle/ppplayer\n'
        '  chmod 0755 build/linux/x64/release/bundle/ppplayer\n'
        '  printf "fake-libcef" > build/linux/x64/release/bundle/lib/libcef.so\n'
        '  printf "#!/bin/sh\\necho cef-sub\\n" > build/linux/x64/release/bundle/lib/flutter_chromium_webview_subprocess\n'
        '  chmod 0644 build/linux/x64/release/bundle/lib/flutter_chromium_webview_subprocess\n'
        '  printf "icudtl" > build/linux/x64/release/bundle/data/icudtl.dat\n'
        '  printf "{}" > build/linux/x64/release/bundle/data/flutter_assets/version.json\n'
        'fi\n',
    )
    write_tool('strip', f'echo "strip $*" >> "{calls}"\nexit 0\n')
    write_tool(
        'dpkg-deb',
        f'echo "dpkg-deb $*" >> "{calls}"\n'
        'printf "fake-deb" > "$2.deb"\n',
    )
    write_tool(
        'appimagetool',
        f'echo "appimagetool $*" >> "{calls}"\n'
        'printf "#!/bin/sh\\necho appimage\\n" > "$2"\n'
        'chmod 0755 "$2"\n',
    )

    if include_flatpak_tools:
        write_tool(
            'flatpak-builder',
            f'echo "flatpak-builder $*" >> "{calls}"\n'
            f'if [ {flatpak_builder_exit} -ne 0 ]; then\n'
            '  echo "simulated flatpak-builder failure" >&2\n'
            f'  exit {flatpak_builder_exit}\n'
            'fi\n'
            'for arg in "$@"; do\n'
            '  case "$arg" in\n'
            '    --repo=*) mkdir -p "${arg#--repo=}" ;;\n'
            '  esac\n'
            'done\n',
        )
        write_tool(
            'flatpak',
            f'echo "flatpak $*" >> "{calls}"\n'
            f'if [ {flatpak_bundle_exit} -ne 0 ]; then\n'
            '  echo "simulated flatpak build-bundle failure" >&2\n'
            f'  exit {flatpak_bundle_exit}\n'
            'fi\n'
            'if [ "$1" = "build-bundle" ]; then\n'
            '  printf "fake-flatpak-bundle" > "$3"\n'
            'fi\n',
        )

    return fake_bin, calls


def _isolated_env(fake_bin: Path, *, exclude_tools: tuple[str, ...] = ()) -> dict[str, str]:
    """Build a clean PATH putting fake_bin first and optionally hiding system flatpak tools."""
    path_parts = [str(fake_bin)]
    for entry in os.environ.get('PATH', '').split(os.pathsep):
        if not entry:
            continue
        p = Path(entry)
        if exclude_tools and any((p / t).exists() for t in exclude_tools):
            continue
        path_parts.append(entry)
    env = dict(os.environ)
    env['PATH'] = os.pathsep.join(path_parts)
    env.pop('PPPLAYER_BUILD_FLATPAK', None)
    env.pop('PPPLAYER_FLATPAK_MANIFEST', None)
    return env


class FlatpakManifestUpdaterTests(unittest.TestCase):
    def test_updates_only_ppplayer_archive_and_preserves_all_third_party_checksums(self):
        original = TEMPLATE_MANIFEST.read_text(encoding='utf-8')
        new_sha = 'a' * 64
        updated = manifest_updater.update_manifest_content(
            original, version='4.0.2', sha256=new_sha
        )

        # Deterministic across repeated generations
        updated_again = manifest_updater.update_manifest_content(
            original, version='4.0.2', sha256=new_sha
        )
        self.assertEqual(updated, updated_again)

        # Parse before/after and verify every third-party checksum & URL is untouched
        before_entries = manifest_updater.parse_manifest_sources(original)
        after_entries = manifest_updater.parse_manifest_sources(updated)
        self.assertEqual(len(before_entries), len(after_entries))

        found_shas = set()
        for before, after in zip(before_entries, after_entries):
            if before.module_name == 'ppplayer' and before.fields.get('type', [(0, '')])[0][1] == 'archive':
                self.assertEqual(
                    after.fields['url'][0][1],
                    'https://github.com/ppplayer-labs/app/releases/download/v4.0.2/PPPlayer-Linux-x86_64.tar.gz',
                )
                self.assertEqual(after.fields['sha256'][0][1], new_sha)
            else:
                self.assertEqual(before.fields, after.fields)
                if 'sha256' in after.fields:
                    found_shas.add(after.fields['sha256'][0][1])

        for dep_name, dep_sha in EXPECTED_THIRD_PARTY_SHA256.items():
            self.assertIn(dep_sha, found_shas, f'Missing preserved SHA-256 for {dep_name}')
        self.assertEqual(updated.count(f'sha256: {new_sha}'), 1)

    def test_cli_rejects_invalid_sha256_version_missing_duplicate_and_malformed(self):
        original = TEMPLATE_MANIFEST.read_text(encoding='utf-8')
        valid_sha = '0123456789abcdef' * 4

        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            good_in = tmp / 'good.yml'
            good_in.write_text(original, encoding='utf-8')
            out_file = tmp / 'out.yml'

            # Invalid checksums (short, uppercase, non-hex)
            for bad_sha in ('deadbeef', 'A' * 64, 'z' * 64, ''):
                res = subprocess.run(
                    [
                        sys.executable,
                        str(UPDATER),
                        '--input',
                        str(good_in),
                        '--output',
                        str(out_file),
                        '--version',
                        '4.0.2',
                        '--sha256',
                        bad_sha,
                    ],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(res.returncode, 0, f'Expected failure for sha256={bad_sha!r}')

            # Missing PPPlayer archive source
            missing_in = tmp / 'missing.yml'
            missing_in.write_text(
                original.replace(
                    'url: https://github.com/ppplayer-labs/app/releases/download/v4.0.1/PPPlayer-Linux-x86_64.tar.gz',
                    'url: https://example.com/other.tar.gz',
                ).replace('dest: ppplayer-bundle', 'dest: other-bundle'),
                encoding='utf-8',
            )
            res = subprocess.run(
                [
                    sys.executable,
                    str(UPDATER),
                    '--input',
                    str(missing_in),
                    '--output',
                    str(out_file),
                    '--version',
                    '4.0.2',
                    '--sha256',
                    valid_sha,
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(res.returncode, 0)
            self.assertIn('Missing PPPlayer archive source', res.stderr)

            # Duplicate PPPlayer archive sources
            dup_block = (
                '      - type: archive\n'
                '        dest: ppplayer-bundle\n'
                '        url: https://github.com/ppplayer-labs/app/releases/download/v4.0.1/PPPlayer-Linux-x86_64.tar.gz\n'
                '        sha256: 0afaa5b47434e562ba75bfe35ecd0bf80849b08e26742f7170e04ffb0f8be57e\n'
            )
            dup_in = tmp / 'dup.yml'
            dup_in.write_text(original + '\n' + dup_block, encoding='utf-8')
            res = subprocess.run(
                [
                    sys.executable,
                    str(UPDATER),
                    '--input',
                    str(dup_in),
                    '--output',
                    str(out_file),
                    '--version',
                    '4.0.2',
                    '--sha256',
                    valid_sha,
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(res.returncode, 0)
            self.assertIn('Duplicate PPPlayer archive sources', res.stderr)

            # Malformed source configuration (tab indentation & missing sha256)
            tab_in = tmp / 'tab.yml'
            tab_in.write_text(original.replace('  - name: libass', '\t- name: libass'), encoding='utf-8')
            res = subprocess.run(
                [
                    sys.executable,
                    str(UPDATER),
                    '--input',
                    str(tab_in),
                    '--output',
                    str(out_file),
                    '--version',
                    '4.0.2',
                    '--sha256',
                    valid_sha,
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(res.returncode, 0)

            no_sha_in = tmp / 'no_sha.yml'
            no_sha_in.write_text(
                original.replace(
                    '        sha256: 0afaa5b47434e562ba75bfe35ecd0bf80849b08e26742f7170e04ffb0f8be57e\n',
                    '',
                ),
                encoding='utf-8',
            )
            res = subprocess.run(
                [
                    sys.executable,
                    str(UPDATER),
                    '--input',
                    str(no_sha_in),
                    '--output',
                    str(out_file),
                    '--version',
                    '4.0.2',
                    '--sha256',
                    valid_sha,
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(res.returncode, 0)
            self.assertIn('sha256', res.stderr)


@unittest.skipUnless(shutil.which('bash'), 'bash required')
class LinuxBuildTests(unittest.TestCase):
    def test_build_failure_stops_packaging_even_with_stale_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'pubspec.yaml').write_text('version: 3.0.3+11\n', encoding='utf-8')
            (root / 'build/linux/x64/release/bundle').mkdir(parents=True)
            flutter = root / 'flutter'
            flutter.write_text(
                '#!/bin/sh\n'
                'echo "$*" >> "$CALLS"\n'
                'if [ "$1" = "build" ]; then exit 42; fi\n',
                encoding='utf-8',
            )
            flutter.chmod(0o755)
            calls = root / 'calls'
            env = dict(os.environ, PATH=f'{root}{os.pathsep}{os.environ["PATH"]}', CALLS=str(calls))
            result = subprocess.run(
                ['bash', str(SCRIPT), str(root)], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 42, result.stdout + result.stderr)
            self.assertEqual(calls.read_text().splitlines(), ['pub get', 'build linux --release'])
            self.assertFalse((root / 'dist').exists())

    def test_default_build_packages_tarball_metadata_preserves_checksums_and_skips_flatpak_build(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake_bin, calls = _make_fake_project(root, include_flatpak_tools=True)
            env = _isolated_env(fake_bin)
            result = subprocess.run(
                ['bash', str(SCRIPT), str(root)], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('Flatpak bundle build not requested', result.stdout)
            self.assertNotIn('flatpak-builder', calls.read_text(encoding='utf-8'))
            self.assertFalse((root / 'dist/PPPlayer-Linux-x86_64.flatpak').exists())

            # Extract tarball into clean dir and verify complete portable + metadata layout
            tarball = root / 'dist/PPPlayer-Linux-x86_64.tar.gz'
            self.assertTrue(tarball.is_file())
            tar_sha = hashlib.sha256(tarball.read_bytes()).hexdigest()

            extract_dir = root / 'extracted'
            extract_dir.mkdir()
            with tarfile.open(tarball, 'r:gz') as tf:
                tf.extractall(extract_dir)

            app_exe = extract_dir / 'PPPlayer/ppplayer'
            cef_sub = extract_dir / 'PPPlayer/lib/flutter_chromium_webview_subprocess'
            libcef = extract_dir / 'PPPlayer/lib/libcef.so'
            desktop = extract_dir / 'PPPlayer/share/applications/com.ppplayer.PPPlayer.desktop'
            metainfo = extract_dir / 'PPPlayer/share/metainfo/com.ppplayer.PPPlayer.metainfo.xml'
            icon = extract_dir / 'PPPlayer/share/icons/hicolor/512x512/apps/com.ppplayer.PPPlayer.png'

            for p in (app_exe, cef_sub, libcef, desktop, metainfo, icon):
                self.assertTrue(p.is_file(), f'Missing expected archive file: {p}')
            self.assertTrue(os.access(app_exe, os.X_OK), 'ppplayer must be executable')
            self.assertTrue(os.access(cef_sub, os.X_OK), 'CEF subprocess must be executable')

            # Validate Desktop Entry, AppStream XML, and PNG dimensions
            desktop_text = desktop.read_text(encoding='utf-8')
            self.assertIn('[Desktop Entry]', desktop_text)
            self.assertIn('Exec=ppplayer %U', desktop_text)
            self.assertIn('Icon=com.ppplayer.PPPlayer', desktop_text)

            xml_root = ET.parse(metainfo).getroot()
            self.assertEqual(xml_root.findtext('id'), 'com.ppplayer.PPPlayer')

            png_bytes = icon.read_bytes()
            self.assertEqual(png_bytes[:8], b'\x89PNG\r\n\x1a\n')
            width, height = struct.unpack('>II', png_bytes[16:24])
            self.assertEqual((width, height), (512, 512))

            # Validate staged Flatpak manifest checksum integrity
            staged_manifest = (root / 'dist/flatpak/com.ppplayer.PPPlayer.yml').read_text(
                encoding='utf-8'
            )
            self.assertIn(
                'url: https://github.com/ppplayer-labs/app/releases/download/v4.0.2/PPPlayer-Linux-x86_64.tar.gz',
                staged_manifest,
            )
            self.assertEqual(staged_manifest.count(f'sha256: {tar_sha}'), 1)
            for dep_name, dep_sha in EXPECTED_THIRD_PARTY_SHA256.items():
                self.assertIn(
                    f'sha256: {dep_sha}',
                    staged_manifest,
                    f'Staged manifest corrupted third-party SHA-256 for {dep_name}',
                )

    def test_flatpak_requested_when_tooling_unavailable_skips_explicitly(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake_bin, calls = _make_fake_project(root, include_flatpak_tools=False)
            env = _isolated_env(fake_bin, exclude_tools=('flatpak-builder', 'flatpak'))
            result = subprocess.run(
                ['bash', str(SCRIPT), '--build-flatpak', str(root)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('SKIPPED: Flatpak tooling', result.stdout)
            self.assertNotIn('flatpak-builder', calls.read_text(encoding='utf-8'))
            self.assertFalse((root / 'dist/PPPlayer-Linux-x86_64.flatpak').exists())

    def test_flatpak_requested_when_tooling_available_fails_on_builder_error(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake_bin, calls = _make_fake_project(
                root, include_flatpak_tools=True, flatpak_builder_exit=23
            )
            env = _isolated_env(fake_bin)
            result = subprocess.run(
                ['bash', str(SCRIPT), '--build-flatpak', str(root)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0, 'Flatpak build failure must not be masked')
            self.assertIn('flatpak-builder', calls.read_text(encoding='utf-8'))
            self.assertFalse((root / 'dist/PPPlayer-Linux-x86_64.flatpak').exists())

    def test_flatpak_requested_when_tooling_available_fails_on_bundle_error(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake_bin, calls = _make_fake_project(
                root, include_flatpak_tools=True, flatpak_builder_exit=0, flatpak_bundle_exit=17
            )
            env = _isolated_env(fake_bin)
            result = subprocess.run(
                ['bash', str(SCRIPT), '--build-flatpak', str(root)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0, 'flatpak build-bundle failure must not be masked')
            self.assertIn('flatpak build-bundle', calls.read_text(encoding='utf-8'))

    def test_flatpak_requested_when_tooling_available_succeeds_and_checksums_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake_bin, calls = _make_fake_project(root, include_flatpak_tools=True)
            env = _isolated_env(fake_bin)
            result = subprocess.run(
                ['bash', str(SCRIPT), '--build-flatpak', str(root)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('flatpak-builder', calls.read_text(encoding='utf-8'))
            self.assertIn('flatpak build-bundle', calls.read_text(encoding='utf-8'))
            self.assertTrue((root / 'dist/PPPlayer-Linux-x86_64.flatpak').is_file())
            self.assertIn(
                'PPPlayer-Linux-x86_64.flatpak',
                (root / 'dist/SHA256SUMS').read_text(encoding='utf-8'),
            )


if __name__ == '__main__':
    unittest.main()
