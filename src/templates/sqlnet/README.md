# SQL*Net Configuration Templates

This directory contains Oracle SQL*Net configuration templates for various use cases and security requirements.

## Available Templates

### sqlnet.ora Templates

| Template | Purpose | Use Case |
|----------|---------|----------|
| `sqlnet.ora.basic` | Basic configuration | Development/test environments |
| `sqlnet.ora.secure` | Enterprise security | Production with encryption |

### Connection Descriptor Templates

| Template | Purpose | Use Case |
|----------|---------|----------|
| `tnsnames.ora.template` | Connection examples | Various connection scenarios |
| `ldap.ora.template` | LDAP naming | Centralized directory naming |

## Quick Start

### Install Basic Configuration

```bash
# Install basic sqlnet.ora
oradba_sqlnet.sh --install basic

# Generate tnsnames entry for your database
oradba_sqlnet.sh --generate ORCL

# Validate configuration
oradba_sqlnet.sh --validate
```

### Install Secure Configuration

```bash
# Install secure sqlnet.ora with encryption
oradba_sqlnet.sh --install secure

# Test connection
oradba_sqlnet.sh --test ORCL
```

## Template Details

### sqlnet.ora.basic

Basic configuration suitable for development and test environments:

- **Naming**: TNSNAMES, EZCONNECT, HOSTNAME
- **Timeouts**: 60s inbound, 120s outbound
- **Diagnostics**: ADR enabled
- **Dead connection detection**: 10 minutes

### sqlnet.ora.secure

Production-grade security configuration:

- **Encryption**: AES256/192/128 (REQUIRED)
- **Checksumming**: SHA256/384/512 (REQUIRED)
- **Authentication**: TCPS, NTS
- **Case-sensitive logon**: Enabled
- **Minimum version**: Oracle 12c
- **Requires**: Oracle Advanced Security license

**Note**: Network encryption features require Oracle Advanced Security license.

### tnsnames.ora.template

Comprehensive connection descriptor examples:

- Basic connection (dedicated server)
- Failover configuration (automatic)
- Load balancing (multiple nodes)
- Secure TCPS connection
- PDB connections
- RAC SCAN listener
- Connection pooling
- Data Guard standby
- Custom timeouts

### ldap.ora.template

LDAP directory configuration:

- Oracle Internet Directory (OID)
- Active Directory (AD)
- SSL/TLS support
- Authentication credentials
- Cache configuration

## Usage Examples

### List TNS Aliases

```bash
oradba_sqlnet.sh --list
```

### Test Connection

```bash
oradba_sqlnet.sh --test ORCL
```

### Backup Configuration

```bash
# Backup before making changes
oradba_sqlnet.sh --backup
```

## Variable Substitution

Templates support environment variable substitution:

- `${ORACLE_BASE}` - Oracle base directory
- `${ORACLE_SID}` - Current database SID
- `${ORACLE_HOME}` - Oracle home directory

Variables are substituted during template installation.

## File Locations

Configuration files are installed to `$TNS_ADMIN` or `$ORACLE_HOME/network/admin`:

```
$TNS_ADMIN/
├── sqlnet.ora     # Network configuration
├── tnsnames.ora   # Connection descriptors
└── ldap.ora       # LDAP naming configuration
```

## Security Considerations

### Encryption

- Use `sqlnet.ora.secure` for production environments
- Requires Oracle Advanced Security license
- AES256 provides strongest encryption
- Always use REQUIRED (not REQUESTED or ACCEPTED)

### Authentication

- Use wallet-based authentication when possible
- Enable case-sensitive logon
- Set minimum logon version to 12 or higher
- Use TCPS for sensitive connections

### Compliance

Secure template helps meet:

- PCI-DSS requirements
- HIPAA compliance
- SOX requirements
- GDPR data protection

## Best Practices

1. **Always backup** before modifying configuration
2. **Test in non-production** first
3. **Use encryption** for production databases
4. **Enable ADR** for diagnostics
5. **Set appropriate timeouts** for your network
6. **Document custom changes** in comments
7. **Use SCAN** for RAC environments
8. **Regular security audits** of configurations

## Troubleshooting

### Connection Fails

```bash
# Validate configuration
oradba_sqlnet.sh --validate

# Test specific alias
oradba_sqlnet.sh --test ORCL

# Check tnsping
tnsping ORCL
```

### Encryption Issues

- Verify Oracle Advanced Security license
- Check wallet location and permissions
- Ensure matching encryption settings client/server
- Review trace files for detailed errors

### Performance Issues

- Increase SDU_SIZE for bulk operations
- Reduce timeout values for faster failover
- Enable connection pooling
- Use TCP.NODELAY=YES

## Integration

### With oraenv.sh

The `oraenv.sh` script automatically sets:

```bash
export TNS_ADMIN=${ORACLE_BASE}/admin/${ORACLE_SID}/network/admin
```

### With oradba_install.sh

Templates are installed to:

```
/usr/local/oradba/templates/sqlnet/
```

## References

- [Oracle Net Services documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [Oracle Advanced Security Guide](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [Net Services Reference](https://docs.oracle.com/en/database/oracle/oracle-database/)

## Support

For issues or questions:

- GitHub: https://github.com/oehrlis/oradba/issues
- Email: stefan.oehrli@oradba.ch

---
*Part of the OraDBA project - https://github.com/oehrlis/oradba*
