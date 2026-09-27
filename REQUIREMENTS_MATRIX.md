# Requirement Verification Matrix

This is a living gate document, not a claim of completion. `PENDING` rows are release-blocking. Evidence must name an automated result or dated manual record; assumptions are not evidence.

| Requirement group | Feature / layer | Current evidence | Status |
|---|---|---|---|
| Product identity | Name, version, BDT, Asia/Dhaka, English-first | package/config/schema review | PASS |
| Offline architecture | No runtime server/cloud; CSP restricted | architecture/config review | PASS |
| Bengali foundation | Bundled Noto Sans Bengali; UTF-8 SQLite | frontend production build includes Bengali face | PASS |
| Activation | Native derived verifier, no plaintext source value | Rust implementation; native tests pending CI | PENDING |
| Initial setup | Clinic, primary dentist, owner credentials, auto-lock setting | UI/native transaction; integration pending | PENDING |
| Database model | 45-table normalized initial migration, constraints/indexes | Python SQLite executes schema and foreign_key_check | PASS |
| Authentication/session | Argon2id, throttling, login, lock/logout/change password | Password primitive only | PENDING |
| Native RBAC | Permission guard on every protected command | Primitive test authored; command coverage incomplete | PENDING |
| Application shell | Header/sidebar/search/notifications/shortcuts | Not implemented | PENDING |
| Patients/visits/chart | Full workflows and timeline | Schema only | PENDING |
| Appointments/queue | Operational workflow | Schema only | PENDING |
| Prescriptions | Workflow, print, PDF, Bengali | Schema only | PENDING |
| Billing/payments | Exact invoice/payment allocation | Schema only | PENDING |
| Inventory/suppliers | Batch movement ledger | Schema only | PENDING |
| Accounting | Balanced journal and reports | Schema only | PENDING |
| Staff/users | Profiles/custom roles | Schema only | PENDING |
| Attachments | Managed transactional filesystem | Architecture/schema only | PENDING |
| Backup/restore | Validated container and atomic restore | Architecture/schema only | PENDING |
| Reports/search/notifications | Permission-aware workflows | Schema only | PENDING |
| Printing/PDF | Shared paper profiles and real preview | Architecture/schema only | PENDING |
| Frontend checks | lint/typecheck/unit/build | local lint/typecheck/build PASS; 3 tests PASS | PASS |
| Native checks | fmt/clippy/unit/integration | Local Rust unavailable; CI pending | PENDING |
| Dependency audit | npm high/critical vulnerabilities | `npm audit --audit-level=high`: 0 | PASS |
| Full license inventory | Direct + transitive generated notices | Preliminary direct inventory only | PENDING |
| Performance/security/recovery | Required suites and evidence | Not run | PENDING |
| Windows/DPI/printers | Required resolution, scale and device matrix | Not run | PENDING |
| Installer/clean machine/uninstall | Actual release artifact acceptance | Not run; no release artifact | PENDING |
| Pull request and CI | Review and all checks | Workflow authored; run pending | PENDING |
| Release EXE/checksum | Tested artifact and SHA-256 | Release prohibited until all rows pass | PENDING |
