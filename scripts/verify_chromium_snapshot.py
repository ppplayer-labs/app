"""Verify the frozen candidate's Chromium sources without resolving packages."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[1] / 'third_party' / 'chromium'
manifest = json.loads((root / 'SOURCE_MANIFEST.json').read_text())
failures = [name for name, digest in manifest['files'].items()
            if not (root / name).is_file()
            or hashlib.sha256((root / name).read_bytes()).hexdigest() != digest]
if failures:
    raise SystemExit('FAIL: ' + ', '.join(failures))
print(f"PASS: {len(manifest['files'])} Chromium source hashes match")
