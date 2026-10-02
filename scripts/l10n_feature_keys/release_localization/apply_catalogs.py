"""Apply checked, explicit translations; never synthesize English fallbacks."""
import csv
import json
import re
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
ARB_DIRECTORY = DIRECTORY.parents[2] / "lib/l10n"


def arguments(text):
    return set(re.findall(r"\{([A-Za-z_]\w*)\s*[,}]", text))


def apply():
    locales = {file.stem[4:]: file for file in ARB_DIRECTORY.glob("app_*.arb")}
    updates = {locale: {} for locale in locales}
    for table in sorted(DIRECTORY.glob("*.tsv")):
        with table.open() as source:
            rows = list(csv.DictReader(source, delimiter="\t"))
        by_locale = {row.pop("locale"): row for row in rows}
        if len(rows) != len(by_locale) or by_locale.keys() != locales.keys():
            raise ValueError(f"{table.name}: duplicate or missing locales")
        for locale, messages in by_locale.items():
            for key, text in messages.items():
                if not key or not text or arguments(text) != arguments(by_locale["en"][key]):
                    raise ValueError(f"{table.name}: invalid message {locale}/{key}")
                if key in updates[locale]:
                    raise ValueError(f"Duplicate key: {key}")
                updates[locale][key] = text

    for locale, file in locales.items():
        data = json.loads(file.read_text())
        for key, text in updates[locale].items():
            if key in data and data[key] != text:
                raise ValueError(f"Refusing to overwrite existing translation: {locale}/{key}")
            data[key] = text
            if locale == "en":
                data["@" + key] = {"placeholders": {
                    name: {"type": "String"} for name in sorted(arguments(text))
                }} if arguments(text) else {}
        file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"Applied {len(updates['en'])} messages across {len(locales)} locales")


if __name__ == "__main__":
    apply()
