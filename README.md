# Dentiva Pro

Premium, offline-first Windows dental clinic management software for Bangladesh.

> **Build status:** active production implementation. Version 1.0.0 release gates have **not** been completed and no current artifact is represented as production-ready. See [`BUILD_STATE.md`](BUILD_STATE.md).

## Architecture

Dentiva Pro uses React and TypeScript for an accessible high-density UI, Tauri 2 and Rust for the trusted native boundary, and embedded SQLite for durable local data. It has no runtime cloud, telemetry, account service or activation server. English is the application language; UTF-8 Bengali data and documents use bundled Noto Sans Bengali. Currency is BDT and exact amounts are integer poisha.

Read [`ARCHITECTURE.md`](ARCHITECTURE.md), [`DATABASE.md`](DATABASE.md), and [`SECURITY.md`](SECURITY.md) before contributing.

## Development

Prerequisites:

- Node.js 22
- stable Rust toolchain
- Windows 10/11 for packaging and native acceptance tests
- Microsoft C++ Build Tools and WebView2 as required by Tauri

```bash
npm ci
npm run typecheck
npm run lint
npm test
npm run tauri dev
```

A production Windows candidate is compiled by `.github/workflows/ci.yml`. Publishing is separately gated by `.github/workflows/release.yml`; a successful compile alone is not a production release.

## Product data

Writable data follows Windows application-data conventions under `%LOCALAPPDATA%`, not the installation directory. Never commit a clinic database, backup, attachment or credentials. Development/test data must be synthetic and isolated.

## Documentation

- [Architecture](ARCHITECTURE.md)
- [Database model](DATABASE.md)
- [Security](SECURITY.md)
- [Testing](TESTING.md)
- [Release process](RELEASE.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Persistent build state](BUILD_STATE.md)
- [Requirement evidence](REQUIREMENTS_MATRIX.md)

## Attribution

Created and developed by **Shohan Khan**  
Contact: **helloiamshohan@gmail.com**

Copyright © 2026 Shohan Khan. Third-party components retain their respective licenses.
