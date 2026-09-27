# Database

Dentiva Pro uses SQLite with migrations in `src-tauri/migrations`. SQLite is the authoritative source; dashboard values are queries over operational and ledger records, never editable counters.

## Conventions

- UUID text primary keys; human-readable patient/invoice codes have unique constraints.
- UTC RFC3339 timestamps; clinic display timezone defaults to `Asia/Dhaka`.
- Money uses signed 64-bit integer poisha (`*_minor`), never floating point.
- Soft archive columns preserve regulated history; posted financial rows are reversed, not deleted.
- Foreign keys are enabled for every connection. Destructive cascades are avoided for clinical/financial history.
- Partial and composite indexes support active records, date windows and patient timelines.
- `schema_migrations` records migration version and checksum.

## Financial model

Invoices and immutable items establish receivables. Payments are independent records and `payment_allocations` apply them to invoices. Refunds/adjustments are explicit records. Journal entries contain debit/credit lines; posting validates equal totals in one transaction. Reports aggregate these records using integer arithmetic.

## Stock model

`inventory_transactions` is the stock source of truth. Current quantity is derived per batch/item. Corrections create adjustments with reason and audit event; no command overwrites stock.

## Integrity

Startup uses `PRAGMA quick_check`; backup/restore uses `integrity_check` and manifest hashes. Migration and restore use exclusive transactions/staged atomic replacement. See migration 0001 for constraints and relationships.
