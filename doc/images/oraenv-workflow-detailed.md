```mermaid
flowchart TD
    Start([source oraenv.sh NAME OPTIONS])
    
    Start --> Init[Initialize Script<br/>Set _ORAENV_SCRIPT_DIR<br/>Set ORADBA_PREFIX]
    
    Init --> LoadLibs[Load Libraries:<br/>1. oradba_common.sh<br/>2. oradba_registry.sh<br/>3. oradba_db_functions.sh<br/>4. extensions.sh optional<br/>5. oradba_env_parser.sh<br/>6. oradba_env_builder.sh<br/>7. oradba_env_validator.sh<br/>8. oradba_env_config.sh]
    
    LoadLibs --> LoadCoreConfig[load_config_file<br/>oradba_core.conf required]
    
    LoadCoreConfig --> CoreOK{Core<br/>loaded?}
    CoreOK -->|No| ErrorCore[Return 1<br/>Cannot continue]
    CoreOK -->|Yes| LoadLocalConfig[load_config_file<br/>oradba_local.conf optional]
    
    LoadLocalConfig --> SetOratab[Set ORATAB_FILE<br/>get_oratab_path]
    
    SetOratab --> ParseArgs[_oraenv_parse_args<br/>Process options]
    
    ParseArgs --> TTY{TTY<br/>detected?}
    
    TTY -->|Yes| SetInteractive[ORAENV_INTERACTIVE=true<br/>SHOW_STATUS=true]
    TTY -->|No| SetNonInteractive[ORAENV_INTERACTIVE=false<br/>SHOW_STATUS=false]
    
    SetInteractive --> ProcessOpts
    SetNonInteractive --> ProcessOpts[Process Options Loop:<br/>--silent, --status,<br/>--force, --help]
    
    ProcessOpts --> CheckHelp{--help<br/>flag?}
    CheckHelp -->|Yes| ShowHelp[_oraenv_usage<br/>Display help and return]
    CheckHelp -->|No| ExtractSID[Extract REQUESTED_SID<br/>from arguments]
    
    ExtractSID --> MainFunc[_oraenv_main<br/>Main execution function]
    
    MainFunc --> GetOratab[_oraenv_get_oratab_file<br/>Resolve oratab path]
    
    GetOratab --> OratFound{Oratab<br/>found?}
    OratFound -->|No| ErrorOrat[log_error<br/>Return 1]
    OratFound -->|Yes| CheckReqSID{REQUESTED_SID<br/>empty?}
    
    CheckReqSID -->|Yes| PromptFunc[_oraenv_prompt_sid oratab]
    
    PromptFunc --> GetLists[Get Available Options:<br/>1. oradba_registry_get_homes<br/>   → Oracle Homes<br/>2. oradba_registry_get_databases<br/>   → Database SIDs]
    
    GetLists --> CheckInteractiveMode{ORAENV_<br/>INTERACTIVE<br/>== true?}
    
    CheckInteractiveMode -->|Yes| DisplayMenu[Display Numbered Menu:<br/>Oracle Homes first<br/>Database SIDs second]
    DisplayMenu --> ReadInput[read -p "Enter name or number"]
    ReadInput --> ValidateInput{Input is<br/>number?}
    ValidateInput -->|Yes| MapNumber[Map number to<br/>HOME or SID]
    ValidateInput -->|No| UseDirectName[Use name directly]
    MapNumber --> SetEnvFunc
    UseDirectName --> SetEnvFunc
    
    CheckInteractiveMode -->|No| UseFirst[Select first entry:<br/>Home if available,<br/>else first SID]
    UseFirst --> SetEnvFunc
    
    CheckReqSID -->|No| SetEnvFunc[_oraenv_set_environment<br/>REQUESTED_SID oratab_file]
    
    SetEnvFunc --> CleanupOld[_oraenv_cleanup_environment<br/>Remove old Oracle paths]
    
    CleanupOld --> CheckIsHome{Is NAME an<br/>Oracle Home?}
    
    CheckIsHome -->|Test| TestHome[oradba_find_home NAME]
    TestHome -->|Found| IsHome
    TestHome -->|Not Found| IsSID
    
    CheckIsHome -->|Yes Home| IsHome[Process Oracle Home]
    CheckIsHome -->|No SID| IsSID[Process Database SID]
    
    IsHome --> RegLookup[oradba_find_home NAME<br/>Get registry entry]
    RegLookup --> ParseReg[Parse Registry:<br/>NAME|PATH|TYPE|ORDER|<br/>ALIAS|DESC|VERSION]
    ParseReg --> SetHome[export ORACLE_HOME=PATH]
    SetHome --> SetType[Set product type<br/>from registry]
    SetType --> CheckDataSafe{Type ==<br/>datasafe?}
    CheckDataSafe -->|Yes| SetDataSafePaths[Set DataSafe paths:<br/>oracle_cman_home/bin<br/>oracle_cman_home/lib<br/>DATASAFE_CONFIG]
    CheckDataSafe -->|No| SetStandardPaths[Set standard paths:<br/>ORACLE_HOME/bin<br/>ORACLE_HOME/lib]
    SetDataSafePaths --> DeriveBase
    SetStandardPaths --> DeriveBase[derive_oracle_base<br/>Auto-derive ORACLE_BASE]
    DeriveBase --> ExportBaseEnv[export_oracle_base_env<br/>Set TNS_ADMIN, etc.]
    ExportBaseEnv --> LoadConfigHome[load_config NAME<br/>Load hierarchical config]
    LoadConfigHome --> ReturnSuccess
    
    IsSID --> TryRegistry[oradba_registry_get_by_name<br/>REQUESTED_SID]
    TryRegistry --> RegFound{Registry<br/>entry found?}
    RegFound -->|Yes| ParseRegEntry[Parse: type|name|home|<br/>version|flags|order|<br/>alias|desc]
    ParseRegEntry --> ExtractHome[Extract ORACLE_HOME<br/>Create oratab_entry]
    
    RegFound -->|No| Fallback[parse_oratab<br/>REQUESTED_SID oratab_file]
    
    ExtractHome --> CheckEntry
    Fallback --> CheckEntry{oratab_entry<br/>found?}
    
    CheckEntry -->|No| AutoDiscoverCheck{Auto-discover<br/>enabled AND<br/>oratab empty?}
    AutoDiscoverCheck -->|Yes| RunDiscover[discover_running_oracle_instances]
    RunDiscover --> DiscoverResult{Instances<br/>found?}
    DiscoverResult -->|Yes| PersistOptional[persist_discovered_instances<br/>optional]
    PersistOptional --> ExtractFromDiscovered[Extract oratab_entry<br/>for REQUESTED_SID]
    ExtractFromDiscovered --> ValidateExtracted
    DiscoverResult -->|No| ErrorNotFound[log_error<br/>SID not found<br/>Return 1]
    AutoDiscoverCheck -->|No| ErrorNotFound
    
    CheckEntry -->|Yes| ValidateExtracted[Extract fields:<br/>actual_sid := field 1<br/>oracle_home := field 2<br/>startup_flag := field 3]
    
    ValidateExtracted --> CheckHomeDir{ORACLE_HOME<br/>directory exists?}
    CheckHomeDir -->|No| ErrorInvalidHome[log_error<br/>Invalid ORACLE_HOME<br/>Return 1]
    CheckHomeDir -->|Yes| SetSIDVars[export ORACLE_SID=actual_sid<br/>export ORACLE_HOME<br/>export ORACLE_STARTUP]
    
    SetSIDVars --> SetPaths[Set Product Paths:<br/>Detect type<br/>Set PATH appropriately]
    
    SetPaths --> DeriveBaseSID[derive_oracle_base<br/>ORACLE_HOME]
    DeriveBaseSID --> ExportBaseSID[export_oracle_base_env]
    ExportBaseSID --> LoadConfigSID[load_config actual_sid<br/>5-layer hierarchy]
    
    LoadConfigSID --> ConfigureSQLPATH{ORADBA_CONFIGURE_<br/>SQLPATH == true?}
    ConfigureSQLPATH -->|Yes| SetSQLPATH[configure_sqlpath<br/>Add extension SQL dirs]
    ConfigureSQLPATH -->|No| CheckExtensions
    SetSQLPATH --> CheckExtensions{ORADBA_AUTO_<br/>DISCOVER_EXTENSIONS<br/>== true?}
    
    CheckExtensions -->|Yes| LoadExtensions[discover_extensions<br/>Load from ORADBA_LOCAL_BASE]
    CheckExtensions -->|No| ReturnSuccess
    LoadExtensions --> ReturnSuccess[Return 0<br/>Success]
    
    ReturnSuccess --> BackToMain[Back to _oraenv_main]
    
    BackToMain --> StatusCheck{ORAENV_STATUS_ONLY<br/>== true?}
    StatusCheck -->|Yes| ForceStatus[show_database_status<br/>Always show]
    StatusCheck -->|No| InteractiveCheck{SHOW_STATUS<br/>== true AND<br/>function exists?}
    InteractiveCheck -->|Yes| ShowStatusFunc[show_database_status<br/>Display DB info]
    InteractiveCheck -->|No| SilentMode[Silent mode<br/>No output]
    
    ForceStatus --> Complete
    ShowStatusFunc --> Complete
    SilentMode --> Complete([Environment Set<br/>Script Complete])
    
    ErrorCore --> Failed
    ErrorOrat --> Failed
    ErrorNotFound --> Failed
    ErrorInvalidHome --> Failed
    ShowHelp --> Exit([Exit without<br/>setting environment])
    Failed([Setup Failed<br/>Return 1])
    
    style Start fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style LoadLibs fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style LoadCoreConfig fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style ParseArgs fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    style PromptFunc fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style DisplayMenu fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    
    style RegLookup fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style TryRegistry fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style Fallback fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    
    style SetSIDVars fill:#c5e1a5,stroke:#33691e,stroke-width:2px
    style LoadConfigSID fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style LoadConfigHome fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    
    style ShowStatusFunc fill:#c5e1a5,stroke:#33691e,stroke-width:2px
    style ForceStatus fill:#c5e1a5,stroke:#33691e,stroke-width:2px
    
    style Complete fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style Failed fill:#ffcdd2,stroke:#c62828,stroke-width:3px
    style Exit fill:#e0e0e0,stroke:#616161,stroke-width:2px
```
