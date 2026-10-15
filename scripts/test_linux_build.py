"""Check that Linux packaging builds a fresh bundle and stops on build failure."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'packaging/linux/scripts/build_linux.sh'


class LinuxBuildTests(unittest.TestCase):
    def test_build_failure_stops_packaging_even_with_stale_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'pubspec.yaml').write_text('version: 3.0.3+11\n')
            (root / 'build/linux/x64/release/bundle').mkdir(parents=True)
            flutter = root / 'flutter'
            flutter.write_text(
                '#!/bin/sh\n'
                'echo "$*" >> "$CALLS"\n'
                'if [ "$1" = "build" ]; then exit 42; fi\n'
            )
            flutter.chmod(0o755)
            calls = root / 'calls'
            env = dict(os.environ, PATH=f'{root}{os.pathsep}{os.environ["PATH"]}', CALLS=str(calls))
            result = subprocess.run(['bash', str(SCRIPT), str(root)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 42, result.stdout + result.stderr)
            self.assertEqual(calls.read_text().splitlines(), ['pub get', 'build linux --release'])
            self.assertFalse((root / 'dist').exists())


if __name__ == '__main__':
    unittest.main()
