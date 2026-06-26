# Security Policy

## Supported Versions

Security fixes are applied to the latest release only.

| Version | Supported          |
|---------|--------------------|
| Latest  | :white_check_mark: |
| Older   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Report vulnerabilities by email to: **<stefan.oehrli@oradba.ch>**

Include in your report:

- Description of the vulnerability and potential impact
- Steps to reproduce or proof-of-concept
- Affected version(s)
- Any suggested remediation if known

You will receive an acknowledgement within **48 hours** and a status update within
**7 days** indicating whether the report has been accepted or declined.

If accepted, we will coordinate a fix and disclosure timeline with you. We aim to
release patches within **30 days** of confirmation for critical issues.

## Scope

This policy covers the `oradba` toolset:

- Shell scripts in `src/bin/` and `src/lib/`
- The installer (`oradba_install.sh`) and its build pipeline
- Configuration defaults shipped with the package

**Out of scope:**

- Oracle Database itself — report Oracle product vulnerabilities to
  [Oracle Security](https://www.oracle.com/corporate/security-practices/assurance/vulnerability/reporting.html)
- Vulnerabilities requiring physical access to the host
- Issues in third-party tools invoked by oradba (sqlplus, rman, etc.)

## Security Design Notes

- Scripts run with the invoking user's privileges; no setuid/setgid bits
- No credentials are stored or transmitted by oradba scripts
- `shellcheck` linting enforced in CI at `-S warning` level
- `set -euo pipefail` on all executable scripts

### Verified install flow

- When installing from a GitHub release, the installer downloads the companion
  `.sha256` file and verifies the tarball before extraction. Verification uses
  `shasum -a 256 -c` (macOS/BSD) and falls back to `sha256sum -c` (Linux).
- If neither checksum tool is available, the installer fails closed and aborts
  rather than installing an unverified payload.

### Wallet password file requirements

- `get_seps_pwd.sh` can read a wallet password from `${WALLET_DIR}/.wallet_pwd`.
- This file must be mode `600` and owned by the current user; otherwise the
  script refuses to read it and exits non-zero.
- The base64 layer in `.wallet_pwd` is obfuscation only, not encryption - the
  file permissions are the security control.
- Recovered passwords are never written to logs; only quiet mode emits the value
  to stdout for script consumption.

### Temp-file handling

- Scripts that write secret-bearing temporary files (DBCA response files, RMAN
  scripts) use `mktemp` for exclusive creation under a private directory and clean
  up via `EXIT`/`RETURN` traps on all exit paths, including failure.
