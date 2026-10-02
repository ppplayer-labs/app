# Release interface translations

These TSV files contain explicit translations for all 38 app languages. They cover output selection, AirPlay, settings headings, playback controls, subtitles, network-stream forms and common feedback. Branded names, media metadata and developer diagnostics remain recognizable.

Run `python3 scripts/l10n_feature_keys/release_localization/apply_catalogs.py` from the app directory to validate and apply the tables, then `flutter gen-l10n`. Every table must contain each supported locale exactly once; values and interpolation arguments must be present. The updater rejects conflicting existing messages. When reviewing a translation already applied, edit both its TSV entry and ARB entry before regenerating. No translation service or English-fill behavior is used.

The generated Dart files are checked in. Widget tests under `test/features/network_outputs/output_localization_test.dart` exercise all languages at 320 pixels, right-to-left direction and selected device labels. Runtime translations in dismissed context menus must be captured before asynchronous work rather than read from a disposed BuildContext.

`lib/l10n/app_localization_delegates.dart` supplies the Material/Cupertino navigation and editing labels used by the app for Guarani and Nigerian Pidgin, which Flutter does not provide. Inherited calendar/time-picker messages are not localized by these supplemental delegates; PPPlayer does not expose those widgets. New uses of such widgets require extending the catalogs.

Translations still benefit from native-speaker review. Catalog completeness and automated layout checks do not establish linguistic accuracy.
