# Customer Extension

This is an example OraDBA extension demonstrating the extension system.

## Purpose

Provides customer-specific Oracle database scripts, SQL queries, and RMAN backup scripts.

## Installation

This example extension is already in the correct location structure. For a real extension:

1. Create directory parallel to ORADBA_BASE:

   ```bash
   mkdir -p ${ORADBA_LOCAL_BASE}/customer
   ```

2. Copy this structure or create your own

3. Extension will be auto-discovered on next login

## Structure

```text
customer/
├── .extension              # Metadata (optional but recommended)
├── README.md              # This file
├── bin/
│   └── customer_tool.sh   # Example script (added to PATH)
├── sql/
│   └── customer_query.sql # Example SQL (added to SQLPATH)
├── rcv/
│   └── customer_backup.rman # Example RMAN script
└── etc/
    └── customer.conf.example  # Config examples
```

## Usage

### Navigation

```bash
# Navigate to extension directory
cdecustomer
```

### Scripts

```bash
# Run example tool (automatically in PATH)
customer_tool.sh

# Run SQL script (automatically in SQLPATH)
sqlplus / as sysdba
SQL> @customer_query.sql
```

### Configuration

Copy required settings from `etc/customer.conf.example` to:

```bash
${ORADBA_PREFIX}/etc/oradba_customer.conf
```

## Configuration Options

Add to `oradba_customer.conf`:

```bash
# Disable this extension
export ORADBA_EXT_CUSTOMER_ENABLED="false"

# Change load priority
export ORADBA_EXT_CUSTOMER_PRIORITY="5"
```

## Version History

- **1.0.0** (2026-01-02): Initial example extension

## Author

DBA Team
