"""Builds a multi-language Microsoft Store listing CSV from the en-us column."""
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from part1 import L as L1
from part2 import L as L2
from part3 import L as L3
from part4 import L as L4
from part5 import L as L5

LANGS = {}
for p in (L1, L2, L3, L4, L5):
    LANGS.update(p)

SRC = Path(sys.argv[1])
DST = Path(sys.argv[2])

with open(SRC, newline='', encoding='utf-8-sig') as f:
    rows = list(csv.reader(f))

header = rows[0]
en_idx = header.index('en-us')
existing = header[en_idx + 1:]
new_codes = existing + [c for c in sorted(LANGS) if c not in existing]
out_header = header[:en_idx + 1] + new_codes


def release_notes(n):
    return (f"{n[0]}\n\n{n[1]}\n" + "\n".join(f"- {x}" for x in n[2:6]) +
            f"\n\n{n[6]}\n" + "\n".join(f"- {x}" for x in n[7:10]) + f"\n\n{n[10]}")


def value(lang, field, en_val):
    d = LANGS[lang]
    if field == 'Description':
        return "\n\n".join(d['D']) + "\n"
    if field == 'ReleaseNotes':
        return release_notes(d['N'])
    if field == 'ShortDescription':
        return d['S']
    if field.startswith('Feature') and field[7:].isdigit() and int(field[7:]) <= 4:
        return d['F'][int(field[7:]) - 1]
    if field.startswith('SearchTerm') and field[10:].isdigit() and int(field[10:]) <= 7:
        return d['T'][int(field[10:]) - 1]
    if field == 'VoiceTitle':
        return "PP Player"
    if field in ('Title', 'ShortTitle', 'DevStudio', 'CopyrightTrademarkInformation', 'OverrideLogosForWin10'):
        return en_val
    return ''


with open(DST, 'w', newline='', encoding='utf-8-sig') as f:
    w = csv.writer(f, lineterminator='\r\n')
    w.writerow(out_header)
    for r in rows[1:]:
        r = r + [''] * (len(header) - len(r))
        field, en_val = r[0], r[en_idx]
        out = r[:en_idx + 1]
        for c in new_codes:
            out.append(value(c, field, en_val) if field and c in LANGS else '')
        w.writerow(out)
print(len(new_codes), 'locales written to', DST)
