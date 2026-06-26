# Static Analysis Findings - OraDBA

Date: 2026-06-26\
Repository: /Users/stefan.oehrli/Repos/own/oehrlis/oradba\
Tool Versions:

- ShellCheck 0.11.0
- shfmt 3.13.1
- .shellcheckrc exists: yes (severity=warning, SC1091/SC2030/SC2031/SC2314/SC2315/SC2329 disabled)

----------------------------------------------------------------------------------------------------

## ShellCheck Results

Aggregated by SC code. .shellcheckrc present and applied. Severity level: warning.

| Code   | Count | Examples (file:line)                                                                                       |
|--------|-------|------------------------------------------------------------------------------------------------------------|
| SC2016 | 2     | tests/test_oradba_aliases.bats:99, tests/test_oradba_aliases.bats:156                                      |
| SC2181 | 8     | tests/test_oradba_aliases.bats:299, tests/test_oradba_aliases.bats:312, tests/test_oradba_aliases.bats:325 |

----------------------------------------------------------------------------------------------------

## shfmt Conformance

shfmt version 3.13.1 run in diff mode (-d, no writes).

| Status                        | Count | Files (first 5 shown)                                                                                                                                     |
|-------------------------------|-------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| Non-conformant (indent style) | 7     | src/templates/init.d/oradba, tests/test_database_plugin.bats, tests/test_datasafe_plugin.bats, tests/test_extensions.bats, tests/test_oradba_aliases.bats |

**Indent Style Issue:** Files use 4-space indentation; shfmt expects tab indentation by default.
BATS files and template use spaces throughout.

----------------------------------------------------------------------------------------------------

## Risky Constructs Map

No judgment applied - raw static evidence only.

### cd without error handling (\|\| exit)

| File                        | Line | Pattern                         |
|-----------------------------|------|---------------------------------|
| tests/run_docker_tests.sh   | 134  | cd "\$PROJECT_ROOT"             |
| scripts/build_installer.sh  | 23   | cd "$`(dirname "`$SCRIPT_DIR")" |
| scripts/build_pdf.sh        | 239  | cd "\${PROJECT_ROOT}"           |
| scripts/validate_project.sh | 21   | cd "\$PROJECT_ROOT"             |

### /tmp literal temp files (non-mktemp)

| File                           | Line | Pattern                                                            |
|--------------------------------|------|--------------------------------------------------------------------|
| dist/oradba_install.sh         | 474  | \$0 --local /tmp/oradba-0.16.0.tar.gz                              |
| dist/oradba_install.sh         | 1030 | log_error " cp \${SCRIPT_INSTALL_DIR}/bin/oradba_install.sh /tmp/" |
| tests/test_guard_production.sh | 47   | cat \> /tmp/test_guard_minimal.sh \<\< 'EOF'                       |
| tests/test_guard_production.sh | 66   | bash /tmp/test_guard_minimal.sh                                    |
| tests/test_guard_production.sh | 75   | bash -c 'source /tmp/test_guard_minimal.sh 2\>&1'                  |

### eval usage

| File                       | Line | Pattern                                     |
|----------------------------|------|---------------------------------------------|
| src/bin/oradba_validate.sh | 131  | eval "\${test_command}" \> /dev/null 2\>&1; |
| src/bin/oraenv.sh          | 401  | eval "\${sids_var}=()"                      |
| src/bin/oraenv.sh          | 402  | eval "\${homes_var}=()"                     |
| src/bin/oraenv.sh          | 409  | eval "$`{sids_var}+=(\"`${sid}")"           |
| src/bin/oraenv.sh          | 419  | eval "$`{homes_var}+=(\"`${name}")"         |

### rm -rf with variables

| File                   | Line | Pattern                         |
|------------------------|------|---------------------------------|
| dist/oradba_install.sh | 221  | rm -rf "\$TEMP_DIR"             |
| dist/oradba_install.sh | 1363 | rm -rf "\$install_dir"          |
| dist/oradba_install.sh | 1448 | rm -rf "\$temp_config_dir"      |
| dist/oradba_install.sh | 1537 | rm -rf "\$install_dir"          |
| dist/oradba_install.sh | 2229 | rm -rf "\$RUNTIME_PRESERVE_DIR" |

### IFS changes

| File                   | Line | Pattern                                 |
|------------------------|------|-----------------------------------------|
| dist/oradba_install.sh | 253  | while IFS= read -r line; do             |
| dist/oradba_install.sh | 349  | while IFS= read -r src; do              |
| dist/oradba_install.sh | 362  | while IFS= read -r src; do              |
| dist/oradba_install.sh | 394  | while IFS= read -r src; do              |
| dist/oradba_install.sh | 1251 | IFS='.' read -ra v1_parts \<\<\< "\$v1" |

### Password/Secret Patterns

| File                   | Line | Pattern                                                           |
|------------------------|------|-------------------------------------------------------------------|
| src/bin/oradba_dbca.sh | 96   | --sys-password PWD (comment)                                      |
| src/bin/oradba_dbca.sh | 97   | --system-password PWD (comment)                                   |
| src/bin/oradba_dbca.sh | 410  | --sys-password)                                                   |
| src/bin/oradba_dbca.sh | 414  | --system-password)                                                |
| src/bin/oradba_dbca.sh | 532  | Passwords are required (use --sys-password and --system-password) |

### sudo/su Calls

| File                            | Line | Pattern                                                                    |
|---------------------------------|------|----------------------------------------------------------------------------|
| dist/oradba_install.sh          | 447  | Run as specific user (requires sudo)                                       |
| dist/oradba_install.sh          | 495  | sudo \$0 --prefix /opt/oradba --user oracle                                |
| dist/oradba_install.sh          | 719  | Suggests sudo if permissions insufficient                                  |
| dist/oradba_install.sh          | 737  | Run with sudo or choose a different --prefix                               |
| tests/docker_automated_tests.sh | 392  | if sudo cp /etc/oratab /etc/oratab.backup_autodiscovery 2\>/dev/null; then |

### chmod World-Writable (7???)

| File                     | Line | Pattern                                                                                   |
|--------------------------|------|-------------------------------------------------------------------------------------------|
| src/bin/oradba_sqlnet.sh | 208  | chmod 755 "$`{tns_admin}" "`${tns_admin}/admin" "$`{tns_admin}/log" "`${tns_admin}/trace" |

----------------------------------------------------------------------------------------------------

## Duplication Candidates

### Functions defined in multiple files

| Function     | Count | Files                                                                                                                                                                         |
|--------------|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| oradba_log() | 6     | scripts/select_tests.sh, src/bin/oradba_datasafe_debug.sh, src/bin/oradba_rman.sh, src/lib/oradba_common.sh, src/templates/script_template.sh, tests/test_guard_production.sh |
| setup()      | 45+   | BATS test files (standard fixture - expected duplication)                                                                                                                     |
| teardown()   | 38+   | BATS test files (standard fixture - expected duplication)                                                                                                                     |

----------------------------------------------------------------------------------------------------

## Naming Inconsistency

### Function Naming Patterns

| Pattern    | Count |
|------------|-------|
| lowercase  | 7     |
| snake_case | 4     |

Examples:

- lowercase: print, restart, setup, start, status (7 functions)
- snake_case: check_script, log_debug, log_message, oradba_log (4 functions)

### Variable Naming Patterns

| Pattern    | Count |
|------------|-------|
| UPPER_CASE | 28    |
| snake_case | 6     |
| lowercase  | 15    |

Examples:

- UPPER_CASE: SCRIPT_NAME, ORADBA_BIN, TEST_DIR, ORACLE_BASE (28 variables)
- snake_case: test_temp_dir, log_message, script_path (6 variables)
- lowercase: status, output, value (15 variables)

----------------------------------------------------------------------------------------------------

## Near-Identical Blocks (3+ lines)

Most duplication is in BATS test fixtures (setup/teardown) and test data generation blocks.
Representative samples:

| Block                                       | Occurrences | Files                                                 |
|---------------------------------------------|-------------|-------------------------------------------------------|
| mkdir -p "\${ds_home}/oracle_cman_home/..." | 9           | tests/test_datasafe_plugin.bats (multiple test cases) |
| CMCTL_MOCK / chmod +x / source              | 8           | tests/test_datasafe_plugin.bats                       |
| exit 0/1 patterns                           | 7           | tests/test_datasafe_plugin.bats                       |
| Color code defs (ANSI escape)               | 7           | tests/test_extensions.bats                            |

----------------------------------------------------------------------------------------------------

## Summary Statistics

| Category                              | Count          |
|---------------------------------------|----------------|
| Total shell files analyzed            | 75+            |
| ShellCheck violations (active)        | 10             |
| shfmt non-conformant files            | 7              |
| Risky construct patterns identified   | 50+            |
| Function name duplications (non-BATS) | 1 (oradba_log) |
| Naming pattern mix (functions)        | 2 styles       |
| Naming pattern mix (variables)        | 3 styles       |

----------------------------------------------------------------------------------------------------

## Notes

- BATS test files (.bats) have expected duplication: setup/teardown are standard fixtures
- Indent style: repo uses 4-space indents; shfmt default is tabs
- IFS changes are intentional (safe pattern: IFS= for read loops)
- eval usage in src/bin/oraenv.sh appears intentional for dynamic array construction
- Password references in src/bin/oradba_dbca.sh are in comments and parameter names, not hardcoded
  secrets
- sudo/su calls in dist/ are in documentation/suggestions, not direct execution
- chmod 755 does not expose security risk (not world-writable for write)
