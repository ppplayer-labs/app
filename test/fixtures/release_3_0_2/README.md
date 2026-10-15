# Published 3.0.2 database schema fixture

The released app already used schema 14. Its generated Drift schema
`lib/core/db/app_database.g.dart` is byte-identical to the pre-preparation
4.0.0 candidate: SHA-256
`d6bf7b9e906dab7e47a19d0517a65b25ae70ddd25d168d9bb374134d1ccba9fa`.
`schema.sql` was exported from that schema using sqlite_master before any schema
changes, not inferred from the version number. Synthetic rows in the retained
upgrade test exercise this on-disk schema through fresh candidate connections.

This fixture is not a backup of a real user's private library and does not
replace a signed 3.0.2-to-4.0.0 installed-app upgrade, Hive/settings migration,
security-bookmark entitlement checks, or platform-specific file persistence.
