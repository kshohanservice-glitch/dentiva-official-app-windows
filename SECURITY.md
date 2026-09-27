# Security Model

## Controls

- Native-side, deny-by-default authorization for every protected operation.
- Argon2id password hashes with unique salts; no recoverable passwords.
- PBKDF2-derived activation verifier in the native binary; activation input is never persisted or logged.
- Opaque in-memory sessions, idle lock, generic authentication failures and throttled repeated attempts.
- Parameterized SQL, strict command DTO validation, database constraints and bounded inputs.
- Canonical managed attachment paths; generated filenames; MIME/signature/size checks; no user-controlled path joins.
- Immutable audit model: application users receive no update/delete path; each row includes a hash chained to the prior row.
- Exact integer money, balanced journal constraints in business transactions, immutable posted entries.
- Backup manifests and all payloads are SHA-256 verified before restore; extraction rejects absolute paths, `..`, links and unlisted files.
- CSP denies remote resources. Runtime needs no network service and emits no telemetry.

## Local threat statement

The application protects against ordinary unauthorized use, UI bypass, malicious input and casual local inspection. An offline executable and a machine administrator cannot be made cryptographically unmodifiable. Activation is therefore described as tamper-resistant, not unbreakable. Full database-at-rest encryption is not claimed in 1.0.0; Windows account ACLs and protected secrets are used. Clinics should use BitLocker for stolen-device protection.

## Sensitive logging

Passwords, activation input, session tokens, clinical body text, National IDs and attachment contents are never logged. Operational logs contain redacted entity IDs, error class, app version and correlation ID. Ordinary users never see stack traces.

## Reporting a vulnerability

Do not open a public issue containing patient information. Contact `helloiamshohan@gmail.com` with a minimal, de-identified reproduction.
