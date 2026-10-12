# Conventions

**Purpose:** Single definition of the OS groups, filesystem layout and Oracle Home naming that the OraDBA tools
assume as defaults.

**Audience:** DBAs and engineers who install Oracle software with OraDBA tooling, build images or labs, or write
automation on top of it.

## Introduction {.unlisted}

Several repositories install and patch Oracle software: the patch and home engine
[odb_autoupgrade](https://github.com/oehrlis/odb_autoupgrade), the Ansible collection `oradba.automation`
(repository `oradba-ansible`, planned), lab environments and Docker image builds. This page defines the conventions
they share. It is the only place where these values are decided:

- Engine and collection implement them as **defaults that a site can override**. Site configuration always wins.
- A change to a convention is made on this page first; the implementing repositories follow in their next release.
- Nothing here is an Oracle requirement unless stated. Where Oracle has a default (Preinstallation RPM, OFA), the
  difference is named.

Scope is single-instance Oracle Database on Linux. Grid Infrastructure and ASM groups (`asmadmin`, `asmdba`,
`asmoper`) are not covered yet.

## Filesystem Layout

Three roots, kept as separate directories even when they live on one filesystem. Any of them can later move to a
dedicated volume without changing a path.

<!-- markdownlint-disable MD013 MD060 -->
| Item | Variable | Default | Notes |
| --- | --- | --- | --- |
| Software root | `ORACLE_ROOT` | `/u00` | Binaries, `ORACLE_BASE`, inventory |
| Data root | `ORACLE_DATA` | `/u01` | Datafiles, control files, online redo |
| Archive root | `ORACLE_ARCH` | `/u02` | Archived redo and fast recovery area |
| `ORACLE_BASE` | `ORACLE_BASE` | `/u00/app/oracle` | Also root of the OraDBA installation (`${ORACLE_BASE}/local/oradba`) |
| Central inventory | - | `/u00/app/oraInventory` | Recorded in `/etc/oraInst.loc` with `inst_group=oinstall` |
| Oracle Homes | `ORACLE_HOME` | `${ORACLE_BASE}/product/<version>` | See [Oracle Home Naming](#oracle-home-naming) |
| Datafiles | - | `/u01/oradata/<DB_UNIQUE_NAME>` | One directory per database |
| Archived redo | - | `/u02/archive/<DB_UNIQUE_NAME>` | When not written to the fast recovery area |
| Fast recovery area | `db_recovery_file_dest` | `/u02/fast_recovery_area` | Oracle adds `<DB_UNIQUE_NAME>` below |
<!-- markdownlint-restore -->

Difference to Oracle OFA: OFA uses `/u01/app/oracle` for the software and `/u02`, `/u03`, ... for data. The OraDBA
layout keeps software on `/u00` so that `/u01` and `/u02` carry only database files.

Known deviations in existing code, to be aligned with this page:

- `oradba_logrotate.sh` and `oradba_sqlnet.sh` fall back to `/u01/app/oracle` when `ORACLE_BASE` is unset.
- `oradba_dbca.sh` defaults the data directory to `${ORACLE_BASE}/oradata/<SID>`; set `DATA_DIR` to follow this page.
- `oracle-database-docker-legacy` uses `ORACLE_DATA=/u00/oradata` (single root).

## OS Users and Groups

The software owner is `oracle`. Group names default to the names created by the Oracle Database Preinstallation RPM
(`oracle-database-preinstall-19c` on Oracle Linux 8 and 9), with the RPM's GIDs.

<!-- markdownlint-disable MD013 MD060 -->
| Role | Default name | GID (RPM) | odb_autoupgrade variable | AutoUpgrade key |
| --- | --- | --- | --- | --- |
| Inventory group | `oinstall` | 54321 | `AU_INVENTORY_GROUP` | `home_settings.inventory_group` |
| OSDBA | `dba` | 54322 | `AU_GROUP_OSDBA` | `home_settings.osdba_group` |
| OSOPER | `oper` | 54323 | `AU_GROUP_OSOPER` | `home_settings.osoper_group` |
| OSBACKUPDBA | `backupdba` | 54324 | `AU_GROUP_OSBACKUPDBA` | `home_settings.osbackupdba_group` |
| OSDGDBA | `dgdba` | 54325 | `AU_GROUP_OSDGDBA` | `home_settings.osdgdba_group` |
| OSKMDBA | `kmdba` | 54326 | `AU_GROUP_OSKMDBA` | `home_settings.oskmdba_group` |
| OSRACDBA | `racdba` | 54330 | `AU_GROUP_OSRACDBA` | `home_settings.osracdba_group` |
<!-- markdownlint-restore -->

The user `oracle` (UID 54321 from the RPM) has `oinstall` as primary group and all six OS groups as secondary
groups. Reference:
[Oracle Database 19c installation guide for Linux - operating system privileges groups](https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/creating-operating-system-privileges-groups.html).

Rules:

- GIDs (and the UID of `oracle`) must be identical on all hosts that share files or form one configuration
  (Data Guard, shared NFS for backups or patches). Choose them once per site.
- When a home is created from an existing source home, the groups recorded in the source home
  (`rdbms/lib/config.c`) win; the defaults above apply only to homes created without a source home.
- The engine uses group **names** only. GIDs matter where groups are created (OS preparation, the collection).

### Site Variant: os\* Group Names

Some sites use `osdba`, `osoper`, `osbackupdba`, `osdgdba`, `oskmdba` and `osracdba` with fixed GIDs. This is a
supported site choice, not the default. The GIDs of such a site are site data and are not published here; they
belong in the site configuration of the group creation. odb_autoupgrade ships the name mapping as an example in
`etc/groups/os-fixed-gid.env`.

### Legacy GIDs

`oracle-database-docker-legacy` creates the default group names with GIDs 1010 (`oinstall`), 1020 (`dba`),
1030 (`oper`), 1040 (`backupdba`), 1050 (`kmdba`), 1060 (`dgdba`) and 1070 (`racdba`). Images and volumes built
with these GIDs keep them until they are rebuilt; changing GIDs on an existing host means re-owning every file of
the old GID.

## Oracle Home Naming

New database homes are named after the Release Update they contain, in four parts:

```text
${ORACLE_BASE}/product/<major>.<RU>.0.0
/u00/app/oracle/product/19.32.0.0
```

- The four-part version is the `releaseUpdate` value from AutoUpgrade's `patches_info.json`, not the base release.
- A second home on the same RU (for example a different MRP level or one-off set) gets a numeric suffix:
  `product/19.32.0.0_2`, `product/19.32.0.0_3`.
- No `dbhome_1` level below the version.
- The home is registered in `oradba_homes.conf` so that OraDBA can switch to it. odb_autoupgrade does this in
  OraDBA mode and prints it as a manual step in standalone mode.

Names in use before this convention and to be migrated: `product/19.0.0.0` (docker), `product/19.31/dbhome_1`
(oci-labs). Existing homes are not renamed in place; the convention applies to the next
home created out of place.

The convention covers database homes. Other products managed by OraDBA (client, OUD, WebLogic, Data Safe
connectors) keep their current names.

## Implementation and Overrides

<!-- markdownlint-disable MD013 MD060 -->
| Repository | Implements | Override |
| --- | --- | --- |
| `oradba` | Environment for `ORACLE_BASE` and registered homes | `ORACLE_BASE` in the OraDBA configuration, `oradba_homes.conf` |
| `odb_autoupgrade` (0.6.0+) | Group defaults, home naming, inventory | `AU_ORACLE_BASE`, `AU_GROUP_*`, `AU_INVENTORY_LOCATION`, `AU_INVENTORY_GROUP`, `AU_TARGET_HOME` |
| `oradba-ansible` (planned) | Group and user creation with GIDs, directory layout | Role variables (inventory or site variables) |
| `oci-labs`, image builds | Consume the engine and the collection | Lab inventory and build arguments |
<!-- markdownlint-restore -->

Details for the engine: [odb_autoupgrade - Oracle Home Management](https://github.com/oehrlis/odb_autoupgrade/blob/main/doc/oracle-home.md).
