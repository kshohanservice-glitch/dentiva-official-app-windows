# Dentiva Pro Architecture

## Decision record

**Version:** 1.0.0  
**Target:** Windows 10/11 x64, offline after installation

Dentiva Pro uses **Tauri 2 + Rust + React/TypeScript + SQLite**. Tauri was selected over Electron because WebView2 is supplied by modern Windows, the distributable and idle memory footprint are materially smaller, and the privileged boundary can be kept in strongly typed Rust. A web UI is appropriate for dense, accessible forms and print CSS; no HTTP server is present in production.

## Trust boundaries

```text
React UI (untrusted presentation)
  | typed Tauri invoke; no SQL, paths, secrets, or authorization decisions
Rust command adapters
  | schema validation + authenticated session + permission check
Application services
  | transactions, invariants, audit append
Repositories
  | parameterized SQL only
SQLite + managed files under %LOCALAPPDATA%/Dentiva Pro/
```

The UI may hide forbidden actions for usability, but every native command authorizes independently. Record identifiers are opaque UUIDs. Money is stored as integer poisha. Timestamps are UTC RFC3339 and presented in Asia/Dhaka.

## Runtime layout

- `src/`: React presentation, feature modules, reusable design system, print templates.
- `src-tauri/src/commands`: narrow IPC adapters.
- `src-tauri/src/domain`: business rules and exact-money types.
- `src-tauri/src/db`: connection, migrations and repositories.
- `src-tauri/src/security`: password hashing, activation, sessions, authorization.
- `src-tauri/migrations`: append-only SQL migrations.
- `%LOCALAPPDATA%/Dentiva Pro/data/dentiva.sqlite3`: primary database.
- `%LOCALAPPDATA%/Dentiva Pro/attachments/<clinic>/<patient>/<uuid>`: managed attachment payloads.
- `%LOCALAPPDATA%/Dentiva Pro/logs`: rotating, redacted operational logs.
- User-selected directories: backups and exports.

SQLite uses WAL, foreign keys, busy timeout, secure delete, and transactional migrations. A single application writer plus short transactions avoids lock contention. Search is indexed and result sets are paginated. Attachment copies use staging files, validation, fsync, atomic rename, then a metadata transaction.

## Major subsystems

### Identity and security

Activation verification runs only in Rust against a PBKDF2-HMAC-SHA256 derived value using constant-time comparison. Activation state is a versioned, integrity-protected local record bound to a stable installation identifier and protected with Windows DPAPI in production. It is deliberately resistance against casual extraction, not an unbreakable offline license.

Passwords use Argon2id with per-user random salt. Sessions are process-memory capabilities with idle and absolute expiry. Passwords and activation input are never logged. RBAC uses explicit permissions joined through user roles. Commands use deny-by-default permission guards.

### Storage and recovery

All writes use transactions. Database migrations run after a pre-migration backup and are tracked by checksum. SQLite WAL is checkpointed before backup. Backups are deterministic ZIP-compatible `.dpb` containers containing a manifest, database, settings, attachments, and SHA-256 inventory. Restore extracts into staging, rejects traversal/symlinks, validates hashes and SQLite integrity, creates a pre-restore backup, then swaps directories atomically with rollback.

### Printing/PDF

One document model drives print preview, Windows printing and PDF. Paper profiles define physical dimensions/margins/orientation for A4, A5, 80 mm, 58 mm and custom stock. HTML/CSS paged media is rendered by WebView2 for preview and the Windows print dialog; Save as PDF is available through the print pipeline. Inter and Noto Sans Bengali are bundled and print styles embed/use the Bengali face. Thermal profiles switch to stacked content instead of scaling desktop tables.

### UI

React feature slices call a typed IPC client. React Router owns deep links; route guards improve UX but are not a security control. The design uses an 8 px rhythm, 272/76 px sidebar, 44 px minimum controls, visible focus, reduced-motion support and fluid CSS Grid. Tables query native paginated endpoints. Unsaved forms stay mounted under the lock overlay.

## Failure recovery

- Transactions guarantee all-or-nothing domain writes.
- Startup validates migration history and runs `quick_check`; failures enter a recovery screen without mutating data.
- Temporary files have operation IDs and are cleaned only after age/ownership checks.
- UI error boundaries provide retry and a redacted diagnostic ID.
- Backups/restores and large imports report progress and support safe cancellation boundaries.
- Finalized financial and clinical documents are amended/reversed, never silently rewritten.

## Build and release

Dependencies are pinned by `package-lock.json` and `Cargo.lock`. Linux CI performs frontend checks and Rust tests; Windows CI packages NSIS and MSI bundles. Release is gated on all tests and a version tag. Artifacts include SHA-256 checksums and build provenance. Code signing requires an optional organization-owned certificate and is not fabricated by this repository.
