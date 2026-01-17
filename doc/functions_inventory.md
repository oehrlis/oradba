# OraDBA Function Inventory

**Generated:** 2026-01-17 12:43:53

**Analysis Scope:** All shell scripts in `src/bin/` and `src/lib/`

## Overview Statistics

| Metric                       | Count |
|------------------------------|-------|
| Total Functions              | 374   |
| Functions in src/bin         | 227   |
| Functions in src/lib         | 147   |
| Large Functions (>100 lines) | 24    |
| Functions with unknown size  | 0     |

## Distribution by File

| File                    | Function Count |
|-------------------------|----------------|
| oradba_common.sh        | 54             |
| oradba_install.sh       | 30             |
| extensions.sh           | 20             |
| oradba_extension.sh     | 18             |
| oradba_sqlnet.sh        | 18             |
| oradba_check.sh         | 16             |
| oradba_logrotate.sh     | 14             |
| oradba_homes.sh         | 11             |
| oradba_db_functions.sh  | 11             |
| oradba_version.sh       | 10             |
| oradba_env_builder.sh   | 10             |
| oraup.sh                | 9              |
| oradba_services.sh      | 9              |
| oradba_rman.sh          | 9              |
| oradba_env_status.sh    | 9              |
| oradba_help.sh          | 8              |
| get_seps_pwd.sh         | 8              |
| oradba_dbctl.sh         | 8              |
| oraenv.sh               | 8              |
| oradba_env.sh           | 8              |
| oradba_lsnrctl.sh       | 8              |
| oradba_env_parser.sh    | 8              |
| oradba_env_config.sh    | 8              |
| sync_to_peers.sh        | 7              |
| sync_from_peers.sh      | 7              |
| oradba_env_validator.sh | 7              |
| oradba_env_changes.sh   | 7              |
| oradba_registry.sh      | 7              |
| longops.sh              | 6              |
| oradba_aliases.sh       | 6              |
| oradba_services_root.sh | 5              |
| oradba_setup.sh         | 5              |
| dbstatus.sh             | 3              |
| oradba_validate.sh      | 2              |
| sessionsql.sh           | 0              |
| imp_jobs.sh             | 0              |
| exp_jobs.sh             | 0              |
| rman_jobs.sh            | 0              |

## Complete Function List

| Function Name                       | File                    | Line | Size (lines) | Calls |
|-------------------------------------|-------------------------|------|--------------|-------|
| `usage`                             | dbstatus.sh             | 42   | 24           | 83    |
| `version`                           | dbstatus.sh             | 68   | 4            | 280   |
| `main`                              | dbstatus.sh             | 74   | 49           | 41    |
| `usage`                             | get_seps_pwd.sh         | 45   | 38           | 83    |
| `should_log`                        | get_seps_pwd.sh         | 85   | 6            | 31    |
| `get_entry`                         | get_seps_pwd.sh         | 93   | 5            | 2     |
| `parse_args`                        | get_seps_pwd.sh         | 100  | 19           | 4     |
| `validate_environment`              | get_seps_pwd.sh         | 121  | 18           | 1     |
| `load_wallet_password`              | get_seps_pwd.sh         | 141  | 13           | 1     |
| `search_wallet`                     | get_seps_pwd.sh         | 156  | 48           | 1     |
| `main`                              | get_seps_pwd.sh         | 206  | 6            | 41    |
| `usage`                             | longops.sh              | 39   | 45           | 83    |
| `parse_args`                        | longops.sh              | 86   | 34           | 4     |
| `monitor_longops`                   | longops.sh              | 122  | 62           | 2     |
| `display_header`                    | longops.sh              | 186  | 12           | 1     |
| `run_monitor`                       | longops.sh              | 200  | 57           | 1     |
| `main`                              | longops.sh              | 259  | 4            | 41    |
| `log_pass`                          | oradba_check.sh         | 66   | 5            | 21    |
| `log_fail`                          | oradba_check.sh         | 72   | 4            | 4     |
| `log_warn`                          | oradba_check.sh         | 77   | 5            | 45    |
| `log_info`                          | oradba_check.sh         | 83   | 5            | 167   |
| `log_header`                        | oradba_check.sh         | 89   | 6            | 11    |
| `usage`                             | oradba_check.sh         | 97   | 55           | 83    |
| `check_system_info`                 | oradba_check.sh         | 206  | 34           | 1     |
| `check_system_tools`                | oradba_check.sh         | 244  | 57           | 1     |
| `check_optional_tools`              | oradba_check.sh         | 305  | 35           | 2     |
| `check_github_connectivity`         | oradba_check.sh         | 344  | 45           | 1     |
| `check_disk_space`                  | oradba_check.sh         | 393  | 34           | 2     |
| `check_oracle_environment`          | oradba_check.sh         | 431  | 45           | 1     |
| `check_oracle_tools`                | oradba_check.sh         | 480  | 29           | 1     |
| `check_database_connectivity`       | oradba_check.sh         | 513  | 35           | 1     |
| `check_oracle_versions`             | oradba_check.sh         | 552  | 58           | 1     |
| `check_oradba_installation`         | oradba_check.sh         | 614  | 42           | 1     |
| `usage`                             | oradba_dbctl.sh         | 57   | 35           | 83    |
| `get_databases`                     | oradba_dbctl.sh         | 97   | 16           | 1     |
| `should_autostart`                  | oradba_dbctl.sh         | 116  | 8            | 0     |
| `ask_justification`                 | oradba_dbctl.sh         | 126  | 31           | 2     |
| `start_database`                    | oradba_dbctl.sh         | 159  | 50           | 2     |
| `open_all_pdbs`                     | oradba_dbctl.sh         | 211  | 17           | 1     |
| `stop_database`                     | oradba_dbctl.sh         | 230  | 64           | 2     |
| `show_status`                       | oradba_dbctl.sh         | 296  | 29           | 3     |
| `usage`                             | oradba_env.sh           | 72   | 35           | 83    |
| `cmd_list`                          | oradba_env.sh           | 112  | 64           | 3     |
| `cmd_show`                          | oradba_env.sh           | 181  | 86           | 2     |
| `cmd_validate`                      | oradba_env.sh           | 272  | 83           | 3     |
| `cmd_status`                        | oradba_env.sh           | 360  | 67           | 2     |
| `cmd_changes`                       | oradba_env.sh           | 432  | 22           | 2     |
| `cmd_version`                       | oradba_env.sh           | 459  | 8            | 2     |
| `main`                              | oradba_env.sh           | 471  | 34           | 41    |
| `usage`                             | oradba_extension.sh     | 72   | 109          | 83    |
| `validate_extension_name`           | oradba_extension.sh     | 185  | 23           | 2     |
| `download_github_release`           | oradba_extension.sh     | 212  | 71           | 1     |
| `download_extension_from_github`    | oradba_extension.sh     | 288  | 144          | 2     |
| `validate_extension_structure`      | oradba_extension.sh     | 437  | 21           | 2     |
| `update_extension`                  | oradba_extension.sh     | 463  | 92           | 2     |
| `cmd_create`                        | oradba_extension.sh     | 559  | 246          | 1     |
| `cmd_add`                           | oradba_extension.sh     | 809  | 279          | 1     |
| `format_status`                     | oradba_extension.sh     | 1092 | 14           | 2     |
| `cmd_list`                          | oradba_extension.sh     | 1110 | 91           | 3     |
| `cmd_info`                          | oradba_extension.sh     | 1205 | 31           | 1     |
| `cmd_validate`                      | oradba_extension.sh     | 1240 | 51           | 3     |
| `cmd_validate_all`                  | oradba_extension.sh     | 1295 | 36           | 1     |
| `cmd_discover`                      | oradba_extension.sh     | 1335 | 37           | 1     |
| `cmd_paths`                         | oradba_extension.sh     | 1376 | 30           | 1     |
| `cmd_enabled`                       | oradba_extension.sh     | 1410 | 34           | 1     |
| `cmd_disabled`                      | oradba_extension.sh     | 1448 | 30           | 1     |
| `main`                              | oradba_extension.sh     | 1482 | 47           | 41    |
| `show_main_help`                    | oradba_help.sh          | 32   | 39           | 2     |
| `show_alias_help`                   | oradba_help.sh          | 73   | 16           | 1     |
| `show_scripts_help`                 | oradba_help.sh          | 91   | 31           | 1     |
| `show_variables_help`               | oradba_help.sh          | 124  | 29           | 1     |
| `show_config_help`                  | oradba_help.sh          | 155  | 57           | 1     |
| `show_sql_help`                     | oradba_help.sh          | 214  | 17           | 1     |
| `show_online_help`                  | oradba_help.sh          | 233  | 18           | 1     |
| `main`                              | oradba_help.sh          | 253  | 43           | 41    |
| `show_usage`                        | oradba_homes.sh         | 41   | 100          | 6     |
| `list_homes`                        | oradba_homes.sh         | 146  | 92           | 2     |
| `show_home`                         | oradba_homes.sh         | 243  | 91           | 2     |
| `add_home`                          | oradba_homes.sh         | 339  | 250          | 3     |
| `remove_home`                       | oradba_homes.sh         | 594  | 55           | 2     |
| `discover_homes`                    | oradba_homes.sh         | 654  | 116          | 2     |
| `validate_homes`                    | oradba_homes.sh         | 775  | 71           | 2     |
| `export_config`                     | oradba_homes.sh         | 851  | 30           | 2     |
| `import_config`                     | oradba_homes.sh         | 886  | 134          | 2     |
| `dedupe_homes`                      | oradba_homes.sh         | 1025 | 83           | 2     |
| `main`                              | oradba_homes.sh         | 1112 | 46           | 41    |
| `determine_default_prefix`          | oradba_install.sh       | 33   | 85           | 1     |
| `log_info`                          | oradba_install.sh       | 122  | 3            | 167   |
| `log_warn`                          | oradba_install.sh       | 126  | 3            | 45    |
| `log_error`                         | oradba_install.sh       | 130  | 3            | 150   |
| `check_archived_version`            | oradba_install.sh       | 135  | 18           | 1     |
| `cleanup`                           | oradba_install.sh       | 155  | 5            | 6     |
| `backup_modified_files`             | oradba_install.sh       | 165  | 67           | 1     |
| `usage`                             | oradba_install.sh       | 234  | 82           | 83    |
| `check_required_tools`              | oradba_install.sh       | 318  | 69           | 1     |
| `check_optional_tools`              | oradba_install.sh       | 389  | 50           | 2     |
| `check_disk_space`                  | oradba_install.sh       | 441  | 47           | 2     |
| `check_permissions`                 | oradba_install.sh       | 490  | 53           | 1     |
| `detect_profile_file`               | oradba_install.sh       | 545  | 21           | 1     |
| `profile_has_oradba`                | oradba_install.sh       | 568  | 15           | 1     |
| `update_profile`                    | oradba_install.sh       | 585  | 100          | 1     |
| `run_preflight_checks`              | oradba_install.sh       | 687  | 30           | 1     |
| `version_compare`                   | oradba_install.sh       | 913  | 30           | 4     |
| `get_installed_version`             | oradba_install.sh       | 945  | 10           | 1     |
| `check_existing_installation`       | oradba_install.sh       | 957  | 14           | 1     |
| `backup_installation`               | oradba_install.sh       | 973  | 16           | 1     |
| `restore_from_backup`               | oradba_install.sh       | 991  | 20           | 1     |
| `preserve_configs`                  | oradba_install.sh       | 1013 | 27           | 1     |
| `restore_configs`                   | oradba_install.sh       | 1042 | 26           | 1     |
| `perform_update`                    | oradba_install.sh       | 1070 | 82           | 1     |
| `extract_embedded_payload`          | oradba_install.sh       | 1154 | 50           | 1     |
| `prompt_oracle_base`                | oradba_install.sh       | 1206 | 48           | 1     |
| `validate_write_permissions`        | oradba_install.sh       | 1256 | 37           | 1     |
| `create_temp_oratab`                | oradba_install.sh       | 1295 | 80           | 1     |
| `extract_local_tarball`             | oradba_install.sh       | 1377 | 51           | 1     |
| `extract_github_release`            | oradba_install.sh       | 1430 | 99           | 1     |
| `usage`                             | oradba_logrotate.sh     | 42   | 79           | 83    |
| `print_message`                     | oradba_logrotate.sh     | 123  | 5            | 60    |
| `check_root`                        | oradba_logrotate.sh     | 130  | 8            | 4     |
| `install_logrotate`                 | oradba_logrotate.sh     | 140  | 62           | 1     |
| `uninstall_logrotate`               | oradba_logrotate.sh     | 204  | 30           | 1     |
| `list_logrotate`                    | oradba_logrotate.sh     | 236  | 24           | 1     |
| `test_logrotate`                    | oradba_logrotate.sh     | 262  | 25           | 1     |
| `force_logrotate`                   | oradba_logrotate.sh     | 289  | 29           | 1     |
| `customize_logrotate`               | oradba_logrotate.sh     | 320  | 102          | 1     |
| `install_user`                      | oradba_logrotate.sh     | 424  | 129          | 1     |
| `run_user`                          | oradba_logrotate.sh     | 555  | 57           | 1     |
| `generate_cron`                     | oradba_logrotate.sh     | 614  | 19           | 1     |
| `show_version`                      | oradba_logrotate.sh     | 635  | 5            | 1     |
| `main`                              | oradba_logrotate.sh     | 642  | 48           | 41    |
| `usage`                             | oradba_lsnrctl.sh       | 47   | 32           | 83    |
| `get_first_oracle_home`             | oradba_lsnrctl.sh       | 84   | 19           | 1     |
| `set_listener_env`                  | oradba_lsnrctl.sh       | 105  | 24           | 4     |
| `get_running_listeners`             | oradba_lsnrctl.sh       | 131  | 6            | 1     |
| `ask_justification`                 | oradba_lsnrctl.sh       | 139  | 31           | 2     |
| `start_listener`                    | oradba_lsnrctl.sh       | 172  | 29           | 2     |
| `stop_listener`                     | oradba_lsnrctl.sh       | 203  | 29           | 2     |
| `show_status`                       | oradba_lsnrctl.sh       | 234  | 17           | 3     |
| `usage`                             | oradba_rman.sh          | 74   | 109          | 83    |
| `check_parallel_method`             | oradba_rman.sh          | 194  | 14           | 1     |
| `load_rman_config`                  | oradba_rman.sh          | 212  | 31           | 2     |
| `process_template`                  | oradba_rman.sh          | 247  | 288          | 2     |
| `execute_rman_for_sid`              | oradba_rman.sh          | 539  | 157          | 4     |
| `execute_parallel_background`       | oradba_rman.sh          | 700  | 26           | 1     |
| `execute_parallel_gnu`              | oradba_rman.sh          | 730  | 21           | 1     |
| `send_notification`                 | oradba_rman.sh          | 755  | 60           | 2     |
| `main`                              | oradba_rman.sh          | 819  | 191          | 41    |
| `usage`                             | oradba_services.sh      | 55   | 38           | 83    |
| `load_config`                       | oradba_services.sh      | 101  | 22           | 7     |
| `start_listeners`                   | oradba_services.sh      | 125  | 26           | 1     |
| `stop_listeners`                    | oradba_services.sh      | 153  | 26           | 1     |
| `start_databases`                   | oradba_services.sh      | 181  | 26           | 1     |
| `stop_databases`                    | oradba_services.sh      | 209  | 26           | 1     |
| `show_status`                       | oradba_services.sh      | 237  | 22           | 3     |
| `start_all`                         | oradba_services.sh      | 261  | 36           | 2     |
| `stop_all`                          | oradba_services.sh      | 299  | 36           | 2     |
| `check_root`                        | oradba_services_root.sh | 48   | 6            | 4     |
| `check_oracle_user`                 | oradba_services_root.sh | 56   | 6            | 1     |
| `check_services_script`             | oradba_services_root.sh | 64   | 11           | 1     |
| `run_as_oracle`                     | oradba_services_root.sh | 77   | 18           | 1     |
| `usage`                             | oradba_services_root.sh | 97   | 35           | 83    |
| `usage`                             | oradba_setup.sh         | 37   | 40           | 83    |
| `cmd_link_oratab`                   | oradba_setup.sh         | 81   | 101          | 1     |
| `cmd_check`                         | oradba_setup.sh         | 186  | 122          | 1     |
| `cmd_show_config`                   | oradba_setup.sh         | 312  | 60           | 1     |
| `main`                              | oradba_setup.sh         | 376  | 59           | 41    |
| `usage`                             | oradba_sqlnet.sh        | 42   | 44           | 83    |
| `get_tns_admin`                     | oradba_sqlnet.sh        | 88   | 9            | 6     |
| `backup_file`                       | oradba_sqlnet.sh        | 99   | 12           | 14    |
| `is_readonly_home`                  | oradba_sqlnet.sh        | 116  | 28           | 1     |
| `get_central_tns_admin`             | oradba_sqlnet.sh        | 146  | 10           | 0     |
| `create_tns_structure`              | oradba_sqlnet.sh        | 158  | 30           | 1     |
| `migrate_config_files`              | oradba_sqlnet.sh        | 190  | 34           | 1     |
| `create_symlinks`                   | oradba_sqlnet.sh        | 226  | 43           | 1     |
| `update_sqlnet_paths`               | oradba_sqlnet.sh        | 271  | 37           | 1     |
| `setup_tns_admin`                   | oradba_sqlnet.sh        | 310  | 66           | 2     |
| `setup_all_tns_admin`               | oradba_sqlnet.sh        | 378  | 45           | 1     |
| `install_sqlnet`                    | oradba_sqlnet.sh        | 425  | 36           | 1     |
| `generate_tnsnames`                 | oradba_sqlnet.sh        | 463  | 43           | 1     |
| `test_tnsalias`                     | oradba_sqlnet.sh        | 508  | 32           | 1     |
| `list_aliases`                      | oradba_sqlnet.sh        | 542  | 14           | 1     |
| `validate_config`                   | oradba_sqlnet.sh        | 558  | 51           | 1     |
| `backup_config`                     | oradba_sqlnet.sh        | 611  | 21           | 1     |
| `main`                              | oradba_sqlnet.sh        | 636  | 57           | 41    |
| `usage`                             | oradba_validate.sh      | 56   | 17           | 83    |
| `test_item`                         | oradba_validate.sh      | 92   | 26           | 67    |
| `check_version`                     | oradba_version.sh       | 54   | 10           | 3     |
| `get_checksum_exclusions`           | oradba_version.sh       | 72   | 58           | 2     |
| `check_integrity`                   | oradba_version.sh       | 136  | 116          | 3     |
| `check_additional_files`            | oradba_version.sh       | 256  | 50           | 1     |
| `check_extension_checksums`         | oradba_version.sh       | 310  | 146          | 1     |
| `show_installed_extensions`         | oradba_version.sh       | 460  | 58           | 1     |
| `check_updates`                     | oradba_version.sh       | 522  | 45           | 1     |
| `version_info`                      | oradba_version.sh       | 571  | 46           | 2     |
| `usage`                             | oradba_version.sh       | 621  | 30           | 83    |
| `main`                              | oradba_version.sh       | 655  | 61           | 41    |
| `_oraenv_parse_args`                | oraenv.sh               | 100  | 66           | 2     |
| `_oraenv_usage`                     | oraenv.sh               | 168  | 47           | 2     |
| `_oraenv_find_oratab`               | oraenv.sh               | 217  | 28           | 1     |
| `_oraenv_prompt_sid`                | oraenv.sh               | 247  | 126          | 1     |
| `_oraenv_set_environment`           | oraenv.sh               | 375  | 209          | 1     |
| `_oraenv_unset_old_env`             | oraenv.sh               | 586  | 10           | 2     |
| `_oraenv_show_environment`          | oraenv.sh               | 598  | 14           | 0     |
| `_oraenv_main`                      | oraenv.sh               | 614  | 59           | 11    |
| `show_usage`                        | oraup.sh                | 66   | 30           | 6     |
| `get_db_status`                     | oraup.sh                | 102  | 13           | 3     |
| `get_db_mode`                       | oraup.sh                | 121  | 46           | 2     |
| `get_listener_status`               | oraup.sh                | 173  | 11           | 1     |
| `should_show_listener_status`       | oraup.sh                | 195  | 56           | 1     |
| `get_startup_flag`                  | oraup.sh                | 257  | 6            | 1     |
| `show_oracle_status_registry`       | oraup.sh                | 270  | 142          | 2     |
| `show_oracle_status`                | oraup.sh                | 417  | 46           | 2     |
| `main`                              | oraup.sh                | 467  | 32           | 41    |
| `load_config`                       | sync_from_peers.sh      | 58   | 38           | 7     |
| `usage`                             | sync_from_peers.sh      | 98   | 44           | 83    |
| `should_log`                        | sync_from_peers.sh      | 144  | 6            | 31    |
| `parse_args`                        | sync_from_peers.sh      | 153  | 46           | 4     |
| `perform_sync`                      | sync_from_peers.sh      | 201  | 53           | 2     |
| `show_summary`                      | sync_from_peers.sh      | 256  | 12           | 2     |
| `main`                              | sync_from_peers.sh      | 270  | 10           | 41    |
| `load_config`                       | sync_to_peers.sh        | 56   | 38           | 7     |
| `usage`                             | sync_to_peers.sh        | 96   | 42           | 83    |
| `should_log`                        | sync_to_peers.sh        | 140  | 6            | 31    |
| `parse_args`                        | sync_to_peers.sh        | 149  | 46           | 4     |
| `perform_sync`                      | sync_to_peers.sh        | 197  | 44           | 2     |
| `show_summary`                      | sync_to_peers.sh        | 243  | 11           | 2     |
| `main`                              | sync_to_peers.sh        | 256  | 10           | 41    |
| `discover_extensions`               | extensions.sh           | 33   | 37           | 2     |
| `get_all_extensions`                | extensions.sh           | 78   | 23           | 9     |
| `get_extension_property`            | extensions.sh           | 117  | 30           | 7     |
| `parse_extension_metadata`          | extensions.sh           | 156  | 15           | 6     |
| `get_extension_name`                | extensions.sh           | 179  | 6            | 11    |
| `get_extension_version`             | extensions.sh           | 193  | 4            | 7     |
| `get_extension_description`         | extensions.sh           | 205  | 4            | 3     |
| `get_extension_priority`            | extensions.sh           | 217  | 4            | 6     |
| `is_extension_enabled`              | extensions.sh           | 230  | 7            | 8     |
| `extension_provides`                | extensions.sh           | 246  | 17           | 1     |
| `sort_extensions_by_priority`       | extensions.sh           | 275  | 17           | 4     |
| `remove_extension_paths`            | extensions.sh           | 304  | 31           | 2     |
| `deduplicate_path`                  | extensions.sh           | 344  | 27           | 2     |
| `deduplicate_sqlpath`               | extensions.sh           | 380  | 29           | 2     |
| `load_extensions`                   | extensions.sh           | 418  | 45           | 2     |
| `load_extension`                    | extensions.sh           | 471  | 70           | 2     |
| `create_extension_alias`            | extensions.sh           | 550  | 19           | 2     |
| `list_extensions`                   | extensions.sh           | 581  | 59           | 1     |
| `show_extension_info`               | extensions.sh           | 648  | 71           | 1     |
| `validate_extension`                | extensions.sh           | 731  | 64           | 2     |
| `create_dynamic_alias`              | oradba_aliases.sh       | 29   | 12           | 25    |
| `get_diagnostic_dest`               | oradba_aliases.sh       | 49   | 31           | 2     |
| `has_rlwrap`                        | oradba_aliases.sh       | 88   | 3            | 2     |
| `oradba_tnsping`                    | oradba_aliases.sh       | 102  | 47           | 2     |
| `generate_sid_aliases`              | oradba_aliases.sh       | 161  | 76           | 2     |
| `generate_base_aliases`             | oradba_aliases.sh       | 249  | 6            | 2     |
| `get_script_dir`                    | oradba_common.sh        | 25   | 10           | 1     |
| `init_logging`                      | oradba_common.sh        | 48   | 38           | 2     |
| `init_session_log`                  | oradba_common.sh        | 94   | 40           | 1     |
| `oradba_log`                        | oradba_common.sh        | 172  | 81           | 412   |
| `_show_deprecation_warning`         | oradba_common.sh        | 274  | 14           | 6     |
| `log_info`                          | oradba_common.sh        | 298  | 4            | 167   |
| `log_warn`                          | oradba_common.sh        | 312  | 4            | 45    |
| `log_error`                         | oradba_common.sh        | 326  | 4            | 150   |
| `log_debug`                         | oradba_common.sh        | 340  | 4            | 22    |
| `execute_db_query`                  | oradba_common.sh        | 354  | 58           | 10    |
| `get_oratab_path`                   | oradba_common.sh        | 426  | 49           | 12    |
| `is_dummy_sid`                      | oradba_common.sh        | 484  | 14           | 1     |
| `command_exists`                    | oradba_common.sh        | 506  | 3            | 1     |
| `alias_exists`                      | oradba_common.sh        | 522  | 15           | 2     |
| `safe_alias`                        | oradba_common.sh        | 550  | 25           | 6     |
| `verify_oracle_env`                 | oradba_common.sh        | 584  | 17           | 1     |
| `get_oracle_version`                | oradba_common.sh        | 610  | 13           | 2     |
| `parse_oratab`                      | oradba_common.sh        | 633  | 12           | 1     |
| `generate_sid_lists`                | oradba_common.sh        | 654  | 72           | 4     |
| `generate_oracle_home_aliases`      | oradba_common.sh        | 736  | 46           | 4     |
| `generate_pdb_aliases`              | oradba_common.sh        | 790  | 65           | 1     |
| `load_rman_catalog_connection`      | oradba_common.sh        | 864  | 25           | 1     |
| `discover_running_oracle_instances` | oradba_common.sh        | 903  | 83           | 3     |
| `persist_discovered_instances`      | oradba_common.sh        | 1001 | 99           | 3     |
| `export_oracle_base_env`            | oradba_common.sh        | 1111 | 15           | 3     |
| `validate_directory`                | oradba_common.sh        | 1138 | 20           | 2     |
| `get_oracle_homes_path`             | oradba_common.sh        | 1173 | 10           | 10    |
| `resolve_oracle_home_name`          | oradba_common.sh        | 1192 | 39           | 3     |
| `parse_oracle_home`                 | oradba_common.sh        | 1242 | 38           | 7     |
| `list_oracle_homes`                 | oradba_common.sh        | 1289 | 32           | 4     |
| `get_oracle_home_path`              | oradba_common.sh        | 1330 | 7            | 2     |
| `get_oracle_home_alias`             | oradba_common.sh        | 1346 | 7            | 2     |
| `get_oracle_home_type`              | oradba_common.sh        | 1362 | 7            | 4     |
| `detect_product_type`               | oradba_common.sh        | 1379 | 79           | 9     |
| `detect_oracle_version`             | oradba_common.sh        | 1467 | 89           | 1     |
| `derive_oracle_base`                | oradba_common.sh        | 1566 | 38           | 2     |
| `set_oracle_home_environment`       | oradba_common.sh        | 1621 | 112          | 3     |
| `is_oracle_home`                    | oradba_common.sh        | 1743 | 7            | 6     |
| `cleanup_previous_sid_config`       | oradba_common.sh        | 1761 | 23           | 2     |
| `capture_sid_config_vars`           | oradba_common.sh        | 1796 | 30           | 3     |
| `load_config_file`                  | oradba_common.sh        | 1841 | 36           | 8     |
| `load_config`                       | oradba_common.sh        | 1889 | 71           | 7     |
| `create_sid_config`                 | oradba_common.sh        | 1972 | 40           | 4     |
| `get_oradba_version`                | oradba_common.sh        | 2026 | 9            | 2     |
| `version_compare`                   | oradba_common.sh        | 2047 | 30           | 4     |
| `version_meets_requirement`         | oradba_common.sh        | 2088 | 10           | 2     |
| `get_install_info`                  | oradba_common.sh        | 2109 | 11           | 2     |
| `set_install_info`                  | oradba_common.sh        | 2132 | 20           | 2     |
| `init_install_info`                 | oradba_common.sh        | 2164 | 14           | 2     |
| `configure_sqlpath`                 | oradba_common.sh        | 2194 | 52           | 2     |
| `show_sqlpath`                      | oradba_common.sh        | 2255 | 19           | 1     |
| `show_path`                         | oradba_common.sh        | 2283 | 19           | 1     |
| `show_config`                       | oradba_common.sh        | 2312 | 72           | 1     |
| `add_to_sqlpath`                    | oradba_common.sh        | 2394 | 28           | 4     |
| `check_database_connection`         | oradba_db_functions.sh  | 30   | 17           | 2     |
| `get_database_open_mode`            | oradba_db_functions.sh  | 53   | 7            | 2     |
| `query_instance_info`               | oradba_db_functions.sh  | 66   | 21           | 2     |
| `query_database_info`               | oradba_db_functions.sh  | 93   | 23           | 3     |
| `query_datafile_size`               | oradba_db_functions.sh  | 122  | 14           | 2     |
| `query_memory_usage`                | oradba_db_functions.sh  | 142  | 21           | 2     |
| `query_sessions_info`               | oradba_db_functions.sh  | 169  | 20           | 2     |
| `query_pdb_info`                    | oradba_db_functions.sh  | 195  | 25           | 2     |
| `format_uptime`                     | oradba_db_functions.sh  | 227  | 23           | 2     |
| `show_oracle_home_status`           | oradba_db_functions.sh  | 256  | 37           | 2     |
| `show_database_status`              | oradba_db_functions.sh  | 299  | 168          | 4     |
| `oradba_dedupe_path`                | oradba_env_builder.sh   | 28   | 32           | 16    |
| `oradba_clean_path`                 | oradba_env_builder.sh   | 87   | 19           | 2     |
| `oradba_add_oracle_path`            | oradba_env_builder.sh   | 114  | 79           | 7     |
| `oradba_set_lib_path`               | oradba_env_builder.sh   | 201  | 77           | 2     |
| `oradba_detect_rooh`                | oradba_env_builder.sh   | 286  | 41           | 2     |
| `oradba_is_asm_instance`            | oradba_env_builder.sh   | 334  | 5            | 3     |
| `oradba_set_oracle_vars`            | oradba_env_builder.sh   | 348  | 69           | 3     |
| `oradba_set_asm_environment`        | oradba_env_builder.sh   | 424  | 11           | 2     |
| `oradba_set_product_environment`    | oradba_env_builder.sh   | 442  | 38           | 2     |
| `oradba_build_environment`          | oradba_env_builder.sh   | 487  | 107          | 1     |
| `oradba_get_file_signature`         | oradba_env_changes.sh   | 26   | 17           | 3     |
| `oradba_store_file_signature`       | oradba_env_changes.sh   | 51   | 27           | 4     |
| `oradba_check_file_changed`         | oradba_env_changes.sh   | 87   | 39           | 2     |
| `oradba_check_config_changes`       | oradba_env_changes.sh   | 134  | 38           | 3     |
| `oradba_init_change_tracking`       | oradba_env_changes.sh   | 180  | 25           | 1     |
| `oradba_clear_change_tracking`      | oradba_env_changes.sh   | 212  | 7            | 1     |
| `oradba_auto_reload_on_change`      | oradba_env_changes.sh   | 227  | 24           | 1     |
| `oradba_apply_config_section`       | oradba_env_config.sh    | 29   | 96           | 4     |
| `oradba_load_generic_configs`       | oradba_env_config.sh    | 133  | 21           | 12    |
| `oradba_load_sid_config`            | oradba_env_config.sh    | 162  | 17           | 2     |
| `oradba_apply_product_config`       | oradba_env_config.sh    | 187  | 53           | 2     |
| `oradba_expand_variables`           | oradba_env_config.sh    | 248  | 7            | 1     |
| `oradba_list_config_sections`       | oradba_env_config.sh    | 263  | 9            | 1     |
| `oradba_validate_config_file`       | oradba_env_config.sh    | 280  | 56           | 1     |
| `oradba_get_config_value`           | oradba_env_config.sh    | 346  | 47           | 1     |
| `oradba_parse_oratab`               | oradba_env_parser.sh    | 29   | 37           | 4     |
| `oradba_parse_homes`                | oradba_env_parser.sh    | 76   | 51           | 3     |
| `oradba_find_sid`                   | oradba_env_parser.sh    | 135  | 9            | 3     |
| `oradba_find_home`                  | oradba_env_parser.sh    | 153  | 43           | 2     |
| `oradba_get_home_metadata`          | oradba_env_parser.sh    | 206  | 30           | 4     |
| `oradba_list_all_sids`              | oradba_env_parser.sh    | 243  | 3            | 1     |
| `oradba_list_all_homes`             | oradba_env_parser.sh    | 254  | 8            | 2     |
| `oradba_get_product_type`           | oradba_env_parser.sh    | 270  | 84           | 4     |
| `oradba_check_db_status`            | oradba_env_status.sh    | 24   | 42           | 3     |
| `oradba_check_asm_status`           | oradba_env_status.sh    | 75   | 34           | 3     |
| `oradba_check_listener_status`      | oradba_env_status.sh    | 118  | 21           | 1     |
| `oradba_check_process_running`      | oradba_env_status.sh    | 147  | 18           | 4     |
| `oradba_check_datasafe_status`      | oradba_env_status.sh    | 174  | 22           | 2     |
| `oradba_get_datasafe_port`          | oradba_env_status.sh    | 205  | 37           | 1     |
| `oradba_check_oud_status`           | oradba_env_status.sh    | 250  | 28           | 2     |
| `oradba_check_wls_status`           | oradba_env_status.sh    | 286  | 23           | 2     |
| `oradba_get_product_status`         | oradba_env_status.sh    | 319  | 40           | 2     |
| `oradba_validate_oracle_home`       | oradba_env_validator.sh | 29   | 8            | 2     |
| `oradba_validate_sid`               | oradba_env_validator.sh | 44   | 16           | 2     |
| `oradba_check_oracle_binaries`      | oradba_env_validator.sh | 68   | 67           | 2     |
| `oradba_check_db_running`           | oradba_env_validator.sh | 142  | 12           | 4     |
| `oradba_get_db_version`             | oradba_env_validator.sh | 162  | 16           | 2     |
| `oradba_get_db_status`              | oradba_env_validator.sh | 186  | 32           | 2     |
| `oradba_validate_environment`       | oradba_env_validator.sh | 226  | 118          | 2     |
| `oradba_registry_get_all`           | oradba_registry.sh      | 35   | 73           | 5     |
| `oradba_registry_get_by_name`       | oradba_registry.sh      | 116  | 16           | 2     |
| `oradba_registry_get_by_type`       | oradba_registry.sh      | 140  | 14           | 2     |
| `oradba_registry_get_databases`     | oradba_registry.sh      | 161  | 3            | 2     |
| `oradba_registry_get_field`         | oradba_registry.sh      | 173  | 23           | 10    |
| `oradba_registry_discover_all`      | oradba_registry.sh      | 204  | 12           | 3     |
| `oradba_registry_validate`          | oradba_registry.sh      | 223  | 33           | 1     |

## Most Called Functions

Top 30 functions by call frequency:

| Function Name   | Call Count | File                    |
|-----------------|------------|-------------------------|
| `oradba_log`    | 412        | oradba_common.sh        |
| `version`       | 280        | dbstatus.sh             |
| `log_info`      | 167        | oradba_install.sh       |
| `log_info`      | 167        | oradba_check.sh         |
| `log_info`      | 167        | oradba_common.sh        |
| `log_error`     | 150        | oradba_install.sh       |
| `log_error`     | 150        | oradba_common.sh        |
| `usage`         | 83         | oradba_logrotate.sh     |
| `usage`         | 83         | oradba_services_root.sh |
| `usage`         | 83         | oradba_validate.sh      |
| `usage`         | 83         | get_seps_pwd.sh         |
| `usage`         | 83         | dbstatus.sh             |
| `usage`         | 83         | oradba_dbctl.sh         |
| `usage`         | 83         | oradba_setup.sh         |
| `usage`         | 83         | longops.sh              |
| `usage`         | 83         | oradba_env.sh           |
| `usage`         | 83         | oradba_version.sh       |
| `usage`         | 83         | sync_to_peers.sh        |
| `usage`         | 83         | oradba_lsnrctl.sh       |
| `usage`         | 83         | oradba_install.sh       |
| `usage`         | 83         | oradba_services.sh      |
| `usage`         | 83         | oradba_rman.sh          |
| `usage`         | 83         | oradba_extension.sh     |
| `usage`         | 83         | oradba_check.sh         |
| `usage`         | 83         | oradba_sqlnet.sh        |
| `usage`         | 83         | sync_from_peers.sh      |
| `test_item`     | 67         | oradba_validate.sh      |
| `print_message` | 60         | oradba_logrotate.sh     |
| `log_warn`      | 45         | oradba_install.sh       |
| `log_warn`      | 45         | oradba_check.sh         |

## Large Functions (>100 lines)

Functions exceeding 100 lines may benefit from refactoring:

| Function Name                    | File                    | Line | Size (lines) |
|----------------------------------|-------------------------|------|--------------|
| `process_template`               | oradba_rman.sh          | 247  | 288          |
| `cmd_add`                        | oradba_extension.sh     | 809  | 279          |
| `add_home`                       | oradba_homes.sh         | 339  | 250          |
| `cmd_create`                     | oradba_extension.sh     | 559  | 246          |
| `_oraenv_set_environment`        | oraenv.sh               | 375  | 209          |
| `main`                           | oradba_rman.sh          | 819  | 191          |
| `show_database_status`           | oradba_db_functions.sh  | 299  | 168          |
| `execute_rman_for_sid`           | oradba_rman.sh          | 539  | 157          |
| `check_extension_checksums`      | oradba_version.sh       | 310  | 146          |
| `download_extension_from_github` | oradba_extension.sh     | 288  | 144          |
| `show_oracle_status_registry`    | oraup.sh                | 270  | 142          |
| `import_config`                  | oradba_homes.sh         | 886  | 134          |
| `install_user`                   | oradba_logrotate.sh     | 424  | 129          |
| `_oraenv_prompt_sid`             | oraenv.sh               | 247  | 126          |
| `cmd_check`                      | oradba_setup.sh         | 186  | 122          |
| `oradba_validate_environment`    | oradba_env_validator.sh | 226  | 118          |
| `check_integrity`                | oradba_version.sh       | 136  | 116          |
| `discover_homes`                 | oradba_homes.sh         | 654  | 116          |
| `set_oracle_home_environment`    | oradba_common.sh        | 1621 | 112          |
| `usage`                          | oradba_rman.sh          | 74   | 109          |
| `usage`                          | oradba_extension.sh     | 72   | 109          |
| `oradba_build_environment`       | oradba_env_builder.sh   | 487  | 107          |
| `customize_logrotate`            | oradba_logrotate.sh     | 320  | 102          |
| `cmd_link_oratab`                | oradba_setup.sh         | 81   | 101          |

## Function Categories

Functions grouped by common prefixes/purposes:

### Builder/Generator

**Count:** 15 functions

- `create_dynamic_alias`
- `create_extension_alias`
- `create_sid_config`
- `create_symlinks`
- `create_temp_oratab`
- `create_tns_structure`
- `generate_base_aliases`
- `generate_cron`
- `generate_oracle_home_aliases`
- `generate_pdb_aliases`
- `generate_sid_aliases`
- `generate_sid_lists`
- `generate_tnsnames`
- `setup_all_tns_admin`
- `setup_tns_admin`

### Core API (oradba_)

**Count:** 58 functions

- `oradba_add_oracle_path`
- `oradba_apply_config_section`
- `oradba_apply_product_config`
- `oradba_auto_reload_on_change`
- `oradba_build_environment`
- `oradba_check_asm_status`
- `oradba_check_config_changes`
- `oradba_check_datasafe_status`
- `oradba_check_db_running`
- `oradba_check_db_status`
- `oradba_check_file_changed`
- `oradba_check_listener_status`
- `oradba_check_oracle_binaries`
- `oradba_check_oud_status`
- `oradba_check_process_running`
- `oradba_check_wls_status`
- `oradba_clean_path`
- `oradba_clear_change_tracking`
- `oradba_dedupe_path`
- `oradba_detect_rooh`
- `oradba_expand_variables`
- `oradba_find_home`
- `oradba_find_sid`
- `oradba_get_config_value`
- `oradba_get_datasafe_port`
- `oradba_get_db_status`
- `oradba_get_db_version`
- `oradba_get_file_signature`
- `oradba_get_home_metadata`
- `oradba_get_product_status`
- `oradba_get_product_type`
- `oradba_init_change_tracking`
- `oradba_is_asm_instance`
- `oradba_list_all_homes`
- `oradba_list_all_sids`
- `oradba_list_config_sections`
- `oradba_load_generic_configs`
- `oradba_load_sid_config`
- `oradba_log`
- `oradba_parse_homes`
- `oradba_parse_oratab`
- `oradba_registry_discover_all`
- `oradba_registry_get_all`
- `oradba_registry_get_by_name`
- `oradba_registry_get_by_type`
- `oradba_registry_get_databases`
- `oradba_registry_get_field`
- `oradba_registry_validate`
- `oradba_set_asm_environment`
- `oradba_set_lib_path`
- _(and 8 more)_

### Display

**Count:** 27 functions

- `display_header`
- `print_message`
- `show_alias_help`
- `show_config`
- `show_config_help`
- `show_database_status`
- `show_extension_info`
- `show_home`
- `show_installed_extensions`
- `show_main_help`
- `show_online_help`
- `show_oracle_home_status`
- `show_oracle_status`
- `show_oracle_status_registry`
- `show_path`
- `show_scripts_help`
- `show_sql_help`
- `show_sqlpath`
- `show_status`
- `show_summary`
- `show_usage`
- `show_variables_help`
- `show_version`

### Logging

**Count:** 16 functions

- `init_session_log`
- `log_debug`
- `log_error`
- `log_fail`
- `log_header`
- `log_info`
- `log_pass`
- `log_warn`
- `should_log`

### Other

**Count:** 179 functions

- `_oraenv_find_oratab`
- `_oraenv_main`
- `_oraenv_parse_args`
- `_oraenv_prompt_sid`
- `_oraenv_set_environment`
- `_oraenv_show_environment`
- `_oraenv_unset_old_env`
- `_oraenv_usage`
- `_show_deprecation_warning`
- `add_home`
- `add_to_sqlpath`
- `alias_exists`
- `ask_justification`
- `backup_config`
- `backup_file`
- `backup_installation`
- `backup_modified_files`
- `capture_sid_config_vars`
- `cleanup`
- `cleanup_previous_sid_config`
- `cmd_add`
- `cmd_changes`
- `cmd_check`
- `cmd_create`
- `cmd_disabled`
- `cmd_discover`
- `cmd_enabled`
- `cmd_info`
- `cmd_link_oratab`
- `cmd_list`
- `cmd_paths`
- `cmd_show`
- `cmd_show_config`
- `cmd_status`
- `cmd_validate`
- `cmd_validate_all`
- `cmd_version`
- `command_exists`
- `configure_sqlpath`
- `customize_logrotate`
- `dedupe_homes`
- `deduplicate_path`
- `deduplicate_sqlpath`
- `derive_oracle_base`
- `detect_oracle_version`
- `detect_product_type`
- `detect_profile_file`
- `determine_default_prefix`
- `discover_extensions`
- `discover_homes`
- _(and 89 more)_

### Parser/Getter

**Count:** 39 functions

- `extract_embedded_payload`
- `extract_github_release`
- `extract_local_tarball`
- `get_all_extensions`
- `get_central_tns_admin`
- `get_checksum_exclusions`
- `get_database_open_mode`
- `get_databases`
- `get_db_mode`
- `get_db_status`
- `get_diagnostic_dest`
- `get_entry`
- `get_extension_description`
- `get_extension_name`
- `get_extension_priority`
- `get_extension_property`
- `get_extension_version`
- `get_first_oracle_home`
- `get_install_info`
- `get_installed_version`
- `get_listener_status`
- `get_oracle_home_alias`
- `get_oracle_home_path`
- `get_oracle_home_type`
- `get_oracle_homes_path`
- `get_oracle_version`
- `get_oradba_version`
- `get_oratab_path`
- `get_running_listeners`
- `get_script_dir`
- `get_startup_flag`
- `get_tns_admin`
- `parse_args`
- `parse_extension_metadata`
- `parse_oracle_home`
- `parse_oratab`

### Validation

**Count:** 40 functions

- `check_additional_files`
- `check_archived_version`
- `check_database_connection`
- `check_database_connectivity`
- `check_disk_space`
- `check_existing_installation`
- `check_extension_checksums`
- `check_github_connectivity`
- `check_integrity`
- `check_optional_tools`
- `check_oracle_environment`
- `check_oracle_tools`
- `check_oracle_user`
- `check_oracle_versions`
- `check_oradba_installation`
- `check_parallel_method`
- `check_permissions`
- `check_required_tools`
- `check_root`
- `check_services_script`
- `check_system_info`
- `check_system_tools`
- `check_updates`
- `check_version`
- `is_dummy_sid`
- `is_extension_enabled`
- `is_oracle_home`
- `is_readonly_home`
- `validate_config`
- `validate_directory`
- `validate_environment`
- `validate_extension`
- `validate_extension_name`
- `validate_extension_structure`
- `validate_homes`
- `validate_write_permissions`
- `verify_oracle_env`

## Potential Issues

### Functions with High Call Frequency

Functions called more than 50 times (verify performance impact):

| Function Name   | Call Count |
|-----------------|------------|
| `oradba_log`    | 412        |
| `version`       | 280        |
| `log_info`      | 167        |
| `log_info`      | 167        |
| `log_info`      | 167        |
| `log_error`     | 150        |
| `log_error`     | 150        |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `usage`         | 83         |
| `test_item`     | 67         |
| `print_message` | 60         |

### Functions with Unknown Size

All function sizes successfully calculated. ✅

## Analysis Summary

### Key Findings

- **Total functions analyzed:** 374
- **Average function size:** 41 lines
- **Largest function:** 288 lines
- **Most called function:** 412 calls
- **Files analyzed:** 38
- **Average functions per file:** 9

### Recommendations

- Consider refactoring 24 large functions (>100 lines)
- Review 28 frequently-called functions for optimization
