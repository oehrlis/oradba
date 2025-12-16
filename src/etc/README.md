# OraDBA Configuration Files

Configuration files and examples for OraDBA setup.

## Files

- **[oradba.conf](oradba.conf)** - Main configuration file (installed)
- **[oradba_config.example](oradba_config.example)** - Configuration template
- **[oratab.example](oratab.example)** - Sample oratab file for reference

## Configuration

Edit `oradba.conf` to customize:

- Default logging behavior
- Database query timeouts
- Output formatting preferences
- Custom environment variables

## Usage

OraDBA scripts automatically source configuration from:

1. `${ORADBA_BASE}/etc/oradba.conf`
2. `${HOME}/.oradba/config`

## Documentation

See [USAGE.md](../doc/USAGE.md) for configuration details and examples.
