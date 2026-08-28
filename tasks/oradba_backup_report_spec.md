# Specification - oradba_backup_report.sh

Backup schedule and runtime observability for the OraDBA toolset.

- Status: Draft for implementation in Claude Code (oradba repo)
- Scope: v1 = observability only. Config generation is v2 (see section 15).
- Target location: `src/bin/oradba_backup_report.sh`, libs in `src/lib/`,
  SQL in `src/sql/`, config template in `src/etc/`.

------------------------------------------------------------------------

## 1. Purpose

Provide a node-local, catalog-independent way to answer three questions per
Oracle database and, optionally, across a fleet:

1. What backup schedule is configured (from crontab)?
2. What did the backups actually do (start, end, elapsed, status, size)?
3. Is the archivelog backup healthy (gaps in what was backed up, and lag
   behind the current sequence)?

The tool reads observed reality. It does not change crontab, does not run
backups, and does not manage a desired-state model. Those belong to v2.

Motivation: manual crontab edits caused overlapping inc0/inc1 windows and, in
one incident, a remote PDB clone failed because the source archive backup had
already purged the redo the clone still needed. Both failure classes are
observable from the data this tool collects (host contention from schedule +
runtime, archive-gap risk from the archivelog lag metric).

------------------------------------------------------------------------

## 2. Non-goals (v1)

- No crontab generation, no desired-state YAML model, no deploy.
- No log-file parsing. Runtime comes from the database (`V$` or catalog).
  If the instance is down, there is simply no datapoint.
- No transport layer. Copying fragments between hosts is done outside oradba
  (e.g. an existing `sync_to_peers.sh`); `merge` only consumes a directory of
  fragments that are already present locally.
- No collision linter (that is a v2 concern once a desired-state model exists).
  v1 surfaces overlaps visually and reports archive gaps, but does not gate CI.

------------------------------------------------------------------------

## 3. Architecture and data flow

Local-first. Each host produces JSON fragments for its local databases. An
optional, separate aggregation step renders a fleet overview.

```text
   per host (default)                         aggregation (optional)
   ------------------                         ----------------------
   crontab -l (oracle) ─┐
                        ├─► collect ─► fragment JSON per (host,sid)
   V$ / RMAN catalog  ──┘                    │
                                             │  (fragments copied together
                                             │   by external tooling)
                                             ▼
                                        merge ─► merged JSON
                                             │
                                             ├─► render ─► SVG / HTML grid
                                             └─► gaps   ─► archivelog report
```

- `collect` runs on the DB host, needs only local access (crontab of the
  executing oracle user + a local DB connection). No SSH, no central catalog
  requirement.
- `merge` and `render` are pure data transforms and can run anywhere the
  fragments have been gathered (a peer host, the OEM node, a workstation).

------------------------------------------------------------------------

## 4. Source model and precedence

Per database, the runtime source is chosen as follows:

1. `rman.conf` present at `$ORACLE_BASE/admin/$ORACLE_SID/etc/rman.conf` and it
   defines a catalog connect string, and the catalog is reachable
   -> source = `catalog` (query `RC_*` views through the catalog connect).
2. Otherwise (nocatalog, missing rman.conf, or catalog unreachable)
   -> source = `controlfile` (query local `V$` views via `/ as sysdba`).
   If this is a fallback from an intended catalog connect, the fragment is
   flagged `source_degraded=true` with a `degraded_reason`, and a warning is
   logged. Collection still succeeds.
3. Instance not at least MOUNTED -> no datapoint. The SID is reported as
   unavailable; exit status reflects partial collection (section 8.6).

Notes:

- `V$RMAN_BACKUP_JOB_DETAILS` reads from the controlfile, which is available in
  MOUNTED state - OPEN is not required.
- `rman.conf` is written by tvdbackup / `oradba_backup.sh` and already carries
  the correct per-SID catalog connect (user/password or a secure external
  password store reference). Because the connect string is per-SID, the
  schema-per-DB-version problem (different catalog owners like `rman19`,
  `rman21` for different DB versions) is solved by construction: the tool uses
  whatever `rman.conf` provides and does not auto-detect a schema. This is an
  assumption to confirm (section 16).
- No 1Password / `op read` at customer sites. Catalog credentials come from
  `rman.conf` only. `op read` remains available for the author's local use but
  must never be a hard dependency of this script.

------------------------------------------------------------------------

## 5. Data model - JSON fragment

One fragment file per `(host, sid)`. Default location is the oradba install
base central log/report area (not `$ORACLE_BASE/admin`):

```text
${ORADBA_BASE}/log/backup_report/backup_report_<host>_<sid>_<YYYYMMDD_HHMMSS>.json
```

Use the existing oradba central logging location; `ORADBA_BASE` is the install
base resolved by the standard oradba environment.

Schema (`schema_version` "1.0"):

```json
{
  "meta": {
    "schema_version": "1.0",
    "generated_at": "2026-08-03T11:53:17+02:00",
    "host": "sv10162",
    "sid": "CPAX01H",
    "db_name": "CPAX01",
    "source": "controlfile",
    "source_degraded": false,
    "degraded_reason": null,
    "oradba_version": "1.2.3",
    "basenv_mode": "basenv",
    "collect_days": 28
  },
  "schedule": [
    {
      "type": "inc0",
      "service": "usz_bck_inc0",
      "minute": 30, "hour": 21,
      "dom": "*", "month": "*", "dow": "5",
      "raw": "30 21 * * 5"
    }
  ],
  "jobs": [
    {
      "class": "inc1",
      "input_type": "DB INCR",
      "start": "2026-08-01T22:30:02",
      "end":   "2026-08-02T00:07:56",
      "elapsed_s": 5874,
      "status": "COMPLETED",
      "input_bytes": 123456789,
      "output_bytes": 23456789,
      "compression_ratio": 5.26,
      "output_device_type": "DISK"
    }
  ],
  "archivelog": {
    "window_first_time": "2026-07-06T00:12:00",
    "window_next_time":  "2026-08-03T08:45:00",
    "seq_count": 4123,
    "thread_count": 1,
    "gaps": [
      { "thread": 1, "gap_start_seq": 79680, "gap_end_seq": 79682,
        "gap_after_time": "2026-07-30T18:55:00" }
    ],
    "backup_lag": [
      { "thread": 1, "last_backed_up_seq": 79810,
        "current_seq": 79814, "lag": 4 }
    ]
  }
}
```

Field notes:

- `jobs[].class` is the disambiguated backup class (`inc0` | `inc1` | `arc`),
  derived per section 7. `input_type` is the raw view value, kept for audit.
- `gaps[]` is forensic: missing sequences inside the already-backed-up range.
- `backup_lag[]` is preventive: distance from the newest backed-up sequence to
  the current sequence per thread. This is the archive-gap-risk signal.
- Sizes in bytes; renderer formats. `compression_ratio` and
  `output_device_type` come straight from the job view.

------------------------------------------------------------------------

## 6. Subcommands

Structure follows `oradba_homes.sh` (subcommand as first word) plus long
flags. Standard flags on every subcommand: `--help`, `--dry-run`, `--yes`.
Config cascade: code defaults -> env file -> conf file -> CLI args.

```text
oradba_backup_report.sh collect [--sid ALL|<sid>[,<sid>...]] [--days N]
                                 [--out <dir>] [--format json]
oradba_backup_report.sh merge   --in <dir> [--out <file>]
oradba_backup_report.sh render  --in <merged.json> --format svg|html
                                 [--out <file>] [--window week|weekend|day]
oradba_backup_report.sh show    [--sid <sid>] [--in <fragment|merged>]
oradba_backup_report.sh gaps    [--sid <sid>] [--in <fragment|merged>]
                                 [--warn-lag N] [--crit-lag N]
```

### 6.1 collect

Node-local. For each target SID: resolve source (section 4), parse crontab
(section 8), query the DB (section 9), compute condensed archivelog metrics
(section 10), write one fragment per SID. `--sid ALL` iterates local SIDs via
the OraDBA registry / oratab. `--days` default 28.

### 6.2 merge

Reads a directory of fragments (already gathered locally), concatenates into a
single merged JSON with a `hosts[]`/`databases[]` structure. Deduplicates by
`(host, sid, generated_at)` keeping the newest per `(host, sid)`.

### 6.3 render

Pure transform: merged JSON -> SVG or HTML grid. Layout per section 11.
`--window` selects the time span (default `week`).

### 6.4 show

Text summary for quick CLI use (no rendering): per SID a table of schedule
plus median/min/max runtime per class and archivelog lag. Uses `LogMessage`
formatting, no bare echo.

### 6.5 gaps

Archivelog health report. Non-zero exit if any thread lag exceeds `--crit-lag`
(default from config), warning-level if above `--warn-lag`. Also lists any
forensic `gaps[]`. This is the subcommand suitable for monitoring hooks.

------------------------------------------------------------------------

## 7. Backup class disambiguation (important)

`V$RMAN_BACKUP_JOB_DETAILS.INPUT_TYPE` yields values such as `DB FULL`,
`DB INCR`, `ARCHIVELOG`, `RECVRY AREA`, `DB INCR CUM`, etc. It does NOT
distinguish incremental level 0 from level 1. USZ uses level-0 as inc0 and
level-1 as inc1, so both arrive as `DB INCR` and cannot be split by
`INPUT_TYPE` alone.

Classification rule (v1):

1. `ARCHIVELOG` / `RECVRY AREA` -> `class = arc`.
2. `DB FULL` -> `class = inc0` (non-incremental full).
3. `DB INCR*` -> correlate the job `start_time` to the parsed crontab slots on
   the same SID. Choose the nearest scheduled slot of type inc0 or inc1c whose
   nominal start is within a tolerance window (default +/- 90 min, config
   `ORADBA_BR_SLOT_TOLERANCE_MIN`). The matched slot type sets the class.
4. No slot match -> keep `class = incr_unknown`, log a warning; renderer shows
   it in a neutral colour so it is visible rather than silently miscounted.

Accuracy upgrade (optional, note for implementation, not required for v1):
join `V$BACKUP_DATAFILE.INCREMENTAL_LEVEL` by session to read the true level.
More precise, more query surface; defer unless the correlation proves unreliable.

------------------------------------------------------------------------

## 8. crontab parsing

- Source: `crontab -l` of the executing oracle user only. No `grid`, no
  `/etc/cron.d`, no `/var/spool/cron` (out of scope for v1, avoids extra
  privileges).
- Filter to own backup jobs before parsing: lines invoking `rman_exec.ksh` or
  `oradba_backup.sh` with a service argument matching `*_bck_*`
  (`usz_bck_inc0`, `usz_bck_inc1c`, `usz_bck_arc`, and generic equivalents).
  Foreign cron entries must not leak into the fragment.
- For each matched line, extract the 5 cron fields plus the service, and map
  service -> type: `*_bck_inc0`->inc0, `*_bck_inc1c`->inc1, `*_bck_arc`->arc.
- Keep the raw line in `schedule[].raw` for audit.
- DOW handling: support lists, ranges, `*`, and the 0/7 = Sunday alias. This is
  the same normalisation already validated against the collect samples.
- The `-t <SID>` argument on the cron line ties the schedule entry to a SID, so
  a host crontab covering multiple DBs is split correctly per fragment.

------------------------------------------------------------------------

## 9. SQL sources (exact)

All queries run via SQL*Plus `-S /nolog` with a heredoc. Local source connects
`/ as sysdba`; catalog source connects with the string from `rman.conf`.
Bind `:days` from `--days`.

### 9.1 Job runtimes

Local (controlfile):

```sql
SELECT db_name, input_type,
       TO_CHAR(start_time,'YYYY-MM-DD"T"HH24:MI:SS'),
       TO_CHAR(end_time  ,'YYYY-MM-DD"T"HH24:MI:SS'),
       elapsed_seconds, status, input_bytes, output_bytes,
       compression_ratio, output_device_type
FROM   v$rman_backup_job_details
WHERE  start_time > SYSDATE - :days
ORDER  BY start_time;
```

Catalog: same projection from `RC_RMAN_BACKUP_JOB_DETAILS`, filtered to the
local `db_name` (or `DB_KEY`).

### 9.2 Archivelog backup window (forensic gaps input)

```sql
SELECT thread#, sequence#,
       TO_CHAR(first_time     ,'YYYY-MM-DD"T"HH24:MI:SS'),
       TO_CHAR(next_time      ,'YYYY-MM-DD"T"HH24:MI:SS'),
       TO_CHAR(completion_time,'YYYY-MM-DD"T"HH24:MI:SS')
FROM   v$backup_archivelog_details
WHERE  completion_time > SYSDATE - :days
ORDER  BY thread#, sequence#;
```

Catalog: `RC_BACKUP_ARCHIVELOG_DETAILS`.

### 9.3 Current sequence (lag input)

```sql
SELECT thread#, MAX(sequence#)
FROM   v$archived_log
WHERE  resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP  BY thread#;
```

(Or `v$log` current sequence per thread; pick one and document it.)

Option (c) is implemented as: query 9.2 and 9.3 raw, then condense in shell
(section 10) so the fragment stays small while gap detection stays exact.

------------------------------------------------------------------------

## 10. Archivelog condensation (in shell)

From the raw rows of 9.2 and 9.3, per thread:

- `window_first_time` = min(first_time), `window_next_time` = max(next_time),
  `seq_count` = count of distinct backed-up sequences, `thread_count`.
- `gaps[]`: sort backed-up sequences; every missing integer run between
  min and max backed-up sequence becomes one gap entry
  `{thread, gap_start_seq, gap_end_seq, gap_after_time}` where `gap_after_time`
  is the `next_time` of the sequence preceding the hole.
- `backup_lag[]`: per thread, `last_backed_up_seq` = max sequence in 9.2,
  `current_seq` from 9.3, `lag = current_seq - last_backed_up_seq`.

Done with awk/sort, no `jq` needed for computation. `jq` may be used only for
final JSON assembly/validation if available; otherwise emit JSON via a small
shell writer (keep `jq` optional, matching oradba's minimal-dependency stance).

------------------------------------------------------------------------

## 11. Renderer (grid)

Reference implementation already prototyped. Inputs: merged JSON.
Computed per (host, sid, class): median (and min/max) `elapsed_s` over
`status='COMPLETED'` jobs; schedule occurrences from `schedule[]`.

Layout:

- Landscape SVG (optionally wrapped in HTML for a title/legend).
- Left label columns: Server | Database | Job (one row per class inc0/inc1/arc).
- Top axis: 7 weekdays, each divided into 24 hours; gridlines every hour, bold
  every 6 h and on day boundaries; weekend tinted.
- Bars placed by scheduled start; bar length = median runtime of that class.
  All weekly occurrences of a class share ONE row. inc0 = red, inc1 = blue,
  arc = green diamonds (near-instant, drawn as markers not bars).
- `incr_unknown` (section 7) rendered in a neutral colour so it is not hidden.
- `--window weekend` narrows to Fri 18:00 - Mon 00:00 for a readable view of the
  level-0 window and host contention; `--window day` shows a representative
  24 h; `--window week` (default) shows Mon-Sun.

Output: `svg` (embeddable in Markdown via `![]()`) or `html` (self-contained,
legend + horizontal scroll). No external assets, no localStorage.

------------------------------------------------------------------------

## 12. Configuration

Cascade (later overrides earlier): code defaults -> env file
(`ORADBA_BASE/etc/...` or the standard oradba env) -> conf file -> CLI args.

Suggested config keys (with defaults):

<!-- markdownlint-disable MD013 MD060 -->

| Key                              | Default                 | Meaning                              |
| -------------------------------- | ----------------------- | ------------------------------------ |
| `ORADBA_BR_DAYS`                 | 28                      | collection window (days)             |
| `ORADBA_BR_REPORT_DIR`           | `${ORADBA_BASE}/log/backup_report` | fragment output dir (oradba install base) |
| `ORADBA_BR_SLOT_TOLERANCE_MIN`   | 90                      | class-correlation tolerance (min)    |
| `ORADBA_BR_WARN_LAG`             | 8                       | archivelog lag warning threshold     |
| `ORADBA_BR_CRIT_LAG`             | 20                      | archivelog lag critical threshold    |
| `ORADBA_BR_SERVICE_PREFIX`       | `usz_bck_`              | backup service name prefix to match  |
| `ORADBA_BR_RENDER_WINDOW`        | `week`                  | default render window                |

<!-- markdownlint-restore -->

`rman.conf` is read but not owned by this tool; only the catalog connect and
catalog/nocatalog flag are consumed.

------------------------------------------------------------------------

## 13. Convention compliance checklist

- `#!/usr/bin/env bash`, `set -euo pipefail`.
- Script header via the `/bash-header` skill: Name, Author, Description,
  Version, Change History.
- All output through the `LogMessage`-style wrapper (INFO/WARN/ERROR), never
  bare echo/printf.
- Library loading via `source`, path resolved from `${BASH_SOURCE[0]}`; reuse
  existing oradba libs (registry API, config manager, status checker) rather
  than duplicating. Check `oradba_rman.sh` / `rman_jobs.sh` for shared helpers.
- Standard flags: `--help`, `--dry-run`, `--yes` on every subcommand.
- BasEnv coexistence: when TVD BasEnv is detected, do not touch
  `ORACLE_SID/HOME/BASE/TNS_ADMIN`; consume them read-only. Detect mode and
  record `meta.basenv_mode`.
- shellcheck clean against repo `.shellcheckrc`.
- Secrets never hardcoded; customer path uses `rman.conf` only.

------------------------------------------------------------------------

## 14. Testing plan (BATS)

Fast local unit tests (no Docker, no Oracle) with fixtures:

- crontab parser: fixture crontab strings -> expected `schedule[]`
  (lists, ranges, 0/7 alias, multi-SID split, foreign-line filtering).
- class disambiguation: job start times + schedule -> expected class,
  including tolerance edges and `incr_unknown`.
- archivelog condensation: raw sequence fixtures -> expected `gaps[]` and
  `backup_lag[]` (holes at start/middle/end, multi-thread, no-gap case).
- merge: directory of fragments -> dedup by newest per (host,sid).
- render: merged JSON -> SVG contains expected rows/bars (assert structure,
  not pixels); window selection changes axis bounds.
- source selection: rman.conf present/absent/unreachable -> correct `source`
  and `source_degraded` flag (mock the connect).

Docker integration test (manual / release tag, `make test-docker`): real
`V$RMAN_BACKUP_JOB_DETAILS` shape against Oracle Free, small backup, assert a
fragment is produced with a plausible job record.

Fixtures live under `tests/fixtures/backup_report/`. Results in
`tests/results/`.

------------------------------------------------------------------------

## 15. v1 / v2 boundary

- v1 (this spec): collect, merge, render, show, gaps. Read-only. crontab is
  parsed, never written.
- v2 (separate spec later): declarative desired-state model (YAML),
  crontab generation from the model, a collision/health linter with CI exit
  codes, and Ansible-based deploy. The v1 JSON schema and renderer are designed
  to be reused unchanged by v2; only the schedule source changes (model instead
  of parsed crontab).

------------------------------------------------------------------------

## 16. Confirmed decisions

All resolved (2026-08-03):

1. Catalog schema-per-version: the `rman.conf` per-SID connect already points at
   the correct catalog schema; no auto-detect. One `rman.conf` addresses one
   schema. CONFIRMED.
2. Fragment granularity: one file per `(host, sid)`. CONFIRMED.
3. Current-sequence source for the lag metric: use `v$archived_log`
   (max sequence per thread, scoped to the current incarnation). CONFIRMED.
4. `jq` not assumed present at customer sites: emit JSON via a shell writer;
   use `jq` only when detected (validation/convenience). CONFIRMED.
5. Report dir default: oradba install base central log area
   (`${ORADBA_BASE}/log/backup_report`), not `$ORACLE_BASE/admin`. CONFIRMED.

------------------------------------------------------------------------

## 17. Implementation phases (for Claude Code)

1. Skeleton: script header, arg parsing, subcommand dispatch, config cascade,
   `LogMessage`, BasEnv detection, `--help`. shellcheck + header tests green.
2. `collect` - source resolution (rman.conf), SQL for 9.1, crontab parser
   (section 8), fragment writer (meta + schedule + jobs). Unit tests.
3. Archivelog: SQL 9.2/9.3 + condensation (section 10). Unit tests for gaps/lag.
4. Class disambiguation (section 7) wired into collect. Unit tests.
5. `merge` + `show`. Unit tests.
6. `render` (SVG then HTML), window selection. Structural tests.
7. `gaps` subcommand with thresholds and monitoring exit codes.
8. Docs: `doc/` page, README feature entry, `doc/releases/v<VERSION>.md`
   before tagging. Docker integration test.

Each phase is a reviewable unit; do not combine collect and render into one PR.
