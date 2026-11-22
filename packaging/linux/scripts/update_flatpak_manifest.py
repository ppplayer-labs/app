#!/usr/bin/env python3
"""Deterministically update ONLY the PPPlayer archive source in a Flatpak manifest.

Uses a strict, indentation-aware parser so third-party module URLs and SHA-256
checksums (libass, libplacebo, jinja, glad, libmpv, etc.) are guaranteed to
remain byte-for-byte unchanged.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys
from typing import Sequence

SHA256_RE = re.compile(r'^[0-9a-f]{64}$')
VERSION_RE = re.compile(r'^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$')
PPPLAYER_URL_RE = re.compile(
    r'^(https://github\.com/ppplayer-labs/app/releases/download/)v[^/\s]+/([^/\s]+)$'
)
KEY_VALUE_RE = re.compile(r'^([A-Za-z0-9_.-]+):(?:\s+(.*))?$')


class ManifestUpdateError(ValueError):
    """Raised when the Flatpak manifest or update inputs fail strict validation."""


@dataclass(frozen=True)
class SourceEntry:
    module_name: str
    start_line: int
    end_line: int
    fields: dict[str, list[tuple[int, str]]]


def _strip_quotes(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def _validate_yaml_if_available(content: str) -> None:
    """Validate YAML syntax with PyYAML when available in the environment."""
    try:
        import yaml  # type: ignore
    except ModuleNotFoundError:
        return
    try:
        parsed = yaml.safe_load(content)
    except Exception as exc:  # pragma: no cover - depends on PyYAML install
        raise ManifestUpdateError(f'Manifest is not valid YAML: {exc}') from exc
    if not isinstance(parsed, dict) or not isinstance(parsed.get('modules'), list):
        raise ManifestUpdateError('Manifest YAML must define a top-level modules list.')


def parse_manifest_sources(content: str) -> list[SourceEntry]:
    """Parse all module source entries from a Flatpak YAML manifest strictly."""
    lines = content.splitlines()
    for idx, line in enumerate(lines, start=1):
        if '\t' in line:
            raise ManifestUpdateError(f'Invalid tab indentation on line {idx}.')

    _validate_yaml_if_available(content)

    modules_idx = None
    for idx, line in enumerate(lines):
        if line.strip() == 'modules:' and not line.startswith(' '):
            if modules_idx is not None:
                raise ManifestUpdateError('Duplicate top-level modules: section.')
            modules_idx = idx
    if modules_idx is None:
        raise ManifestUpdateError('Manifest is missing top-level modules: section.')

    # Locate top-level module items under modules:.
    module_starts: list[tuple[int, int, str]] = []
    module_indent: int | None = None
    idx = modules_idx + 1
    while idx < len(lines):
        line = lines[idx]
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            idx += 1
            continue
        indent = len(line) - len(line.lstrip(' '))
        if indent == 0:
            break
        if stripped.startswith('- '):
            if module_indent is None:
                module_indent = indent
            if indent == module_indent:
                rest = stripped[2:].strip()
                m = KEY_VALUE_RE.match(rest)
                if not m or m.group(1) != 'name' or not (m.group(2) or '').strip():
                    raise ManifestUpdateError(
                        f'Malformed module declaration on line {idx + 1}: {line!r}'
                    )
                module_starts.append((idx, indent, _strip_quotes(m.group(2) or '')))
        idx += 1
    modules_end = idx

    if not module_starts:
        raise ManifestUpdateError('Manifest modules: section contains no modules.')

    entries: list[SourceEntry] = []
    for mod_i, (mod_start, mod_ind, mod_name) in enumerate(module_starts):
        mod_end = module_starts[mod_i + 1][0] if mod_i + 1 < len(module_starts) else modules_end
        sources_idx = None
        sources_indent = None
        for i in range(mod_start + 1, mod_end):
            line = lines[i]
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            indent = len(line) - len(line.lstrip(' '))
            if indent > mod_ind and stripped == 'sources:':
                if sources_idx is not None:
                    raise ManifestUpdateError(
                        f'Duplicate sources: section in module {mod_name!r}.'
                    )
                sources_idx = i
                sources_indent = indent

        if sources_idx is None or sources_indent is None:
            continue

        # Collect source items under this module's sources: section.
        source_starts: list[tuple[int, int]] = []
        src_item_indent: int | None = None
        j = sources_idx + 1
        while j < mod_end:
            line = lines[j]
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                j += 1
                continue
            indent = len(line) - len(line.lstrip(' '))
            if indent <= sources_indent:
                break
            if stripped.startswith('- '):
                if src_item_indent is None:
                    src_item_indent = indent
                if indent == src_item_indent:
                    source_starts.append((j, indent))
            j += 1
        sources_end = j

        for src_i, (src_start, src_ind) in enumerate(source_starts):
            src_end = (
                source_starts[src_i + 1][0]
                if src_i + 1 < len(source_starts)
                else sources_end
            )
            fields: dict[str, list[tuple[int, str]]] = {}
            field_indent = src_ind + 2

            # First line: "- key: value"
            first_rest = lines[src_start].strip()[2:].strip()
            m_first = KEY_VALUE_RE.match(first_rest)
            if not m_first:
                raise ManifestUpdateError(
                    f'Malformed source entry on line {src_start + 1} in module {mod_name!r}.'
                )
            fields.setdefault(m_first.group(1), []).append(
                (src_start, _strip_quotes(m_first.group(2) or ''))
            )

            for k in range(src_start + 1, src_end):
                line = lines[k]
                stripped = line.strip()
                if not stripped or stripped.startswith('#'):
                    continue
                indent = len(line) - len(line.lstrip(' '))
                if indent < field_indent:
                    raise ManifestUpdateError(
                        f'Invalid indentation on line {k + 1} inside source entry of {mod_name!r}.'
                    )
                if indent == field_indent:
                    if stripped.startswith('- '):
                        raise ManifestUpdateError(
                            f'Unexpected list item on line {k + 1} inside source mapping of {mod_name!r}.'
                        )
                    m = KEY_VALUE_RE.match(stripped)
                    if not m:
                        raise ManifestUpdateError(
                            f'Malformed key/value on line {k + 1} in module {mod_name!r}: {line!r}'
                        )
                    fields.setdefault(m.group(1), []).append(
                        (k, _strip_quotes(m.group(2) or ''))
                    )

            entries.append(
                SourceEntry(
                    module_name=mod_name,
                    start_line=src_start,
                    end_line=src_end,
                    fields=fields,
                )
            )

    return entries


def _is_ppplayer_archive_candidate(entry: SourceEntry, archive_name: str) -> bool:
    src_type = entry.fields.get('type', [(0, '')])[0][1]
    if src_type != 'archive':
        return False

    urls = [v for _, v in entry.fields.get('url', [])]
    dests = [v for _, v in entry.fields.get('dest', [])]

    url_matches = any(
        (m := PPPLAYER_URL_RE.match(u)) is not None and m.group(2) == archive_name
        for u in urls
    )
    if entry.module_name == 'ppplayer':
        return url_matches or 'ppplayer-bundle' in dests
    return url_matches


def update_manifest_content(
    content: str,
    *,
    version: str,
    sha256: str,
    archive_name: str = 'PPPlayer-Linux-x86_64.tar.gz',
) -> str:
    """Return updated manifest text with ONLY the PPPlayer archive URL & SHA-256 updated."""
    if not VERSION_RE.match(version):
        raise ManifestUpdateError(
            f'Invalid release version {version!r}; expected semver like 4.0.2 or 4.0.2-rc1.'
        )
    if not SHA256_RE.match(sha256):
        raise ManifestUpdateError(
            f'Invalid SHA-256 checksum {sha256!r}; expected 64 lowercase hexadecimal characters.'
        )
    if not archive_name or '/' in archive_name or '\\' in archive_name:
        raise ManifestUpdateError(f'Invalid archive filename {archive_name!r}.')

    entries = parse_manifest_sources(content)
    matches = [e for e in entries if _is_ppplayer_archive_candidate(e, archive_name)]

    if not matches:
        raise ManifestUpdateError(
            f'Missing PPPlayer archive source for {archive_name!r} in manifest.'
        )
    if len(matches) > 1:
        locations = ', '.join(
            f'module {m.module_name!r} line {m.start_line + 1}' for m in matches
        )
        raise ManifestUpdateError(
            f'Duplicate PPPlayer archive sources detected ({locations}); refusing ambiguous update.'
        )

    target = matches[0]
    if target.module_name != 'ppplayer':
        raise ManifestUpdateError(
            f'PPPlayer archive source found in unexpected module {target.module_name!r}.'
        )

    url_entries = target.fields.get('url', [])
    sha_entries = target.fields.get('sha256', [])
    if len(url_entries) != 1:
        raise ManifestUpdateError(
            f'PPPlayer archive source must declare exactly one url: field (found {len(url_entries)}).'
        )
    if len(sha_entries) != 1:
        raise ManifestUpdateError(
            f'PPPlayer archive source must declare exactly one sha256: field (found {len(sha_entries)}).'
        )

    url_line_idx, old_url = url_entries[0]
    sha_line_idx, _old_sha = sha_entries[0]
    url_match = PPPLAYER_URL_RE.match(old_url)
    if not url_match or url_match.group(2) != archive_name:
        raise ManifestUpdateError(
            f'PPPlayer archive url {old_url!r} does not match expected GitHub Release pattern for {archive_name!r}.'
        )

    new_url = f'{url_match.group(1)}v{version}/{archive_name}'

    has_trailing_newline = content.endswith('\n')
    lines = content.splitlines()

    url_indent = lines[url_line_idx][: len(lines[url_line_idx]) - len(lines[url_line_idx].lstrip(' '))]
    sha_indent = lines[sha_line_idx][: len(lines[sha_line_idx]) - len(lines[sha_line_idx].lstrip(' '))]
    lines[url_line_idx] = f'{url_indent}url: {new_url}'
    lines[sha_line_idx] = f'{sha_indent}sha256: {sha256}'

    updated = '\n'.join(lines) + ('\n' if has_trailing_newline else '')

    # Self-verify that every non-target source remained identical and target matches.
    after_entries = parse_manifest_sources(updated)
    if len(after_entries) != len(entries):
        raise ManifestUpdateError('Internal verification failed: source count changed.')

    for before, after in zip(entries, after_entries):
        if before.module_name == target.module_name and before.start_line == target.start_line:
            if after.fields.get('url', [(0, '')])[0][1] != new_url:
                raise ManifestUpdateError('Internal verification failed: PPPlayer URL mismatch.')
            if after.fields.get('sha256', [(0, '')])[0][1] != sha256:
                raise ManifestUpdateError('Internal verification failed: PPPlayer SHA-256 mismatch.')
        else:
            if before.fields != after.fields:
                raise ManifestUpdateError(
                    f'Internal verification failed: unrelated source in module {before.module_name!r} changed.'
                )

    return updated


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description='Update only the PPPlayer archive URL and SHA-256 in a Flatpak manifest.'
    )
    parser.add_argument('--input', required=True, type=Path, help='Input manifest template path')
    parser.add_argument('--output', required=True, type=Path, help='Output manifest path')
    parser.add_argument('--version', required=True, help='Target app version without leading v (e.g. 4.0.2)')
    parser.add_argument('--sha256', required=True, help='64-char lowercase hex SHA-256 of the PPPlayer archive')
    parser.add_argument(
        '--archive-name',
        default='PPPlayer-Linux-x86_64.tar.gz',
        help='Expected release archive filename',
    )
    args = parser.parse_args(argv)

    if not args.input.is_file():
        print(f'Error: Input manifest not found: {args.input}', file=sys.stderr)
        return 1

    try:
        original = args.input.read_text(encoding='utf-8')
        updated = update_manifest_content(
            original,
            version=args.version,
            sha256=args.sha256,
            archive_name=args.archive_name,
        )
    except ManifestUpdateError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(updated, encoding='utf-8')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
