# Testing

## Commands

```bash
npm ci
npm run lint
npm run typecheck
npm test
npm run build
cargo fmt --manifest-path src-tauri/Cargo.toml -- --check
cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings
cargo test --manifest-path src-tauri/Cargo.toml
npm run tauri build
```

## Layers

- TypeScript unit/component: validation, formatting, accessibility behavior and print layouts.
- Rust unit: activation verifier, password/session logic, permission guard, money and backup path safety.
- SQLite integration: migrations, constraints, pagination, RBAC bypass attempts, invoice/payment/ledger and stock transactions.
- End-to-end on Windows: activation → setup → login and all principal workflows.
- Document snapshots: A4/A5/80 mm/58 mm, multi-page, mixed Bengali/English and long content.
- Performance: seeded 10k/50k/100k patients and hundreds of thousands of timeline/financial rows; query budgets are recorded.
- Release smoke: install the produced artifact on a clean Windows VM, test restart/repair/uninstall and preserve user-data behavior.

A CI build is evidence only for checks it actually runs. Hardware printer, Bluetooth, sleep/wake, Windows scaling and clean-VM results are recorded manually in the release evidence rather than inferred.

## Mandatory Bengali corpus

- রহিম আহমেদ
- দাঁতে ব্যথা, মাড়ি থেকে রক্তপাত এবং সংবেদনশীলতা রয়েছে।
- প্রয়োজনে ব্যথা হলে ওষুধ সেবন করবেন।
- ৳ ১২,৫০০
