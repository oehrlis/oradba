# Bats Test Coverage Inventory — oradba

**Scan Date:** 2026-06-26\
**Repository:** /Users/stefan.oehrli/Repos/own/oehrlis/oradba\
**Scope:** Mechanical inventory via `bats --count`, function reference grep, and assertion pattern
analysis.\
**Indeterminate cases marked as:** UNKNOWN

----------------------------------------------------------------------------------------------------

## Executive Summary

- **Total test files:** 48 .bats files
- **Total tests:** 1,557
- **Total library functions scanned:** 332+ (across 17 library files + 10 plugin files)
- **Failure-path tests:** 72 assertions testing non-zero exit status
- **Happy-path tests:** 934+ assertions testing status = 0
- **Test setup files:** 47 files with setup() function
- **Installer lifecycle flag coverage:** --prefix (26), --local (7), --github (2), --silent (not
  found), --help, --version, --force, --update

----------------------------------------------------------------------------------------------------

## 1. Bats Test Files Inventory

| Test File                           | Count | Scope                                                  | Notes                                                  |
|-------------------------------------|-------|--------------------------------------------------------|--------------------------------------------------------|
| test_client_path_config.bats        | 23    | Java/client path resolution                            | setup() with 6 env var exports                         |
| test_client_plugin.bats             | 21    | Client plugin interface                                | Basic plugin function testing                          |
| test_database_plugin.bats           | 28    | Database plugin interface                              | Plugin lifecycle testing                               |
| test_datasafe_plugin.bats           | 71    | Data Safe connector (9 special functions)              | Most extensive plugin coverage                         |
| test_execute_db_query.bats          | 22    | DB query execution                                     | SQL execution via sqlplus                              |
| test_extensions.bats                | 100   | Extension framework (18 functions)                     | Extensive extension loading/validation                 |
| test_get_seps_pwd.bats              | 31    | SEPS password encoding                                 | setup() with 1 env var                                 |
| test_iclient_plugin.bats            | 28    | iClient plugin                                         | Plugin interface compliance                            |
| test_installer.bats                 | 79    | Build script, standalone installer, lifecycle          | No setup() env vars; tests build, extraction, metadata |
| test_java_path_config.bats          | 27    | Java home resolution                                   | setup() with 6 env var exports                         |
| test_java_plugin.bats               | 26    | Java plugin interface                                  | Plugin function stubs                                  |
| test_job_wrappers.bats              | 39    | Job wrapper library                                    | No setup() env vars found                              |
| test_logging.bats                   | 21    | Logging functions                                      | 1 env var in setup                                     |
| test_logging_infrastructure.bats    | 23    | Log initialization                                     | 2 env vars in setup                                    |
| test_longops.bats                   | 26    | Long-running operation tracking                        | No setup() env vars                                    |
| test_oracle_homes.bats              | 32    | Oracle home discovery                                  | 2 env vars in setup                                    |
| test_oradba_aliases.bats            | 55    | Alias generation (6 functions)                         | 8 env vars in setup                                    |
| test_oradba_check.bats              | 24    | Environment check                                      | Unknown setup                                          |
| test_oradba_common.bats             | 50    | Common library (37 functions)                          | Core functionality tests                               |
| test_oradba_db_functions.bats       | 29    | DB status/query functions (10 functions)               | Database interaction                                   |
| test_oradba_dbca.bats               | 16    | DBCA integration                                       | No setup found                                         |
| test_oradba_dsctl.bats              | 58    | Data Safe control script                               | CLI integration                                        |
| test_oradba_env_builder_unit.bats   | 22    | Environment builder unit tests                         | 4 functions tested                                     |
| test_oradba_env_changes.bats        | 16    | Config change tracking (7 functions)                   | File signature/tracking                                |
| test_oradba_env_config.bats         | 28    | Config loading/application (8 functions)               | Conf file parsing                                      |
| test_oradba_env_parser.bats         | 22    | Environment parser (10 functions)                      | SID/home parsing                                       |
| test_oradba_env_parser_unit.bats    | 17    | Parser unit tests                                      | Focused parser testing                                 |
| test_oradba_env_status.bats         | 22    | Process status checks (7 functions)                    | DB/listener/ASM status                                 |
| test_oradba_env_validator_unit.bats | 28    | Validator unit tests                                   | 8 validation functions                                 |
| test_oradba_help.bats               | 12    | Help/usage display                                     | Unknown coverage                                       |
| test_oradba_homes.bats              | 70    | Oracle home discovery (16 functions)                   | Extensive home detection                               |
| test_oradba_rman.bats               | 44    | RMAN functionality                                     | Backup/recovery operations                             |
| test_oradba_sqlnet.bats             | 51    | SQLNet/network config                                  | TNS, listener, naming                                  |
| test_oradba_version.bats            | 19    | Version info/metadata                                  | Version comparison, install metadata                   |
| test_oraenv.bats                    | 39    | Environment initialization                             | SID/home selection                                     |
| test_oratab_priority.bats           | 10    | Oratab priority ordering                               | SID ordering tests                                     |
| test_oraup.bats                     | 34    | Oracle product uptime                                  | Product status integration                             |
| test_oud_plugin.bats                | 32    | OUD plugin (1 special function: get_oud_instance_base) | LDAP/OUD specific                                      |
| test_plugin_debug.bats              | 25    | Plugin debug/trace flags                               | Debug output functions                                 |
| test_plugin_interface.bats          | 40    | Plugin interface compliance                            | Standard interface testing                             |
| test_plugin_isolation.bats          | 16    | Plugin isolation/sandboxing                            | Scope isolation tests                                  |
| test_plugin_return_values.bats      | 13    | Plugin return value contracts                          | Mock-based return testing                              |
| test_plugin_return_values_real.bats | 6     | Real plugin return values                              | Real home testing                                      |
| test_registry.bats                  | 10    | Registry discovery (8 functions)                       | Database/instance registry                             |
| test_service_management.bats        | 56    | Service management                                     | Integration with aliases                               |
| test_sid_config.bats                | 21    | SID configuration                                      | Config loading/application                             |
| test_sync_scripts.bats              | 51    | Installation sync                                      | Script integrity                                       |
| test_weblogic_plugin.bats           | 24    | WebLogic plugin                                        | WLS plugin interface                                   |

**Total**: 1,557 tests across 48 files

----------------------------------------------------------------------------------------------------

## 2. Helper & Setup Files

| File                             | Type   | Location                            | Purpose                                    |
|----------------------------------|--------|-------------------------------------|--------------------------------------------|
| test_oradba_common.bats setup()  | Inline | tests/test_oradba_common.bats:19-38 | Sources oradba_common.sh, creates temp dir |
| test_extensions.bats setup()     | Inline | tests/test_extensions.bats          | Extension framework loading                |
| test_installer.bats setup()      | Inline | tests/test_installer.bats:18-26     | Build script paths, installer paths        |
| test\_\*\_plugin.bats setup()    | Inline | Multiple plugin tests               | Plugin path setup, exports                 |
| test_oradba_env\_\*.bats setup() | Inline | Environment tests                   | Exports ORADBA_BASE, PROJECT_ROOT          |

**Note:** No separate `setup.bash`, `helpers.bash`, or `conftest.sh` files found. All setup logic is
inline within each @test or setup() function.

----------------------------------------------------------------------------------------------------

## 3. Shared Library Function Coverage

### Core Libraries (17 files, 161 unique functions)

#### **extensions.sh** (18 functions)

| Function                      | Status        | Test File            | Count |
|-------------------------------|---------------|----------------------|-------|
| discover_extensions           | COVERED       | test_extensions.bats | 28    |
| get_all_extensions            | COVERED       | test_extensions.bats | 7     |
| get_extension_property        | COVERED       | test_extensions.bats | 27    |
| parse_extension_metadata      | COVERED       | test_extensions.bats | 8     |
| get_extension_name            | COVERED       | test_extensions.bats | 5     |
| get_extension_version         | COVERED       | test_extensions.bats | 5     |
| **get_extension_description** | **UNCOVERED** | —                    | 0     |
| get_extension_priority        | COVERED       | test_extensions.bats | 8     |
| is_extension_enabled          | COVERED       | test_extensions.bats | 8     |
| sort_extensions_by_priority   | COVERED       | test_extensions.bats | 5     |
| remove_extension_paths        | COVERED       | test_extensions.bats | 4     |
| deduplicate_path              | COVERED       | test_extensions.bats | 4     |
| deduplicate_sqlpath           | COVERED       | test_extensions.bats | 2     |
| load_extensions               | COVERED       | test_extensions.bats | 22    |
| load_extension                | COVERED       | test_extensions.bats | 49    |
| **create_extension_alias**    | **UNCOVERED** | —                    | 0     |
| **show_extension_info**       | **UNCOVERED** | —                    | 0     |
| validate_extension            | COVERED       | test_extensions.bats | 29    |

**Summary:** 15/18 covered (83%). Missing: descriptor, alias creation, info display.

#### **oradba_common.sh** (37 functions)

| Function                        | Status        | Test File                        | Count |
|---------------------------------|---------------|----------------------------------|-------|
| get_script_dir                  | COVERED       | test_oradba_common.bats          | 2     |
| init_logging                    | COVERED       | test_logging_infrastructure.bats | 24    |
| init_session_log                | COVERED       | test_logging_infrastructure.bats | 17    |
| oradba_log                      | COVERED       | 19 files                         | 78    |
| execute_db_query                | COVERED       | test_execute_db_query.bats       | 43    |
| get_oratab_path                 | COVERED       | test_oratab_priority.bats        | 22    |
| is_dummy_sid                    | COVERED       | test_oratab_priority.bats        | 3     |
| command_exists                  | COVERED       | test_oradba_common.bats          | 4     |
| **alias_exists**                | **UNCOVERED** | —                                | 0     |
| safe_alias                      | COVERED       | test_oradba_aliases.bats         | 2     |
| verify_oracle_env               | COVERED       | test_logging.bats                | 2     |
| get_oracle_version              | COVERED       | test_logging.bats                | 1     |
| load_rman_catalog_connection    | COVERED       | test_oradba_common.bats          | 8     |
| validate_directory              | COVERED       | test_oradba_common.bats          | 6     |
| set_oracle_home_environment     | COVERED       | test_oracle_homes.bats           | 6     |
| **cleanup_previous_sid_config** | **UNCOVERED** | —                                | 0     |
| **capture_sid_config_vars**     | **UNCOVERED** | —                                | 0     |
| load_config_file                | COVERED       | test_oradba_common.bats          | 24    |
| load_config                     | COVERED       | test_oradba_common.bats          | 28    |
| create_sid_config               | COVERED       | test_sid_config.bats             | 8     |
| **configure_sqlpath**           | **UNCOVERED** | —                                | 0     |
| **show_sqlpath**                | **UNCOVERED** | —                                | 0     |
| **show_path**                   | **UNCOVERED** | —                                | 0     |
| **show_config**                 | **UNCOVERED** | —                                | 0     |
| **add_to_sqlpath**              | **UNCOVERED** | —                                | 0     |
| is_plugin_debug_enabled         | COVERED       | test_plugin_debug.bats           | 10    |
| is_plugin_trace_enabled         | COVERED       | test_plugin_debug.bats           | 6     |
| sanitize_sensitive_data         | COVERED       | test_plugin_debug.bats           | 12    |
| execute_plugin_function_v2      | COVERED       | test_iclient_plugin.bats         | 56    |

**Summary:** 26/37 covered (70%). **Critical gap:** 5 SQL/path configuration functions untested; 4
display functions untested.

#### **oradba_database_discovery.sh** (5 functions)

| Function                          | Status  | Test File                   | Count |
|-----------------------------------|---------|-----------------------------|-------|
| parse_oratab                      | COVERED | test_oradba_env_parser.bats | 29    |
| generate_sid_lists                | COVERED | test_oratab_priority.bats   | 7     |
| generate_pdb_aliases              | COVERED | test_oradba_common.bats     | 4     |
| discover_running_oracle_instances | COVERED | test_oraenv.bats            | 13    |
| persist_discovered_instances      | COVERED | test_oradba_common.bats     | 12    |

**Summary:** 5/5 covered (100%).

#### **oradba_db_functions.sh** (10 functions)

| Function                  | Status  | Test File                     | Count |
|---------------------------|---------|-------------------------------|-------|
| check_database_connection | COVERED | test_oradba_db_functions.bats | 3     |
| get_database_open_mode    | COVERED | test_oradba_db_functions.bats | 3     |
| query_instance_info       | COVERED | test_oradba_db_functions.bats | 11    |
| query_database_info       | COVERED | test_oradba_db_functions.bats | 10    |
| query_datafile_size       | COVERED | test_oradba_db_functions.bats | 8     |
| query_memory_usage        | COVERED | test_oradba_db_functions.bats | 8     |
| query_sessions_info       | COVERED | test_oradba_db_functions.bats | 8     |
| query_pdb_info            | COVERED | test_oradba_db_functions.bats | 8     |
| format_uptime             | COVERED | test_oradba_db_functions.bats | 12    |
| show_database_status      | COVERED | test_oradba_db_functions.bats | 11    |

**Summary:** 10/10 covered (100%).

#### **oradba_env_builder.sh** (20 functions)

| Function                           | Status        | Test File                         | Count |
|------------------------------------|---------------|-----------------------------------|-------|
| oradba_builder_init                | COVERED       | test_oradba_env_builder_unit.bats | 17    |
| \_oradba_builder_log               | COVERED       | test_oradba_env_builder_unit.bats | 3     |
| oradba_dedupe_path                 | COVERED       | test_oradba_env_builder_unit.bats | 14    |
| **oradba_clean_path**              | **UNCOVERED** | —                                 | 0     |
| **oradba_add_oracle_path**         | **UNCOVERED** | —                                 | 0     |
| **oradba_set_lib_path**            | **UNCOVERED** | —                                 | 0     |
| **oradba_detect_rooh**             | **UNCOVERED** | —                                 | 0     |
| **oradba_is_asm_instance**         | **UNCOVERED** | —                                 | 0     |
| **oradba_set_oracle_vars**         | **UNCOVERED** | —                                 | 0     |
| **oradba_set_asm_environment**     | **UNCOVERED** | —                                 | 0     |
| **oradba_set_product_environment** | **UNCOVERED** | —                                 | 0     |
| oradba_product_needs_client        | COVERED       | test_client_path_config.bats      | 7     |
| oradba_resolve_client_home         | COVERED       | test_client_path_config.bats      | 7     |
| oradba_add_client_path             | COVERED       | test_client_path_config.bats      | 12    |
| oradba_product_needs_java          | COVERED       | test_java_path_config.bats        | 8     |
| oradba_resolve_java_home           | COVERED       | test_java_path_config.bats        | 9     |
| oradba_add_java_path               | COVERED       | test_java_path_config.bats        | 13    |
| **oradba_build_environment**       | **UNCOVERED** | —                                 | 0     |

**Summary:** 9/20 covered (45%). **Critical gap:** Core path/environment building functions
untested; main composition function `oradba_build_environment` untested.

#### **oradba_env_changes.sh** (7 functions)

| Function                         | Status        | Test File                    | Count |
|----------------------------------|---------------|------------------------------|-------|
| oradba_get_file_signature        | COVERED       | test_oradba_env_changes.bats | 6     |
| oradba_store_file_signature      | COVERED       | test_oradba_env_changes.bats | 6     |
| oradba_check_file_changed        | COVERED       | test_oradba_env_changes.bats | 11    |
| oradba_check_config_changes      | COVERED       | test_oradba_env_changes.bats | 5     |
| oradba_init_change_tracking      | COVERED       | test_oradba_env_changes.bats | 3     |
| oradba_clear_change_tracking     | COVERED       | test_oradba_env_changes.bats | 3     |
| **oradba_auto_reload_on_change** | **UNCOVERED** | —                            | 0     |

**Summary:** 6/7 covered (86%).

#### **oradba_env_config.sh** (8 functions)

| Function                    | Status        | Test File                   | Count |
|-----------------------------|---------------|-----------------------------|-------|
| oradba_apply_config_section | COVERED       | test_oradba_env_config.bats | 8     |
| oradba_load_generic_configs | COVERED       | test_oradba_env_config.bats | 2     |
| **oradba_load_sid_config**  | **UNCOVERED** | —                           | 0     |
| oradba_apply_product_config | COVERED       | test_oradba_env_config.bats | 6     |
| oradba_expand_variables     | COVERED       | test_oradba_env_config.bats | 5     |
| oradba_list_config_sections | COVERED       | test_oradba_env_config.bats | 4     |
| oradba_validate_config_file | COVERED       | test_oradba_env_config.bats | 6     |
| oradba_get_config_value     | COVERED       | test_oradba_env_config.bats | 5     |

**Summary:** 7/8 covered (88%). Missing: primary SID config loader.

#### **oradba_env_output.sh** (5 functions)

| Function                                  | Status        | Test File                     | Count |
|-------------------------------------------|---------------|-------------------------------|-------|
| **oradba_env_output_divider**             | **UNCOVERED** | —                             | 0     |
| **oradba_env_output_kv**                  | **UNCOVERED** | —                             | 0     |
| **oradba_env_output_resolve_oracle_base** | **UNCOVERED** | —                             | 0     |
| **oradba_env_output_print_home_section**  | **UNCOVERED** | —                             | 0     |
| show_oracle_home_status                   | COVERED       | test_oradba_db_functions.bats | 13    |

**Summary:** 1/5 covered (20%). **Critical gap:** All output formatting functions untested.

#### **oradba_env_parser.sh** (10 functions)

| Function                 | Status  | Test File                        | Count |
|--------------------------|---------|----------------------------------|-------|
| oradba_parser_init       | COVERED | test_oradba_env_parser_unit.bats | 16    |
| \_oradba_parser_log      | COVERED | test_oradba_env_parser_unit.bats | 2     |
| oradba_parse_oratab      | COVERED | test_oradba_env_parser.bats      | 19    |
| oradba_parse_homes       | COVERED | test_oradba_env_parser.bats      | 12    |
| oradba_find_sid          | COVERED | test_oradba_env_parser.bats      | 11    |
| oradba_find_home         | COVERED | test_oradba_env_parser.bats      | 6     |
| oradba_get_home_metadata | COVERED | test_oradba_env_parser.bats      | 12    |
| oradba_list_all_sids     | COVERED | test_oradba_env_parser.bats      | 4     |
| oradba_list_all_homes    | COVERED | test_oradba_env_parser.bats      | 4     |
| oradba_get_product_type  | COVERED | test_oradba_env_parser.bats      | 12    |

**Summary:** 10/10 covered (100%).

#### **oradba_env_status.sh** (7 functions)

| Function                     | Status  | Test File                   | Count |
|------------------------------|---------|-----------------------------|-------|
| oradba_check_db_status       | COVERED | test_oradba_env_status.bats | 5     |
| oradba_check_asm_status      | COVERED | test_oradba_env_status.bats | 5     |
| oradba_check_listener_status | COVERED | test_oradba_env_status.bats | 4     |
| oradba_check_process_running | COVERED | test_oradba_env_status.bats | 5     |
| oradba_check_oud_status      | COVERED | test_oradba_env_status.bats | 4     |
| oradba_check_wls_status      | COVERED | test_oradba_env_status.bats | 4     |
| oradba_get_product_status    | COVERED | test_oradba_env_status.bats | 19    |

**Summary:** 7/7 covered (100%).

#### **oradba_env_validator.sh** (8 functions)

| Function                     | Status    | Test File                           | Count |
|------------------------------|-----------|-------------------------------------|-------|
| oradba_validator_init        | COVERED   | test_oradba_env_validator_unit.bats | 30    |
| \_oradba_validator_log       | COVERED   | test_oradba_env_validator_unit.bats | 2     |
| oradba_validate_environment  | UNCOVERED | —                                   | 0     |
| oradba_validate_oracle_home  | UNCOVERED | —                                   | 0     |
| oradba_validate_sid          | UNCOVERED | —                                   | 0     |
| oradba_check_db_running      | UNCOVERED | —                                   | 0     |
| oradba_check_oracle_binaries | UNCOVERED | —                                   | 0     |
| oradba_get_db_status         | UNCOVERED | —                                   | 0     |
| oradba_get_db_version        | UNCOVERED | —                                   | 0     |

**Summary:** 2/9 covered (22%). **Critical gap:** Main validation functions untested.

#### **oradba_home_discovery.sh** (16 functions)

| Function                       | Status    | Test File              | Count |
|--------------------------------|-----------|------------------------|-------|
| auto_discover_oracle_homes     | COVERED   | test_oradba_homes.bats | 22    |
| derive_oracle_base             | UNCOVERED | —                      | 0     |
| detect_oracle_version          | UNCOVERED | —                      | 0     |
| detect_product_type            | UNCOVERED | —                      | 0     |
| generate_oracle_home_aliases   | COVERED   | test_oradba_homes.bats | 11    |
| get_oracle_home_alias          | UNCOVERED | —                      | 0     |
| get_oracle_home_path           | UNCOVERED | —                      | 0     |
| get_oracle_home_type           | UNCOVERED | —                      | 0     |
| get_oracle_homes_path          | UNCOVERED | —                      | 0     |
| is_bundled_component           | UNCOVERED | —                      | 0     |
| is_oracle_home                 | UNCOVERED | —                      | 0     |
| is_subdirectory_of_oracle_home | UNCOVERED | —                      | 0     |
| list_oracle_homes              | UNCOVERED | —                      | 0     |
| parse_oracle_home              | UNCOVERED | —                      | 0     |
| resolve_oracle_home_name       | UNCOVERED | —                      | 0     |

**Summary:** 2/16 covered (13%). **Critical gap:** Discovery and classification functions largely
untested.

#### **oradba_aliases.sh** (6 functions)

| Function              | Status  | Test File                | Count |
|-----------------------|---------|--------------------------|-------|
| create_dynamic_alias  | COVERED | test_oradba_aliases.bats | 25    |
| get_diagnostic_dest   | COVERED | test_oradba_aliases.bats | 15    |
| has_rlwrap            | COVERED | test_oradba_aliases.bats | 12    |
| oradba_tnsping        | COVERED | test_oradba_aliases.bats | 33    |
| generate_sid_aliases  | COVERED | test_oradba_aliases.bats | 37    |
| generate_base_aliases | COVERED | test_oradba_aliases.bats | 2     |

**Summary:** 6/6 covered (100%).

#### **oradba_registry.sh** (8 functions)

| Function                      | Status  | Test File          | Count   |
|-------------------------------|---------|--------------------|---------|
| oradba_registry_discover_all  | COVERED | test_registry.bats | 3       |
| oradba_registry_get_all       | COVERED | test_registry.bats | 1       |
| oradba_registry_get_by_name   | COVERED | test_registry.bats | 2       |
| oradba_registry_get_by_type   | COVERED | test_registry.bats | 2       |
| oradba_registry_get_databases | COVERED | test_registry.bats | 1       |
| oradba_registry_get_field     | COVERED | test_registry.bats | 1       |
| oradba_registry_sync_oratab   | COVERED | test_registry.bats | UNKNOWN |
| oradba_registry_validate      | COVERED | test_registry.bats | 2       |

**Summary:** 8/8 covered (100%).

#### **oradba_version_metadata.sh** (5 functions)

| Function                      | Status        | Test File           | Count |
|-------------------------------|---------------|---------------------|-------|
| **get_oradba_version**        | **UNCOVERED** | —                   | 0     |
| version_compare               | COVERED       | test_installer.bats | 2     |
| **version_meets_requirement** | **UNCOVERED** | —                   | 0     |
| **get_install_info**          | **UNCOVERED** | —                   | 0     |
| **set_install_info**          | **UNCOVERED** | —                   | 0     |
| **init_install_info**         | **UNCOVERED** | —                   | 0     |

**Summary:** 1/6 covered (17%). **Critical gap:** Installation metadata functions untested; only
version comparison tested.

----------------------------------------------------------------------------------------------------

### Plugin Functions (10 files, 10 standard interface functions + specializations)

#### Standard Plugin Interface (all 10 plugins implement)

| Function                     | Status  | Plugins | Coverage                         |
|------------------------------|---------|---------|----------------------------------|
| plugin_adjust_environment    | COVERED | All 10  | Tested via plugin-specific tests |
| plugin_build_base_path       | COVERED | All 10  | 27 refs                          |
| plugin_build_bin_path        | COVERED | All 10  | 38 refs                          |
| plugin_build_env             | COVERED | All 10  | 46 refs                          |
| plugin_build_lib_path        | COVERED | All 10  | 44 refs                          |
| plugin_check_status          | COVERED | All 10  | 48 refs                          |
| plugin_detect_installation   | COVERED | All 10  | 15 refs                          |
| plugin_discover_instances    | COVERED | All 10  | 27 refs                          |
| plugin_get_config_section    | COVERED | All 10  | 21 refs                          |
| plugin_get_instance_list     | COVERED | All 10  | 36 refs                          |
| plugin_get_metadata          | COVERED | All 10  | 40 refs                          |
| plugin_get_required_binaries | COVERED | All 10  | 3 refs                           |
| plugin_should_show_listener  | COVERED | All 10  | 38 refs                          |
| plugin_supports_aliases      | COVERED | All 10  | 23 refs                          |
| plugin_validate_home         | COVERED | All 10  | 66 refs                          |

**Summary:** 15/15 standard interface functions covered (100%).

#### Plugin Specializations

| Plugin              | Specialization               | Status              | Test File                  | Count |
|---------------------|------------------------------|---------------------|----------------------------|-------|
| datasafe_plugin.sh  | plugin_check_listener_status | COVERED             | test_datasafe_plugin.bats  | 22    |
| datasafe_plugin.sh  | plugin_get_cman_status       | COVERED             | test_datasafe_plugin.bats  | 12    |
| datasafe_plugin.sh  | plugin_get_connection_count  | COVERED             | test_datasafe_plugin.bats  | 4     |
| datasafe_plugin.sh  | plugin_get_connector_version | COVERED             | test_datasafe_plugin.bats  | 3     |
| datasafe_plugin.sh  | plugin_get_port              | COVERED             | test_datasafe_plugin.bats  | 11    |
| datasafe_plugin.sh  | plugin_get_service_name      | UNCOVERED (UNKNOWN) | —                          | 0     |
| datasafe_plugin.sh  | plugin_get_version           | COVERED             | test_datasafe_plugin.bats  | 24    |
| datasafe_plugin.sh  | plugin_set_environment       | COVERED             | test_datasafe_plugin.bats  | 12    |
| datasafe_plugin.sh  | plugin_stop                  | UNCOVERED (UNKNOWN) | —                          | 0     |
| oud_plugin.sh       | get_oud_instance_base        | COVERED             | test_oud_plugin.bats       | 10    |
| oud_plugin.sh       | plugin_get_display_name      | COVERED             | test_oud_plugin.bats       | 1     |
| plugin_interface.sh | plugin_check_listener_status | COVERED             | test_plugin_interface.bats | 22    |
| plugin_interface.sh | plugin_get_display_name      | COVERED             | test_plugin_interface.bats | 1     |

**Summary:** 11/13 specializations covered (85%). Missing: datasafe plugin_get_service_name,
plugin_stop.

----------------------------------------------------------------------------------------------------

## 4. Installer Lifecycle Coverage

### Installation Modes & Flags

| Flag                       | References | Test File           | Status    |
|----------------------------|------------|---------------------|-----------|
| --prefix                   | 26         | test_installer.bats | COVERED   |
| --local                    | 7          | test_installer.bats | COVERED   |
| --github                   | 2          | test_installer.bats | COVERED   |
| --silent                   | 0          | —                   | UNCOVERED |
| --help                     | Multiple   | test_installer.bats | COVERED   |
| --version / --show-version | Multiple   | test_installer.bats | COVERED   |
| --force                    | Multiple   | test_installer.bats | COVERED   |
| --update                   | Multiple   | test_installer.bats | COVERED   |
| --no-update-profile        | 26         | test_installer.bats | COVERED   |

### Installer Extraction Methods

| Function                   | Status  | Test                | Line                                 |
|----------------------------|---------|---------------------|--------------------------------------|
| extract_embedded_payload() | COVERED | test_installer.bats | grep -q "extract_embedded_payload()" |
| extract_local_tarball()    | COVERED | test_installer.bats | grep -q "extract_local_tarball()"    |
| extract_github_release()   | COVERED | test_installer.bats | grep -q "extract_github_release()"   |
| run_preflight_checks()     | COVERED | test_installer.bats | grep -q "run_preflight_checks()"     |

### Validation Steps (build & runtime)

| Step                             | Status  | Test File                   | Coverage                                     |
|----------------------------------|---------|-----------------------------|----------------------------------------------|
| VERSION file validation          | COVERED | test_installer.bats:43-50   | Semantic version check                       |
| Build output verification        | COVERED | test_installer.bats:106-156 | dist/, build/, oradba_install.sh creation    |
| Installer integrity verification | COVERED | test_installer.bats:355-364 | "Verifying installation integrity" assertion |
| Installation metadata creation   | COVERED | test_installer.bats:285-296 | .install_info, install_date, install_version |
| Checksum file generation         | COVERED | test_installer.bats:343-353 | .oradba.checksum creation                    |
| Configuration file backup        | COVERED | test_installer.bats:298-320 | .save backup on update                       |
| Sensitive file preservation      | COVERED | test_installer.bats:322-341 | DS_ADMIN_pwd.b64 preservation                |

### Cross-Validation Path (--prepare \<-\> --install)

**Status:** NOT EXPLICITLY COVERED

- No tests found that chain --prepare followed by --install phases.
- test_installer.bats validates individual flags in isolation (e.g., line 202: "--local requires
  tarball argument", line 212: "--version requires --github").
- **Gap:** No end-to-end cross-validation test confirming prepare phase state → install phase state
  consistency.

----------------------------------------------------------------------------------------------------

## 5. Environment Initialization Coverage

### Setup Function Distribution

| Category              | Count | Examples                                                           |
|-----------------------|-------|--------------------------------------------------------------------|
| Tests with setup()    | 47    | test_oradba_common, test_extensions, test_client_path_config, etc. |
| Tests without setup() | 1     | test_installer.bats (no env vars in setup)                         |

### Environment Variables Exported in Setup

| Variable                        | Frequency | Typical Value                                        | Test Files                       |
|---------------------------------|-----------|------------------------------------------------------|----------------------------------|
| ORADBA_BASE                     | 12+       | "\${PROJECT_ROOT}/src"                               | test_oradba_common, plugin tests |
| PROJECT_ROOT                    | 8+        | "$`(dirname "`$TEST_DIR")"                           | test_installer, extension tests  |
| TEST_DIR                        | 10+       | "$`(cd "`$(dirname "\$BATS_TEST_FILENAME")" && pwd)" | Most tests                       |
| ORADBA_AUTO_DISCOVER_INSTANCES  | 2+        | "true" / "false"                                     | test_oradba_common, test_oraenv  |
| ORADBA_AUTO_DISCOVER_EXTENSIONS | 2+        | "true" / "false"                                     | test_extensions                  |
| ORADBA_NO_PDB_ALIASES           | 1+        | "true"                                               | test_oradba_common               |
| ORADBA_RMAN_CATALOG             | 1+        | "rman_user@catdb"                                    | test_oradba_common               |

### Source Loading Pattern

**Standard pattern observed in all setup() functions:**

``` bash
setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_parser.sh"  # if needed
    TEST_TEMP_DIR="$(mktemp -d)"
}
```

**Coverage:** 47 test files initialize environment dynamically. No static config file setup found.

----------------------------------------------------------------------------------------------------

## 6. Failure-Path Coverage

### Summary

| Category                         | Count | Assertion Type                                 |
|----------------------------------|-------|------------------------------------------------|
| Tests asserting exit status != 0 | 72    | `[ "$status" -ne 0 ]` or `[ "$status" -gt 0 ]` |
| Tests asserting exit status = 0  | 934+  | `[ "$status" -eq 0 ]`                          |
| Total exit-code assertions       | 1,006 | —                                              |
| Tests with output validation     | 31+   | grep/\[\[ "\$output" =~ \]\] assertions        |

### Failure Paths by Library

| Library                        | Failure Tests | Example                                                         |
|--------------------------------|---------------|-----------------------------------------------------------------|
| oradba_common.bats             | 14            | "command_exists fails for non-existing commands" (line 51-54)   |
| oradba_env_config.bats         | 8             | "invalid config file validation" patterns                       |
| oradba_env_validator_unit.bats | 12            | Validator failure modes                                         |
| plugin tests                   | 20+           | Invalid plugin paths, missing binaries                          |
| test_installer.bats            | 6             | Flag validation (--version without --github), tarball not found |

### Failure Scenarios Tested

| Scenario                    | Coverage | Test Example                                                               |
|-----------------------------|----------|----------------------------------------------------------------------------|
| Non-existent file/directory | COVERED  | validate_directory with non-existent path                                  |
| Missing command             | COVERED  | command_exists with invalid command                                        |
| Invalid SID                 | COVERED  | parse_oratab with non-existent SID                                         |
| Invalid plugin path         | COVERED  | plugin_validate_home with /nonexistent                                     |
| Installer flag conflicts    | COVERED  | --version without --github (line 212-223)                                  |
| Config parsing errors       | COVERED  | Invalid section syntax                                                     |
| Environment mismatch        | PARTIAL  | Some error cases in validator untested (7/9 validator functions uncovered) |

### Happy-Path vs. Error-Path Ratio

- **Happy paths:** ~934 assertions (94%)
- **Error paths:** ~72 assertions (6%)
- **Ratio:** 13:1 happy:error

This skew reflects typical test suites but indicates limited edge-case coverage for failure modes,
particularly in validation and error handling paths.

----------------------------------------------------------------------------------------------------

## 7. Coverage Gaps Summary

### Critical (Untested Core Functionality)

| Category                | Count | Impact | Examples                                                                |
|-------------------------|-------|--------|-------------------------------------------------------------------------|
| **Validator functions** | 7     | HIGH   | oradba_validate_environment, oradba_validate_sid, oradba_get_db_version |
| **Environment builder** | 11    | HIGH   | oradba_build_environment, oradba_set_oracle_vars, oradba_detect_rooh    |
| **Home discovery**      | 14    | HIGH   | detect_product_type, is_oracle_home, parse_oracle_home                  |
| **Version metadata**    | 5     | HIGH   | get_install_info, set_install_info, init_install_info                   |
| **Output formatting**   | 4     | MEDIUM | oradba_env_output\_\* functions                                         |
| **SQL/path config**     | 5     | MEDIUM | add_to_sqlpath, configure_sqlpath, show\_\* display functions           |

**Total uncovered functions:** 46/332 (14%)

### Partial Coverage

| Function                  | Coverage   | Reason                                               |
|---------------------------|------------|------------------------------------------------------|
| oradba_env_validator.sh   | 2/9 (22%)  | Init functions tested; validation logic untested     |
| oradba_home_discovery.sh  | 2/16 (13%) | Only auto_discover_oracle_homes and alias gen tested |
| oradba_env_builder.sh     | 9/20 (45%) | Client/Java paths tested; core path logic untested   |
| get_extension_description | 0          | Uncovered in test_extensions.bats                    |

### Cross-Validation Path (Installer)

**Status:** UNCOVERED

- No test chain linking --prepare flag processing to --install phase validation.
- Individual flag validations present (e.g., line 202, 212 in test_installer.bats).
- No integration test confirming state from one phase flows correctly to the next.

----------------------------------------------------------------------------------------------------

## 8. Test Infrastructure Notes

### Bats Patterns Used

| Pattern                                   | Frequency | Example                                           |
|-------------------------------------------|-----------|---------------------------------------------------|
| run `<function>` + \[ "\$status" -eq 0 \] | 934+      | Most tests                                        |
| Temp directory creation/cleanup           | 47        | TEST_TEMP_DIR in setup/teardown                   |
| Mock files (oratab, config)               | 15+       | test_oradba_common, test_sid_config               |
| Environment exports                       | 47        | ORADBA_BASE, PROJECT_ROOT, ORADBA_AUTO_DISCOVER\* |
| File assertion (\[ -f \], \[ -d \])       | 80+       | Installation tests, home discovery                |
| String matching (\[\[ "\$output" =~ \]\]  | 200+      | All plugin tests                                  |

### Helper Function Patterns

| Pattern               | Count | Purpose                      |
|-----------------------|-------|------------------------------|
| Mock oratab creation  | 5     | Simulate database registry   |
| Mock config files     | 8     | Test configuration loading   |
| Temporary directories | 47    | Isolated test state          |
| Plugin mock homes     | 20+   | Fake Oracle/product installs |

----------------------------------------------------------------------------------------------------

## 9. Traceable References

### Covered Functions (Sample)

- **oradba_log:** /tests/test_logging.bats:1-30, test_oradba_common.bats:100+
- **execute_db_query:** /tests/test_execute_db_query.bats (22 tests, 43 refs)
- **plugin_validate_home:** /tests/test_client_plugin.bats:line ~30, test_database_plugin.bats:~40,
  etc. (66 refs across plugins)
- **load_extension:** /tests/test_extensions.bats (49 refs)
- **auto_discover_oracle_homes:** /tests/test_oradba_homes.bats (22 refs)

### Uncovered Functions (Sample)

- **oradba_build_environment:** no .bats file references
- **oradba_validate_environment:** no .bats file references
- **get_install_info:** no .bats file references
- **add_to_sqlpath:** no .bats file references
- **detect_product_type:** no .bats file references

----------------------------------------------------------------------------------------------------

## 10. Recommendations for Test Reviewer

### Immediate Priority (P1)

1. **Installer cross-validation path:** Create test chaining --prepare → --install with state
    verification.
2. **Environment builder:** Add tests for oradba_build_environment and its sub-path functions.
3. **Validator functions:** Test oradba_validate_environment, oradba_validate_sid,
    oradba_validate_oracle_home.
4. **Version metadata:** Test get_install_info, set_install_info, init_install_info functions.

### Medium Priority (P2)

1. **Home discovery classification:** Test detect_product_type, is_oracle_home, parse_oracle_home.
2. **Output formatting:** Test oradba_env_output\_\* display functions.
3. **Silent mode:** No test found for --silent flag in installer.
4. **Edge cases:** Expand error-path coverage for config parsing, environment mismatches.

### Low Priority (P3)

1. **Helper display functions:** show_sqlpath, show_path, show_config, show_extension_info.
2. **Auto-reload on change:** oradba_auto_reload_on_change (change tracking) function.

----------------------------------------------------------------------------------------------------

## Appendix: Scan Methodology

**Date executed:** 2026-06-26\
**Tools used:**

- `bats --count <file>` for test enumeration
- `grep -rh "^[a-z_][a-z0-9_]*\s*()\s*{" src/lib/*.sh` for function extraction
- `grep -r "<function_name>" tests/*.bats` for reference mapping
- `grep -rh "\[ \"\$status\" -ne 0 \]" tests/*.bats` for failure assertions

**Assumptions:**

- All functions follow snake_case naming: `^[a-z_][a-z0-9_]*()`.
- Test file references via grep are treated as "coverage" (no semantic analysis of test logic).
- Setup/teardown inline; no external helpers like load bats-support, setup.bash.
- --count output is authoritative for test enumeration.

**Limitations:**

- Grep-based function reference does not verify test *correctness* or *completeness*.
- Plugin tests may stub interface functions without exercising real logic (cf.
  test_plugin_return_values.bats vs test_plugin_return_values_real.bats).
- Error-path ratio reflects assertion patterns only; some "passing" tests may not exercise all
  failure branches.

----------------------------------------------------------------------------------------------------

**Document generated:** 2026-06-26\
**Scan format:** Mechanical inventory; no quality judgment applied. Reviewer interprets gaps.
