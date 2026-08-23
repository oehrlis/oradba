# Review Brief: oradba, Boot Path and Lab Integration

> Input for a dedicated oradba session on repository, tooling and architecture.
> Written 2026-08-23 after a night of debugging on an OCI lab host running
> Oracle Linux 8 with Oracle Database 19c under systemd. Every finding below is
> reproduced on that host, not inferred from reading code.

## How this was found

A reboot test of the lab host `oradb01`. `oradba-services.service` was enabled
and had never once been started. Rebooting the host exposed six defects in a
row, each visible only after the one before it had been removed. Three patch
releases (1.0.1, 1.0.2, 1.0.3) came out of a single evening, and 1.0.3 turned
out not to contain the fix it described.

## Are these real defects, or did we create them?

**All six are real and pre-existing in v1.0.0.** None was introduced by the lab.
What the lab did was use oradba in a mode nobody had exercised before: a
non-interactive boot without a loaded environment.

Self-inflicted, for the record and separate from the above:

- The 1.0.1 fix stopped the abort but not the redirection noise, corrected in
  1.0.2.
- `/var/log/oracle` was created root-owned as a side effect of that fix and had
  to be handed to `oracle:oinstall` afterwards.
- The `oradba_core.conf` change was lost twice between edit and commit, which
  is why 1.0.3 shipped incomplete and had to be followed by 1.0.4. Process
  error on the editing side; see M3, which also records a hypothesis about the
  test suite that turned out to be wrong.

## The defect class

One class, six instances: **a bare `${VAR}` reference under `set -euo pipefail`
aborts the script when the caller's environment does not define the variable.**

| # | Location | Symptom |
| --- | --- | --- |
| 1 | `src/bin/oradba_services_root.sh:189` | `log_message: command not found`, exit 127 |
| 2 | `src/lib/oradba_common.sh` `oradba_log` | a log write aborts its caller |
| 3 | `src/bin/oradba_lsnrctl.sh:161` | `TNS_ADMIN: unbound variable`, listener never starts |
| 4 | `src/etc/oradba_core.conf:30` | `ORADBA_LOCAL_BASE: unbound variable` while sourcing own config |
| 5 | `src/lib/oradba_env_parser.sh:19` | include guard aborts on first load |
| 6 | `src/bin/oraenv.sh:1368` | `ORACLE_HOME: unbound variable` |

Total after the sweep: 291 guarded `[[ ]]` tests across `src/etc/`, `src/lib/`
and `src/bin/`.

**Why it stayed invisible.** An interactive shell has sourced the oradba
profile, so `ORACLE_HOME`, `ORACLE_SID` and `TNS_ADMIN` are set and `set -u`
never fires. systemd starts through `su - oracle -c` with no profile at all.
Verifying a service script from an interactive session proves nothing about
boot. Notably, `oraenv.sh:1369` already used `${LD_LIBRARY_PATH:-}` one line
below the defect - the pattern was known, just applied inconsistently.

## Requirements to hold oradba against

Stated by Stefan, 2026-08-23:

1. oradba is the **interactive toolbox** for working in an Oracle environment:
   aliases, scripts, tools, environment variables.
2. It **must be installed by default on every lab system** so it is available
   interactively.
3. Scripts **must run both with and without `oraenv.sh` loaded**. Without it
   they have to source it themselves.

Requirement 3 is what the code already intends - `oradba_dbctl.sh` sources
`oraenv.sh` itself and derives `ORACLE_HOME` from oratab. The design was never
the problem; the loading path was.

Requirement 2 is **currently not met on the lab**, see M1 below.

## Findings for the review session

### M1 - The installer wires the wrong user's profile

`oradba_install.sh` has profile integration (around line 796) that writes the
`oraenv.sh` source line into `${HOME}/.bash_profile`. The oci-labs Ansible role
runs the installer with `become: true`:

```yaml
- name: Install oradba into the target prefix
  become: true
  ansible.builtin.command:
    cmd: "{{ db19_stage_dir }}/oradba_install.sh --prefix {{ db19_oradba_dir }}"
```

`${HOME}` is therefore `/root`, and `/home/oracle/.bash_profile` on `oradb01` is
the untouched Oracle Linux stock file. Confirmed on the host:

```text
su - oracle -c 'echo $ORACLE_HOME $ORACLE_SID $TNS_ADMIN $ORADBA_BASE'
=> all four empty
```

Open question for the session: whose job is this? Options are an installer flag
(`--user oracle` / `--profile-user`), a documented post-install step, or the
consuming automation. Today it is nobody's, so requirement 2 fails silently.

### M2 - No regression test covers the boot path

Every one of the six defects was found by rebooting a real host by hand. A
container that runs `oradba_services.sh start --force` with an empty
environment and no profile would have caught the entire cascade in one run -
including the fact that 1.0.3 did not fix what it claimed.

This is the single highest-value addition to the repository. It is also cheap:
`oehrlis/oracle-database-docker-legacy` already builds Oracle images.

### M3 - Withdrawn: the test suite does not mutate sources

An earlier version of this brief suspected `bats` of reverting
`src/etc/oradba_core.conf`, because the file lost its fix twice between a
verified edit and the commit, with a test run in between each time.

**A controlled experiment disproved it.** `tests/test_installer.bats` was run
against a patched working copy; the file was byte-identical before and after.
The cause was process error on the editing side, not the test suite. Nothing to
investigate here - the finding is recorded only so nobody chases it again.

The real lesson is a process one and applies to any release: **verify the
committed tag content, not the output of the patching step.** Both losses were
invisible in the patch output, which reported success, and both would have been
caught by one `git show <tag>:<file>`.

### M4 - Seven test failures have survived three tagged releases

```text
not ok  installer has preserve_configs function
not ok  generate_sid_aliases creates rlwrap aliases when rlwrap is available
not ok  sqh alias connects with sysdba when rlwrap available
not ok  show_status calls setup_connector_environment
not ok  oradba_version.sh --info shows comprehensive information
not ok  datasafe_plugin.sh supports ORADBA_CACHED_PS environment variable
not ok  datasafe_plugin.sh falls back to ps -ef when no cache
```

Identical in v1.0.1, v1.0.2 and v1.0.3, so not a regression from this work.
Neither CI nor the release workflow blocks on a red suite - `release-check`
calls `make check`, but a red result does not stop the release. That gate is
why seven failures reached three tags unnoticed.

`installer has preserve_configs function` is worth a look on its own merits -
config preservation during `--update` interacts directly with M6.

### M5 - `--force` semantics are inconsistent across the call chain

`oradba_services_root.sh` calls `oradba_services.sh <action> --force`, which
forwards `--force` to `oradba_lsnrctl.sh` and `oradba_dbctl.sh`. That works.
But `oradba_dbctl.sh` without `--force` asks for a free-text **justification**
on stdin when operating on all databases, and cancels when it gets none.

For an interactive tool that is a defensible guard. For anything unattended it
is a trap, and it is invisible until the environment happens to be
non-interactive. Worth deciding explicitly: should a non-TTY stdin imply
`--force`, or fail with a clear message naming the flag?

### M6 - The installer cannot upgrade in place without a flag

The oci-labs role checks whether the target directory exists and skips
installation if so. An upgrade needs `db19_oradba_force_install=true`. This is
an oci-labs gap rather than an oradba one, but it interacts with oradba's own
`--update` mode and its config-preservation behaviour, which the review should
clarify: what exactly does `--update` preserve, and does it ever restore an
older config over a newer shipped one?

### M7 - Logging design

Two related points, both fixed but worth a design decision:

- `init_logging` carefully picks a writable directory and falls back to
  `${HOME}/.oradba/logs`. Six scripts bypass it by setting `ORADBA_LOG_FILE`
  directly: `oradba_services.sh`, `oradba_services_root.sh`, `oradba_dbctl.sh`,
  `oradba_lsnrctl.sh`, `oradba_dsctl.sh`, `oradba_rman.sh`. They therefore never
  get the fallback. Should they call `init_logging`, or is the direct
  assignment intentional?
- `_oradba_log_to_file` now creates the log directory on demand. When the caller
  is root this produces a root-owned `/var/log/oracle` that the `oracle` user
  cannot write. Either the installer should create and chown it, or the helper
  should not create system directories at all.

## Additional requirements from the CPU patch lab

These are things the lab needs and currently reimplements, which arguably belong
in oradba. Deciding this is the point of the session; the list is the input.

### Already in oradba but unused by the lab

| Asset | oradba | Lab today |
| --- | --- | --- |
| dbca response files 19c and 26ai | `src/templates/dbca/{19c,26ai}/*.rsp` | own `dbca.rsp.j2` |
| sqlnet templates | `src/templates/sqlnet/` | own `listener.ora.j2`, `tnsnames.ora.j2` |
| systemd unit | `src/templates/systemd/` | own `oradba-services.service.j2` |

The lab duplicates all three. Either oradba is the canonical source and the lab
consumes it, or the templates in oradba are dead weight. Both are defensible;
the current state is not.

### Not in oradba, currently four times elsewhere

AutoUpgrade is invoked from `oci-labs` (Ansible), `odb_autoupgrade` (shell),
`oracle-database-docker-legacy/scripts/au_*.sh` and
`cpu-patch-tests/scripts/au_*.sh`. The invocation itself is one line and needs
no abstraction. What is genuinely duplicated is **data**:

| Asset | Why it belongs in one place |
| --- | --- |
| AutoUpgrade cfg templates (download, create_home, deploy) | four dialects of the same file |
| Patch list vocabulary (`RU:x,JDK,OPATCH,OJVM,DPBP` vs `RECOMMENDED:x,JDK`) | a convention, not code |
| MOS keystore creation incl. the expect handling for the password | the only genuinely tricky part, duplicated four times |
| Post-patch verification and smoke SQL | today embedded in Ansible tasks; will be written a second time the moment a Docker build wants a smoke test |

The last row is the important one. The verification logic is the expensive,
hard-won asset of the CPU lab. As long as it lives inside Ansible task files it
cannot be reused by a container build or an on-premises run.

Suggested shape, to be challenged in the session: ship them as **data**, not as
an execution layer. Jinja renders them for Ansible, `envsubst` for a Dockerfile,
plain `.sql` files run from either. No extension mechanism, no dependency.

## Suggested scope for the session

1. Decide M1 (profile wiring ownership) - blocks requirement 2.
2. Decide M2 (boot-path regression test) - highest value, prevents recurrence.
3. Decide M5 (`--force` and justification semantics for unattended use).
4. Triage M4 (seven failures) and add a release gate.
5. Decide the asset question: is oradba the canonical home for dbca rsp,
   sqlnet, systemd, AutoUpgrade cfg and verification SQL, or not?

Items 3 and 4 are cheap. Item 5 is the architectural one and should probably
not be decided in the same sitting as the bug fixes. M3 needs no work.
