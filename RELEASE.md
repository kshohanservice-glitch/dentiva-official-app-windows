# Release Procedure

Version 1.0.0 is the fixed Dentiva Pro production version.

1. Complete every gate in `BUILD_STATE.md` and `REQUIREMENTS_MATRIX.md`; unresolved mandatory rows block release.
2. Ensure a clean tree and run all commands in `TESTING.md`.
3. Run performance, security, Bengali document and recovery suites; attach evidence.
4. Open a PR from the Arena session branch. Obtain review and passing CI.
5. On a clean Windows VM, build the signed-or-explicitly-unsigned NSIS installer through GitHub Actions.
6. Install the actual artifact; execute the release smoke checklist including offline mode, restart, backup/restore and uninstall.
7. Generate `SHA256SUMS.txt` with `Get-FileHash -Algorithm SHA256`.
8. Publish the installer, checksums, release notes, test summary and dependency inventory in a GitHub release.

Do not call a development build a release. SmartScreen may warn for an unsigned binary; a code-signing certificate is an external publisher credential, not something this repository can invent.
