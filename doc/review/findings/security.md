# Security Review Findings - OraDBA

Date: 2026-06-26 Repository: /Users/stefan.oehrli/Repos/own/oehrlis/oradba Version reviewed: 0.24.11
(target v1.0.0) Threat model: Oracle infrastructure - oracle-user and root execution, shared
servers, process-list (`ps`) exposure, multi-tenant `/tmp`.

Scope: analysis only. No framework source modified. Evidence cites `file:line`. Severity reflects
exploitability under the stated threat model, not theoretical worst case.

## Summary

| ID     | Title                                                                               | Severity                                                   |
|--------|-------------------------------------------------------------------------------------|------------------------------------------------------------|
| SEC-01 | DBCA writes SYS/SYSTEM passwords to predictable world-readable `/tmp` response file | Critical                                                   |
| SEC-02 | SEPS wallet password loaded from base64 file presented as a protection mechanism    | High                                                       |
| SEC-03 | GitHub release tarball installed without signature/checksum verification            | High                                                       |
| SEC-04 | \`curl ...                                                                          | bash\` install instructions without integrity verification |
| SEC-05 | RMAN catalog connect string reaches process args and DEBUG log                      | Medium                                                     |
| SEC-06 | `eval`-based array build in oraenv consumes oratab/homes fields                     | Medium                                                     |
| SEC-07 | RMAN temp dir uses predictable PID path with `mkdir -p` (no exclusive create)       | Medium                                                     |
| SEC-08 | `--sys-password` / `--system-password` passed on command line                       | Medium                                                     |
| SEC-09 | DBCA DEBUG command-string log line (defensive note)                                 | Low                                                        |
| SEC-10 | TNS_ADMIN tree created `chmod 755` (defensive note)                                 | Low                                                        |

----------------------------------------------------------------------------------------------------

## SEC-01 - DBCA writes SYS/SYSTEM passwords to predictable world-readable /tmp response file

- Severity: Critical
- Category: CWE-377 (insecure temporary file) + CWE-256/CWE-522 (plaintext credential storage) +
  CWE-377/CWE-367 (predictable path)
- Evidence:
  - `src/bin/oradba_dbca.sh:584` - `response_file="/tmp/dbca_${DB_SID}_$$.rsp"`
  - `src/bin/oradba_dbca.sh:182-183` - SYS_PASSWORD / SYSTEM_PASSWORD substituted verbatim into the
    response file body
  - `src/bin/oradba_dbca.sh:194` - file written with default umask, no `chmod`, no `mktemp`, no
    `O_EXCL`-equivalent
  - `src/bin/oradba_dbca.sh:613` - on DBCA failure the file is deliberately preserved
    (`Response file preserved`), leaving plaintext passwords on disk
  - `src/bin/oradba_dbca.sh:598` - dry-run prints first 20 lines of the file (may include password
    lines depending on template ordering)
- Exploit/exposure scenario: The path contains only `${DB_SID}` (often known or guessable, e.g.
  ORCL/CDB1) and the PID `$$` (small integer space, observable via `ps`/`/proc`). On a shared DB
  host any local user can:
  1. Pre-create or race the file, or
  2. Read it during the DBCA window (default umask 022 commonly yields a world-readable file; even
      027 leaves it group-readable to the oracle group, which on many sites includes operators). On
      a DBCA failure the credentials persist in `/tmp` indefinitely. These are SYS/SYSTEM passwords
      of a freshly created database - full DBA compromise.
- Recommendation: Create the response file with `mktemp` inside a per-run directory created
  `mode 700` (e.g. `mktemp -d -t oradba_dbca.XXXXXX`), or in `$ORACLE_BASE/cfgtoollogs` owned by
  oracle, and `chmod 600` before writing secrets. Register a `trap ... EXIT` to shred/remove it on
  all exit paths (including failure). Do not preserve a secret-bearing file on error - log the
  non-secret config separately. Prefer not to materialize passwords on disk at all: DBCA supports
  reading SYS/SYSTEM via stdin / interactive prompt with `-silent`, which avoids the file entirely.

----------------------------------------------------------------------------------------------------

## SEC-02 - SEPS wallet password loaded from base64 file presented as a protection mechanism

- Severity: High
- Category: CWE-261 (weak encoding for password) + CWE-522 (insufficiently protected credentials)
- Evidence:
  - `src/bin/get_seps_pwd.sh:84` - usage text: "stored in `.wallet_pwd` (base64 encoded)"
  - `src/bin/get_seps_pwd.sh:185-188` - `base64 -d "${WALLET_DIR}/.wallet_pwd"` with no
    file-permission/ownership check before reading
  - `src/bin/get_seps_pwd.sh:243` - normal (non-quiet) mode logs the recovered DB password in
    cleartext: `oradba_log INFO "  Password: ${password}"`
- Exploit/exposure scenario: base64 is encoding, not encryption; a `.wallet_pwd` file is trivially
  reversible by anyone who can read it. The defeats the purpose of the auto-login wallet (the whole
  point of SEPS is to avoid a readable password). The script never verifies the file is
  `600`/oracle-owned, so a group- or world-readable `.wallet_pwd` is silently accepted. Separately,
  the default-mode output at line 243 prints the retrieved database password to stdout/log; if
  `ORADBA_LOG_FILE` is set (as it is under the root service wrapper) the DB password lands in a log
  file.
- Recommendation:
  - Drop the documented base64-file mechanism, or rename/document it explicitly as obfuscation-only
    and refuse to read it unless it is `600` and owned by the current user (`stat`-check before
    `base64 -d`). Better: prefer an auto-login wallet (`cwallet.sso`) so no separate password file
    is needed, or source the wallet PIN from `op read` per project convention.
  - Never log the recovered password (line 243); restrict cleartext password to explicit `-q`/quiet
    stdout consumed by a caller, and route INFO/DEBUG to a channel that never carries the secret.
  - Note (positive): `get_entry`/`search_wallet` correctly pass the wallet password to `mkstore` via
    stdin (`echo ... | mkstore`), not on the command line - that part is sound and should be
    preserved.

----------------------------------------------------------------------------------------------------

## SEC-03 - GitHub release tarball installed without signature/checksum verification

- Severity: High
- Category: CWE-494 (download of code without integrity check) + CWE-345 (insufficient verification
  of data authenticity)
- Evidence:
  - `src/bin/oradba_install.sh:2065-2076` - tarball fetched via `curl -L -f` / `wget`, then
  - `src/bin/oradba_install.sh:2085` - `tar -xzf` and installed, with no verification against the
    published `.sha256` (the repo ships `dist/*.tar.gz.sha256` for exactly this purpose)
  - `src/bin/oradba_install.sh:2013` - latest-version lookup over the GitHub API; version string
    parsed and interpolated into the download URL
  - `src/bin/oradba_install.sh:2328-2338` - the only integrity check is `--verify-core`, which
    compares installed files against the project's own `.oradba.checksum` shipped inside the same
    tarball; this detects post-install corruption but provides zero protection against a tampered or
    man-in-the-middle download (the attacker controls both the files and the checksum manifest in
    that case)
- Exploit/exposure scenario: A network attacker (or a compromised CDN/mirror, or DNS spoofing) who
  can intercept the HTTPS download - or a future scenario where the download falls back to a non-TLS
  path - can substitute a malicious tarball. Because installs are frequently run as root or with
  `sudo --user oracle` (see SEC-04), the payload executes with high privilege. The self-referential
  checksum gives a false sense of integrity.
- Recommendation: Download the companion `oradba-${version}.tar.gz.sha256`, verify with
  `sha256sum -c` / `shasum -a 256 -c` against the downloaded tarball, and abort on mismatch before
  extraction. For stronger assurance, sign releases (minisign/GPG) and verify the signature with a
  pinned public key shipped in the installer. Fail closed if no verification tool is available
  rather than warning and continuing (`src/bin/oradba_install.sh:284`).

----------------------------------------------------------------------------------------------------

## SEC-04 - curl-pipe-bash install instructions without integrity verification

- Severity: High
- Category: CWE-494 (download of code without integrity check)
- Evidence:
  - `README.md:88` - `curl -sL .../oradba_check.sh | bash`
  - `README.md:268` - `curl -sL .../oradba_check.sh | bash -s -- --verbose`
  - `README.md:337` - `curl -L .../oradba_install.sh | bash`
- Exploit/exposure scenario: The documented one-liner pipes a remotely fetched script straight into
  `bash` with no checksum/signature step. Combined with the installer commonly being run as root,
  any compromise of the release asset, the GitHub account, or the transport results in arbitrary
  root code execution on the DB host. The repo already publishes `oradba_install.sh.sha256` and
  `oradba_check.sh.sha256`, so the safer flow exists but is not the headline instruction.
- Recommendation: Make the verified two-step the primary documented path: download to a file, fetch
  the `.sha256`, run `shasum -a 256 -c`, inspect, then execute. Keep the pipe form only as a clearly
  labelled convenience for throwaway environments. Document the expected checksum/fingerprint in the
  release notes.

----------------------------------------------------------------------------------------------------

## SEC-05 - RMAN catalog connect string reaches process args and DEBUG log

- Severity: Medium
- Category: CWE-214 (sensitive information in process arguments) + CWE-532 (information exposure
  through log files)
- Evidence:
  - `src/bin/oradba_rman.sh:726` - `rman_args+=" catalog ${RMAN_CATALOG}"`
  - `src/bin/oradba_rman.sh:727` - `oradba_log DEBUG "  Using RMAN catalog: ${RMAN_CATALOG}"`
  - `src/bin/oradba_rman.sh:748` - `"${rman_cmd}" ${rman_args} @"${processed_script}" ...` (RMAN
    invoked with the catalog string as an argument)
  - `src/bin/oradba_rman.sh:270-271` - `RMAN_CATALOG` sourced from a config file
    (`source "${config_file}"`)
- Exploit/exposure scenario: An RMAN catalog connect string is conventionally
  `rcvcat_user/password@catdb`. When set, it is placed on the RMAN command line (visible to any
  local user via `ps -ef`/`/proc/<pid>/cmdline` during the backup window) and written verbatim into
  the DEBUG log. The target database is authenticated via `target /` (OS auth - good), but the
  catalog credential is exposed.
- Recommendation: Pass catalog credentials to RMAN via the script body using `connect catalog ...`
  inside the processed `.rcv` (which is already a restricted-permission temp file) rather than on
  the command line, or use a catalog wallet/SEPS alias so no password appears in args. Redact the
  catalog string in the DEBUG log (show alias only, never the `user/pass` portion). Note: line 748
  also relies on intentional word-splitting of `${rman_args}`; that is acceptable here but should
  carry a `# shellcheck disable=SC2086` rationale comment.

----------------------------------------------------------------------------------------------------

## SEC-06 - eval-based array build in oraenv consumes oratab/homes fields

- Severity: Medium
- Category: CWE-78 (OS command injection via eval) / CWE-95 (eval injection)
- Evidence:
  - `src/bin/oraenv.sh:409` - `eval "${sids_var}+=(\"${sid}\")"`
  - `src/bin/oraenv.sh:419` - `eval "${homes_var}+=(\"${name}\")"`
  - data source: `src/lib/oradba_registry.sh:54-72` (parsed from oratab) and `:75-95` (parsed from
    `oradba_homes.conf`); `sid`/`name` are colon-delimited fields from those files
- Exploit/exposure scenario: The `sid` and `name` values are interpolated into an `eval` string
  inside double quotes. A field value containing a double quote followed by a command substitution
  (for example a crafted `oradba_homes.conf` alias/name like `x")$(touch /tmp/pwned)#`) can break
  out of the quoting and execute arbitrary code in the context of the user sourcing `oraenv`.
  Exposure depends on who can write oratab / `oradba_homes.conf`. On standard installs these are
  admin/oracle-owned, so this is not trivially attacker-controlled - hence Medium, not High - but
  oratab is frequently appended by varied tooling and is sometimes group-writable, making this a
  realistic privilege/lateral path (a less-privileged account that can edit the homes file gains
  code execution as anyone who later sources oraenv, e.g. the DBA).
- Recommendation: Replace `eval`-based array append with a nameref
  (`local -n arr="${sids_var}"; arr+=("${sid}")`) which is Bash 4.3+, or use `read -ra`/`printf -v`
  patterns that do not re-evaluate the value. If Bash 3.2 portability is required, validate
  `sid`/`name` against a strict allowlist (`[[ "${sid}" =~ ^[A-Za-z0-9_.]+$ ]]`) before any `eval`,
  and reject anything else. The same applies to the `eval "${homes_var}+=..."` path.

----------------------------------------------------------------------------------------------------

## SEC-07 - RMAN temp dir uses predictable PID path with mkdir -p

- Severity: Medium
- Category: CWE-377 (insecure temporary file/dir) + CWE-367 (TOCTOU)
- Evidence:
  - `src/bin/oradba_rman.sh:51` - `TEMP_DIR="${TMPDIR:-/tmp}/oradba_rman_$$"`
  - `src/bin/oradba_rman.sh:1048` - `mkdir -p "${TEMP_DIR}" || { ... }`
  - processed RMAN scripts written under `${TEMP_DIR}` (`src/bin/oradba_rman.sh:713`)
- Exploit/exposure scenario: The directory name is fully predictable (`$$` is observable).
  `mkdir -p` succeeds even if the path already exists, so a local attacker can pre-create
  `/tmp/oradba_rman_<pid>` (or a symlink) and then read or tamper with the generated `.rcv` scripts
  before RMAN consumes them. While the current `.rcv` content is backup directives rather than
  passwords, this enables injection of arbitrary RMAN commands executed against the target DB (which
  uses `target /` sysdba), and the predictable path is a general TOCTOU weakness.
- Recommendation: Use `TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/oradba_rman.XXXXXX")` so the kernel
  creates a fresh `700` directory and fails if it exists. Keep the existing `trap`-based cleanup.
  Verify ownership before use. The same hardening applies to any other `mkdir -p` of a `$$`-named
  temp path.

----------------------------------------------------------------------------------------------------

## SEC-08 - --sys-password / --system-password passed on command line

- Severity: Medium
- Category: CWE-214 (sensitive information in process arguments)
- Evidence:
  - `src/bin/oradba_dbca.sh:410-416` - `--sys-password` / `--system-password` accept the secret as
    `$2` on the command line
  - documented in `src/templates/dbca/README.md:121-122`
- Exploit/exposure scenario: Any password supplied via these flags is visible in `ps -ef` /
  `/proc/<pid>/cmdline` to every local user for the lifetime of the process, and is captured in
  shell history. The script does provide an interactive `read -rs` fallback
  (`src/bin/oradba_dbca.sh:520-527`), which is the safe path, but the CLI flags remain a footgun and
  are advertised as a primary option.
- Recommendation: Keep interactive prompt as the default. For automation, accept passwords only via
  stdin or via an env-var/`op read` reference that is read once and never re-exported, and document
  the `ps` exposure prominently if the flags are retained. Consider removing the plaintext flags
  entirely in favour of `--sys-password-stdin`.

----------------------------------------------------------------------------------------------------

## SEC-09 - DBCA DEBUG command-string log line (defensive note)

- Severity: Low
- Category: CWE-532 (information exposure through logs) - defense in depth
- Evidence:
  - `src/bin/oradba_dbca.sh:314,317` - `dbca_cmd` string built and logged at DEBUG. The string
    contains only the response-file path, not the passwords (passwords live inside the file), so
    this is not a direct secret leak today.
- Exploit/exposure scenario: Low risk as written. Flagged only because the command-string-building
  pattern invites future drift toward logging secret-bearing arguments. The real exposure is the
  file referenced (SEC-01).
- Recommendation: Keep secrets out of any `*_cmd` string that is logged; add a comment asserting the
  invariant so it survives refactors.

----------------------------------------------------------------------------------------------------

## SEC-10 - TNS_ADMIN tree created chmod 755 (defensive note)

- Severity: Low
- Category: CWE-732 (incorrect permission assignment) - defense in depth
- Evidence:
  - `src/bin/oradba_sqlnet.sh:208` - `chmod 755 "${tns_admin}" "${tns_admin}/admin" ...`
- Exploit/exposure scenario: `755` is not world-writable, so this is not an injection vector.
  However, the TNS_ADMIN tree may later hold `tnsnames.ora`, `ldap.ora`, and potentially
  wallet-adjacent material; world-readable directories expose connection topology to all local
  users. Low impact, but tighter defaults are preferable on a multi-tenant host.
- Recommendation: Consider `750` for the directories (oracle + oinstall group only) unless a
  documented requirement needs world traversal. Ensure any wallet or password-bearing file placed
  under this tree is independently `600`.

----------------------------------------------------------------------------------------------------

## Positive observations

- `set -euo pipefail` is applied consistently across reviewed scripts.
- `get_seps_pwd.sh` passes the wallet password to `mkstore` via stdin (`echo ... | mkstore`),
  avoiding command-line exposure of the wallet PIN (`src/bin/get_seps_pwd.sh:116,210`).
- `oradba_services_root.sh` enforces `check_root` and validates the oracle user and the target
  script before privilege transition; it passes a fixed action set (start/stop/restart/status)
  validated by a `case` allowlist, and the `su - oracle -c` argument is built only from that
  validated action - no attacker-influenced data reaches the `su` command string
  (`src/bin/oradba_services_root.sh:179-186,111`).
- The installer uses `mktemp -d` for its own working/preserve directories
  (`src/bin/oradba_install.sh:2165,2198`) and `rm -rf` only on those mktemp-derived variables.
- No hardcoded credentials or `op://` secrets were found in `src/`.

## Clarifications / items needing maintainer input (not evidenced as exploitable)

- SEC-03/SEC-04 severity assumes releases are not yet signed and that the `.sha256` is not currently
  verified in the documented flow. If a signing/ verification step exists outside the reviewed
  files, downgrade accordingly.
- SEC-06 exploitability hinges on the real-world write permissions of `/etc/oratab` and
  `oradba_homes.conf` on target deployments. If both are strictly root/oracle-owned and never
  group-writable in supported configs, the practical severity is lower (the injection vector
  requires write access to those files).
- Default umask on supported deployment hosts was not determined from the codebase; SEC-01 severity
  assumes a common 022/027 umask. The finding stands regardless because the script sets no explicit
  restrictive permission.
