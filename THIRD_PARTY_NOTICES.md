# Third-Party Notices

Dentiva Pro source uses free/open-source dependencies. Exact resolved direct and transitive versions are recorded in `package-lock.json`, `Cargo.lock`, and CI-generated license reports.

Primary direct components planned/used:

| Component | Purpose | License | Status |
|---|---|---|---|
| Tauri 2 | Windows desktop shell and IPC | Apache-2.0 / MIT | Compatible |
| React | UI rendering | MIT | Compatible |
| React Router | Routing | MIT | Compatible |
| Vite | Frontend build | MIT | Compatible |
| TypeScript | Static typing | Apache-2.0 | Compatible |
| Lucide React | Icons | ISC | Compatible |
| Zod | UI validation | MIT | Compatible |
| date-fns | Date helpers | MIT | Compatible |
| rusqlite / SQLite | Local database binding / engine | MIT / public domain | Compatible |
| Argon2 | Password hashing | Apache-2.0 / MIT | Compatible |
| Noto Sans Bengali | Bengali font | SIL Open Font License 1.1 | Compatible; attribution required |
| Inter | UI font | SIL Open Font License 1.1 | Compatible; attribution required |

This hand-maintained table is not the final audit. CI must generate a complete inventory including transitive dependencies and fail on disallowed licenses before release. Full upstream copyright/license texts will be bundled with the final application and repository after dependencies and fonts are locked.
