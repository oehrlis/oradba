# OraDBA Configuration Reference

This document lists environment variables and configuration knobs recognised
by the OraDBA framework.

## Performance Variables

| Variable | Default | Description |
| --- | --- | --- |
| `ORADBA_LOAD_PDB_ALIASES` | `false` | Enable PDB alias generation on env switch. Set to `true` to create shell aliases for each PDB in the active CDB. Disabled by default to avoid SQL*Plus connections on every `oraenv.sh` invocation. |
| `ORADBA_LOAD_ALIASES` | `true` | Create shell aliases for SIDs and Oracle Homes during config load. Set to `false` for non-interactive sessions. |
| `ORADBA_CONFIGURE_SQLPATH` | `true` | Configure SQLPATH during env switch. Set to `false` to skip SQLPATH setup. |
| `ORADBA_LOAD_ALIASES_IN_SILENT` | `true` | Allow alias creation even in silent mode. Set to `false` to suppress aliases in non-interactive shells. |
| `ORADBA_CONFIGURE_SQLPATH_IN_SILENT` | `true` | Allow SQLPATH configuration in silent mode. |

## Fast Silent Mode

Pass `--fast-silent` to `oraenv.sh` to activate the fastest possible env switch:

- Aliases disabled (`ORADBA_LOAD_ALIASES=false`)
- SQLPATH setup skipped (`ORADBA_CONFIGURE_SQLPATH=false`)
- PDB alias generation skipped (`ORADBA_LOAD_PDB_ALIASES=false`)

This mode is recommended for login scripts (`.bash_profile`, `.bashrc`) where
startup latency matters more than full interactive features.

## Logging Variables

| Variable | Default | Description |
| --- | --- | --- |
| `ORADBA_LOG_LEVEL` | `INFO` | Minimum log level. Values: TRACE, DEBUG, INFO, WARN, ERROR. |
| `ORADBA_LOG_FILE` | _(auto)_ | Path to main log file. Auto-set to `$ORADBA_LOG_DIR/oradba.log`. |
| `ORADBA_LOG_DIR` | _(auto)_ | Log directory. Defaults to `/var/log/oradba` (writable) or `~/.oradba/logs`. |
| `ORADBA_NO_COLOR` | `0` | Set to `1` to disable ANSI colour in log output. |
| `ORADBA_LOG_SHOW_CALLER` | `false` | Include file:line caller info in log messages. |
