"""Verify the frozen candidate's Chromium sources without resolving packages."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[1] / 'third_party' / 'chromium'
manifest = json.loads((root / 'SOURCE_MANIFEST.json').read_text())


def canonical_sha256(path: Path) -> str:
    data = path.read_bytes()
    if b'\x00' not in data:
        data = data.replace(b'\r\n', b'\n')
    return hashlib.sha256(data).hexdigest()


failures = [name for name, digest in manifest['files'].items()
            if not (root / name).is_file()
            or canonical_sha256(root / name) != digest]
if failures:
    raise SystemExit('FAIL: ' + ', '.join(failures))
print(f"PASS: {len(manifest['files'])} Chromium source hashes match")
