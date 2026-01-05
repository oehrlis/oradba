# OraDBA Script Templates

Reusable templates and skeletons for creating new OraDBA scripts and configs.

## Available Templates

- **[script_template.sh](script_template.sh)** - Bash script template with
  standard structure
- **extension/** - Stubs for site-specific extensions loaded via `oraenv`
- **init.d/** - Legacy init scripts for environments without systemd
- **systemd/** - Unit templates for listeners/databases
- **logrotate/** - Log rotation snippets for OraDBA logs
- **sqlnet/** - Baseline `sqlnet.ora` examples

## Usage

Copy template and customize:

```bash
cp ${ORADBA_BASE}/templates/script_template.sh my_script.sh
# Edit and add your functionality
```

## Template Features

- Standard OraDBA header with version tracking
- Argument parsing framework
- Error handling and logging
- Help text generation
- Consistent code structure

## Documentation

See [DEVELOPMENT.md](../../doc/DEVELOPMENT.md) for coding guidelines and
script development best practices.

For file headers, see [doc/templates/](../../doc/templates/).
