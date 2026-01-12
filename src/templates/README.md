# OraDBA Script Templates

Reusable templates and skeletons for creating new OraDBA scripts and configs.

## Available Templates

- **[script_template.sh](script_template.sh)** - Bash script template with
  standard structure
- **etc/** - Example configuration files for OraDBA scripts
  - **[sync_to_peers.conf.example](etc/sync_to_peers.conf.example)** - Peer sync (push) config
  - **[sync_from_peers.conf.example](etc/sync_from_peers.conf.example)** - Peer sync (pull) config
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

# Copy configuration example
cp ${ORADBA_BASE}/templates/etc/sync_to_peers.conf.example \
   ${ORADBA_BASE}/etc/sync_to_peers.conf
# Edit and configure peer hosts
```

## Template Features

- Standard OraDBA header with version tracking
- Argument parsing framework
- Error handling and logging
- Help text generation
- Consistent code structure

## Configuration Templates

Configuration templates in `etc/` provide examples for setting up:

- Peer synchronization (SSH hosts, rsync options)
- Default values and environment variable overrides
- Multi-host configurations

## Documentation

See [DEVELOPMENT.md](../../doc/DEVELOPMENT.md) for coding guidelines and
script development best practices.

For file headers, see [doc/templates/](../../doc/templates/).
