# Dentiva Pro Build State

**Updated:** 2026-09-27 UTC  
**Branch:** `arena/01a0e432-dentiva-official-app-windows`  
**Version:** 1.0.0  
**Phase:** Architecture and foundation — in progress

## Verified completed

- [x] Inspected repository, Git remote, branch, Actions and local toolchain.
- [x] Confirmed repository began with README only; no inherited implementation or CI.
- [x] Selected Tauri 2 / Rust / React TypeScript / SQLite architecture.
- [x] Defined trust boundaries, local storage, security, printing, recovery and release strategy.
- [x] Created pinned frontend build/test/lint foundation.
- [x] Designed initial normalized SQLite schema and indexes.
- [x] Added native activation derivation approach without storing the activation code as plaintext.

## Current task

Implement and validate native foundation: migration runner, secure activation/setup state, Argon2 authentication, session lock and native command-level RBAC.

## Pending sequence

1. Complete native foundation and integration tests.
2. Build design system, activation and setup flows.
3. Implement shell, authentication/locking, navigation and permission-aware search.
4. Implement patients, visits, dental chart, timeline and attachments.
5. Implement appointments and queue.
6. Implement treatments and prescriptions.
7. Implement invoices, payments and exact ledger accounting.
8. Implement inventory, suppliers and purchases.
9. Implement staff/users/custom roles.
10. Implement notifications, reports and settings.
11. Implement backup/restore and import/export.
12. Implement unified print/PDF profiles and Bengali document test corpus.
13. Complete automated, performance, security and recovery suites.
14. Perform UX, database, dependency/license and full requirement audits.
15. Run Windows CI, clean VM installer/uninstaller test, then and only then produce release artifact.

## Test results

- Frontend lint: PASS (2026-09-27, local).
- TypeScript strict type-check: PASS (2026-09-27, local).
- Frontend production build: PASS (2026-09-27, local; bundled Inter and Noto Sans Bengali emitted).
- Component tests: PASS, 3/3 (activation malformed-input boundary and setup required-field behavior).
- npm high/critical vulnerability audit: PASS, 0 findings.
- SQLite migration smoke: PASS, 45 tables, no foreign-key violations.
- Native Rust tests: pending Windows CI. Local Rust provisioning failed because `sh.rustup.rs` was unreachable; this is recorded rather than treated as a pass.

## Known issues / constraints

- Clean Windows VM, physical printer, Bluetooth printer and Windows DPI testing require Windows infrastructure and cannot be honestly claimed from this Linux workspace.
- Publisher code signing requires a real certificate supplied through protected repository secrets. Unsigned artifact behavior must be disclosed if none is available.
- No release artifact exists; release gates prohibit creating one at this phase.

## Next exact action

Run frontend dependency installation, finish the Rust application skeleton and migration tests, install/provision Rust locally, then execute formatting, lint, type-check and unit tests. Do not move to feature UI until foundation checks pass.
