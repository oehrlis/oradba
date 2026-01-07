# Extension Template

Starter OraDBA extension that follows the recommended layout from `doc/extension-system.md` and `src/doc/18-extensions.md`. Rename it with `../scripts/rename-extension.sh` and then customize the scripts, SQL, and RMAN content.

## Structure
```text
extension-template/
├── .extension                   # Metadata: name, version, priority, description
├── bin/                         # Executable scripts (added to PATH)
├── sql/                         # SQL scripts (added to SQLPATH)
├── rcv/                         # RMAN scripts
├── etc/                         # Config examples (manual opt-in)
└── lib/                         # Optional helper libraries
```

## Usage
- Navigate after loading OraDBA: `cdeextension-template`
- Scripts become available once `${ORADBA_LOCAL_BASE}/extension-template` is discovered.
- Disable or reprioritize via `${ORADBA_PREFIX}/etc/oradba_customer.conf`:
  ```bash
  export ORADBA_EXT_EXTENSION_TEMPLATE_ENABLED="false"
  export ORADBA_EXT_EXTENSION_TEMPLATE_PRIORITY="20"
  ```

## Configuration
- Copy required settings from `etc/extension-template.conf.example` into `${ORADBA_PREFIX}/etc/oradba_customer.conf`.
- Avoid auto-sourcing files in `etc/`; keep them as examples only.

## Sample Content
- `bin/extension_tool.sh` demonstrates logging and environment access.
- `sql/extension_query.sql` shows a placeholder SQL query.
- `rcv/extension_backup.rcv` is a stub RMAN script.
- `lib/common.sh` is provided for shared helper functions inside the extension.

## Packaging
Use `../scripts/build.sh` from the repository root to create a tarball and checksum:

```bash
./scripts/build.sh
tar tzf dist/extension-template-0.1.0.tar.gz
```

## Version History
- 0.1.0: Initial template content
