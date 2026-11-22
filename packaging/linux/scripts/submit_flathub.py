#!/usr/bin/env python3
"""
Utility script to validate and prepare PPPlayer Flatpak packaging for Flathub.
Generates dist/flathub/ directory ready for Flathub submission.
"""

import hashlib
import os
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

PROJECT_ROOT = Path(__file__).resolve().parents[3]
FLATPAK_DIR = PROJECT_ROOT / "packaging" / "linux" / "flatpak"
DIST_DIR = PROJECT_ROOT / "dist"
PUBSPEC = PROJECT_ROOT / "pubspec.yaml"


def get_version() -> str:
    content = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9.]+)", content, re.MULTILINE)
    if not match:
        raise ValueError("Could not find version in pubspec.yaml")
    return match.group(1)


def validate_metainfo(xml_path: Path):
    print(f"Validating AppStream MetaInfo: {xml_path.name}...")
    tree = ET.parse(xml_path)
    root = tree.getroot()
    if root.tag != "component":
        raise ValueError(f"Root tag must be <component>, got <{root.tag}>")
    
    app_id = root.findtext("id")
    if not app_id:
        raise ValueError("Missing <id> tag in metainfo")
    if app_id.endswith(".app") or app_id.endswith(".desktop"):
        raise ValueError(f"Flathub forbids App IDs ending in .app or .desktop: {app_id}")
    
    summary = root.findtext("summary")
    if not summary:
        raise ValueError("Missing <summary> tag in metainfo")
    if summary.endswith("."):
        raise ValueError("Summary must not end with a period according to AppStream guidelines")
    
    rating = root.find("content_rating")
    if rating is None or rating.get("type") != "oars-1.1":
        raise ValueError("Missing <content_rating type=\"oars-1.1\" /> in metainfo")
        
    print(f"MetaInfo validation PASSED for App ID: {app_id}")


def prepare_submission():
    version = get_version()
    print(f"Preparing Flathub submission for PPPlayer version: {version}")
    
    metainfo_path = FLATPAK_DIR / "com.ppplayer.PPPlayer.metainfo.xml"
    desktop_path = FLATPAK_DIR / "com.ppplayer.PPPlayer.desktop"
    manifest_path = FLATPAK_DIR / "com.ppplayer.PPPlayer.yml"
    icon_path = FLATPAK_DIR / "com.ppplayer.PPPlayer.png"
    
    for path in [metainfo_path, desktop_path, manifest_path, icon_path]:
        if not path.is_file():
            raise FileNotFoundError(f"Missing required packaging asset: {path}")
            
    validate_metainfo(metainfo_path)
    
    # Require a verified local release tarball so placeholder hashes are never emitted.
    tarball = DIST_DIR / "PPPlayer-Linux-x86_64.tar.gz"
    if not tarball.is_file():
        raise FileNotFoundError(
            f"Missing release tarball {tarball}; build PPPlayer Linux packages first so a verified SHA-256 can be computed."
        )
    tarball_sha256 = hashlib.sha256(tarball.read_bytes()).hexdigest()
    print(f"Found local release tarball: {tarball.name}")
    print(f"SHA-256: {tarball_sha256}")

    out_dir = DIST_DIR / "flathub-submission"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Update ONLY the PPPlayer archive URL and SHA-256 via the strict updater.
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from update_flatpak_manifest import update_manifest_content

    manifest_content = update_manifest_content(
        manifest_path.read_text(encoding="utf-8"),
        version=version,
        sha256=tarball_sha256,
        archive_name=tarball.name,
    )

    (out_dir / "com.ppplayer.PPPlayer.yml").write_text(manifest_content, encoding="utf-8")
    (out_dir / "com.ppplayer.PPPlayer.metainfo.xml").write_bytes(metainfo_path.read_bytes())
    (out_dir / "com.ppplayer.PPPlayer.desktop").write_bytes(desktop_path.read_bytes())
    (out_dir / "com.ppplayer.PPPlayer.png").write_bytes(icon_path.read_bytes())
    for patch in FLATPAK_DIR.glob("*.patch"):
        (out_dir / patch.name).write_bytes(patch.read_bytes())
    
    print(f"\nFlathub submission package ready at: {out_dir}")
    print("Files ready for pull request:")
    for f in out_dir.iterdir():
        print(f"  - {f.name} ({f.stat().st_size} bytes)")
    print("\nNext step: Copy these files into your flathub/flathub fork branch and open a PR against base branch 'new-pr'!")


if __name__ == "__main__":
    try:
        prepare_submission()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
