# Configuration Examples

Example configuration files for OraDBA scripts.

## Available Examples

### Peer Synchronization

- **[sync_to_peers.conf.example](sync_to_peers.conf.example)** - Configuration for `sync_to_peers.sh`
- **[sync_from_peers.conf.example](sync_from_peers.conf.example)** - Configuration for `sync_from_peers.sh`

## Usage

Copy the relevant example file to `${ORADBA_BASE}/etc/` and customize:

```bash
# Copy and customize sync_to_peers configuration
cp ${ORADBA_BASE}/templates/etc/sync_to_peers.conf.example \
   ${ORADBA_BASE}/etc/sync_to_peers.conf

# Edit the configuration
vi ${ORADBA_BASE}/etc/sync_to_peers.conf
```

## Configuration Files

Configuration files in `${ORADBA_BASE}/etc/` are loaded automatically by their
respective scripts. The scripts follow a hierarchical loading order:

1. Script-specific config: `${ORADBA_BASE}/etc/<script_name>.conf`
2. Alternative location: `${ETC_BASE}/<script_name>.conf` (if `ETC_BASE` is set)
3. CLI-specified config: `-c <config_file>` option
4. Environment variables (highest priority)

## Peer Synchronization Configuration

The sync scripts use rsync over SSH to maintain file consistency across multiple hosts. Common use cases include:

- Synchronizing Oracle Wallet files across RAC nodes
- Distributing tnsnames.ora to all database servers
- Replicating configuration files to standby databases
- Maintaining consistent setup across a database cluster

### Key Configuration Parameters

```bash
# List of peer hostnames (short names or FQDNs)
PEER_HOSTS=(db01 db02 db03)

# SSH connection settings
SSH_USER="oracle"
SSH_PORT="22"

# Optional: Additional rsync options
# RSYNC_OPTS="-az --exclude='*.log' --bwlimit=1000"

# Optional: Custom remote base path
# REMOTE_BASE="/opt/oracle/config"
```

### Example Configurations

**Simple RAC cluster:**

```bash
PEER_HOSTS=(rac1 rac2)
SSH_USER="oracle"
SSH_PORT="22"
```

**Multi-site setup with custom SSH port:**

```bash
PEER_HOSTS=(primary.example.com standby1.example.com standby2.example.com)
SSH_USER="oracle"
SSH_PORT="2222"
RSYNC_OPTS="-az --bwlimit=5000"  # Limit bandwidth for WAN
```

**Testing environment:**

```bash
PEER_HOSTS=(dev01 dev02 test01)
SSH_USER="oracle"
SSH_PORT="22"
RSYNC_OPTS="-az --dry-run"  # Always simulate for testing
```

## See Also

- [Development Guide](../../../doc/development.md) - Coding guidelines
- [Templates README](../README.md) - All available templates
- Script help: `sync_to_peers.sh -h` or `sync_from_peers.sh -h`
