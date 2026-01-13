# Configuration

Configuration guide for OraDBA Extension Template and extensions created from it.

## Extension Metadata

The `.extension` file contains core metadata:

```ini
# Extension metadata
EXTENSION_NAME="extension"
EXTENSION_VERSION="1.0.0"
EXTENSION_PRIORITY="50"
EXTENSION_DESCRIPTION="OraDBA extension template"
```

### Metadata Fields

- **EXTENSION_NAME** - Unique identifier (lowercase, alphanumeric, hyphens/underscores)
- **EXTENSION_VERSION** - Semantic version (MAJOR.MINOR.PATCH)
- **EXTENSION_PRIORITY** - Load order (lower numbers load first, 1-99)
- **EXTENSION_DESCRIPTION** - Brief description

### Priority Guidelines

```text
1-19   : System/infrastructure extensions
20-39  : Database core extensions
40-59  : Application extensions (default: 50)
60-79  : Monitoring/reporting extensions
80-99  : User/custom extensions
```

## Configuration Files

### Extension Configuration Example

Each extension should provide `etc/<name>.conf.example`:

```bash
# Extension configuration example
# Copy needed settings to ${ORADBA_PREFIX}/etc/oradba_customer.conf

# Custom settings for this extension
EXTENSION_CUSTOM_SETTING="value"
EXTENSION_FEATURE_ENABLED="true"

# Integration settings
EXTENSION_API_ENDPOINT="https://api.example.com"
EXTENSION_TIMEOUT="30"
```

### User Configuration

Users add extension settings to their OraDBA configuration:

**File:** `${ORADBA_PREFIX}/etc/oradba_customer.conf`

```bash
# Extension: My Custom Extension
MYEXT_ENABLED="true"
MYEXT_SETTING="custom_value"
```

## Integrity Verification

### Checksum Exclusions

The `.checksumignore` file specifies files excluded from integrity checks:

```text
# Extension metadata (always excluded)
.extension
.checksumignore

# Logs and temporary files
log/
*.log
*.tmp

# User-specific configurations
etc/*.conf
!etc/*.conf.example

# Credentials and secrets
keystore/
*.key
*.pem
*.pwd

# Cache directories
cache/
.cache/

# Build artifacts (if user builds locally)
dist/
*.tar.gz
*.sha256
```

### Pattern Syntax

- **Wildcards:** `*.log` matches all .log files
- **Directories:** `log/` matches entire directory
- **Negation:** `!file.txt` includes file even if matched by earlier pattern
- **Comments:** Lines starting with `#`

## Environment Variables

Extensions can define environment variables in their scripts:

### In Scripts

```bash
#!/usr/bin/env bash
# Extension: My Extension

# Check if OraDBA is loaded
if [[ -z "${ORADBA_BASE}" ]]; then
    echo "Error: OraDBA not loaded"
    exit 1
fi

# Extension-specific variables
readonly MYEXT_HOME="${ORADBA_LOCAL_BASE}/myext"
readonly MYEXT_CONFIG="${ORADBA_PREFIX}/etc/myext.conf"

# Use OraDBA logging
log_info "My extension loaded"
```

### Available OraDBA Variables

Extensions have access to all OraDBA environment variables:

```bash
ORADBA_BASE           # OraDBA installation directory
ORADBA_PREFIX         # Configuration/logs directory
ORADBA_LOCAL_BASE     # Local extensions directory
ORACLE_BASE           # Oracle base directory
ORACLE_HOME           # Current Oracle home
ORACLE_SID            # Current database SID
```

## Directory Structure

Recommended structure for extension configurations:

```text
etc/
├── extension.conf.example     # Main configuration example
├── README.md                  # Configuration documentation
└── templates/                 # Configuration templates
    ├── development.conf       # Development environment
    ├── production.conf        # Production environment
    └── testing.conf           # Testing environment
```

## Configuration Best Practices

### 1. Provide Examples

Always include `.conf.example` files:

```bash
# Good: Comprehensive example
cat > etc/myext.conf.example <<'EOF'
# MyExt Configuration Example
#
# Copy needed settings to ${ORADBA_PREFIX}/etc/oradba_customer.conf

# Enable/disable extension
MYEXT_ENABLED="true"

# Feature flags
MYEXT_FEATURE_A="false"
MYEXT_FEATURE_B="true"

# Integration settings
MYEXT_API_URL="https://api.example.com"
MYEXT_TIMEOUT="30"
MYEXT_RETRY_COUNT="3"
EOF
```

### 2. Use Sensible Defaults

Provide defaults in scripts:

```bash
# Set defaults
MYEXT_ENABLED="${MYEXT_ENABLED:-true}"
MYEXT_TIMEOUT="${MYEXT_TIMEOUT:-30}"
MYEXT_RETRY_COUNT="${MYEXT_RETRY_COUNT:-3}"
```

### 3. Document Variables

Include inline documentation:

```bash
# MYEXT_ENABLED
#   Enable or disable the extension
#   Values: true, false
#   Default: true
MYEXT_ENABLED="true"

# MYEXT_TIMEOUT
#   API timeout in seconds
#   Values: 1-300
#   Default: 30
MYEXT_TIMEOUT="30"
```

### 4. Validate Configuration

Validate settings on load:

```bash
# Validate configuration
validate_config() {
    if [[ "${MYEXT_ENABLED}" != "true" && "${MYEXT_ENABLED}" != "false" ]]; then
        log_error "MYEXT_ENABLED must be 'true' or 'false'"
        return 1
    fi
    
    if [[ ! "${MYEXT_TIMEOUT}" =~ ^[0-9]+$ ]]; then
        log_error "MYEXT_TIMEOUT must be a number"
        return 1
    fi
    
    return 0
}

# Call validation
if ! validate_config; then
    log_error "Configuration validation failed"
    return 1
fi
```

### 5. Separate Secrets

Never include secrets in examples:

```bash
# Bad: Secret in example
MYEXT_API_KEY="your-secret-key-here"

# Good: Placeholder in example
MYEXT_API_KEY="<your-api-key>"
```

Add secrets to `.checksumignore`:

```text
# Secrets and credentials
etc/secrets.conf
*.key
*.pem
```

## Configuration Loading Order

OraDBA loads configurations in this order:

1. **Main config:** `${ORADBA_PREFIX}/etc/oradba.conf`
2. **Customer config:** `${ORADBA_PREFIX}/etc/oradba_customer.conf`
3. **Extension configs:** Auto-loaded from extensions
4. **Environment overrides:** Variables set in shell

Later configurations override earlier ones.

## Environment-Specific Configurations

Support multiple environments:

```bash
# Detect environment
ENVIRONMENT="${ORADBA_ENVIRONMENT:-development}"

# Load environment-specific config
if [[ -f "${MYEXT_HOME}/etc/${ENVIRONMENT}.conf" ]]; then
    source "${MYEXT_HOME}/etc/${ENVIRONMENT}.conf"
fi
```

Create environment templates:

```bash
etc/
├── development.conf     # Dev settings
├── testing.conf        # Test settings
└── production.conf     # Prod settings
```

## Advanced: Dynamic Configuration

Generate configuration dynamically:

```bash
# Generate config based on environment
generate_config() {
    local config_file="${1}"
    
    cat > "${config_file}" <<EOF
# Auto-generated configuration
MYEXT_HOSTNAME="$(hostname)"
MYEXT_ORACLE_HOME="${ORACLE_HOME}"
MYEXT_TIMESTAMP="$(date -Iseconds)"
EOF
}
```

## Next Steps

- See [Installation](installation.md) for setup instructions
- See [Reference](reference.md) for available scripts
- See [Development](development.md) for creating configurations
