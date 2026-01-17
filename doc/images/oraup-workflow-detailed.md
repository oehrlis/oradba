```mermaid
flowchart TD
    Start([oraup.sh])
    
    Start --> Init[Script Initialization<br/>Set SCRIPT_DIR<br/>Set ORADBA_BASE]
    
    Init --> LoadCommon{oradba_common.sh<br/>available?}
    LoadCommon -->|Yes| SourceCommon[source oradba_common.sh]
    LoadCommon -->|No| ContinueLoad
    SourceCommon --> ContinueLoad
    
    ContinueLoad --> LoadStatus{oradba_env_status.sh<br/>available?}
    LoadStatus -->|Yes| SourceStatus[source oradba_env_status.sh]
    LoadStatus -->|No| LoadRegistry
    SourceStatus --> LoadRegistry{oradba_registry.sh<br/>available?}
    
    LoadRegistry -->|No| RegistryError[Set registry_available=false]
    LoadRegistry -->|Yes| SourceRegistry[source oradba_registry.sh]
    
    SourceRegistry --> LoadPlugins[Load all plugins:<br/>for plugin in plugins/*.sh]
    LoadPlugins --> LoopPlugins{More<br/>plugins?}
    LoopPlugins -->|Yes| CheckPlugin{Plugin file<br/>exists AND<br/>not interface?}
    CheckPlugin -->|Yes| SourcePlugin[source plugin<br/>Load plugin functions]
    CheckPlugin -->|No| NextPlugin
    SourcePlugin --> NextPlugin[Next plugin]
    NextPlugin --> LoopPlugins
    LoopPlugins -->|No| GetOratab
    
    RegistryError --> GetOratab[Get oratab path<br/>get_oratab_path or fallback]
    
    GetOratab --> MainFunc[main<br/>Entry point function]
    
    MainFunc --> InitFlags[Initialize flags:<br/>verbose=false<br/>quiet=false]
    
    InitFlags --> ArgLoop{More<br/>arguments?}
    ArgLoop -->|Yes| CheckArg{Argument<br/>type?}
    CheckArg -->|--help/-h| SetHelp[show_usage<br/>Exit 0]
    CheckArg -->|--verbose/-v| SetVerbose[verbose=true]
    CheckArg -->|--quiet/-q| SetQuiet[quiet=true]
    CheckArg -->|Unknown| ShowError[echo Unknown option<br/>show_usage<br/>Exit 1]
    SetVerbose --> NextArg
    SetQuiet --> NextArg[shift<br/>Next argument]
    NextArg --> ArgLoop
    ArgLoop -->|No| CallShow[show_oracle_status<br/>verbose flag]
    
    CallShow --> ShowHeader[echo Header:<br/>Oracle Environment Status<br/>printf column headers]
    
    ShowHeader --> CheckRegAPI{type -t<br/>oradba_registry_get_all<br/>exists?}
    
    CheckRegAPI -->|No| ShowRegError[Display:<br/>Registry API not available<br/>Check installation integrity]
    ShowRegError --> ReturnError[Return 1]
    
    CheckRegAPI -->|Yes| CallGetAll[oradba_registry_get_all]
    
    CallGetAll --> MapArray[mapfile -t all_installations<br/>Store results in array]
    
    MapArray --> CheckCount{installations<br/>array empty?}
    
    CheckCount -->|Yes| ShowEmpty[Display:<br/>No Oracle installations found<br/>Instructions to register]
    ShowEmpty --> ReturnSuccess
    
    CheckCount -->|No| CallShowRegistry[show_oracle_status_registry<br/>installations array]
    
    CallShowRegistry --> InitArrays[Initialize arrays:<br/>databases array<br/>other_homes array]
    
    InitArrays --> SeparateLoop[Loop: for install in installations]
    SeparateLoop --> GetType[oradba_registry_get_field<br/>install "type"]
    GetType --> TypeCheck{ptype ==<br/>"database"?}
    TypeCheck -->|Yes| AddDB[databases+= install]
    TypeCheck -->|No| AddHome[other_homes+= install]
    AddDB --> NextInstall
    AddHome --> NextInstall{More<br/>installations?}
    NextInstall -->|Yes| SeparateLoop
    NextInstall -->|No| CheckHomes{other_homes<br/>count > 0?}
    
    CheckHomes -->|Yes| HomeLoop[for home_obj in other_homes]
    HomeLoop --> ExtractHomeFields[Extract fields:<br/>name= get_field "name"<br/>home= get_field "home"<br/>ptype= get_field "type"]
    
    ExtractHomeFields --> InitStatus[status= "available"]
    InitStatus --> CheckPluginType{type -t<br/>ptype_plugin.sh<br/>exists?}
    
    CheckPluginType -->|Yes| LoadPluginFile[plugin_file= plugins/ptype_plugin.sh<br/>source plugin_file if exists]
    CheckPluginType -->|No| CheckStatusFunc
    LoadPluginFile --> CheckStatusFunc{type -t<br/>plugin_check_status<br/>exists?}
    
    CheckStatusFunc -->|Yes| CallCheckStatus[status= plugin_check_status home]
    CheckStatusFunc -->|No| MapDisplay
    CallCheckStatus --> MapDisplay[Map ptype to display_type:<br/>datasafe → DataSafe Conn<br/>client|iclient → Client<br/>oud → OUD<br/>weblogic → WebLogic<br/>grid → Grid Infra<br/>oms → OMS<br/>emagent → EM Agent<br/>default → ORACLE_HOME]
    
    MapDisplay --> PrintHomeStatus[printf "%-17s : %-12s %-11s %s"<br/>display_type name status home]
    
    PrintHomeStatus --> NextHome{More<br/>other_homes?}
    NextHome -->|Yes| HomeLoop
    NextHome -->|No| CheckDBs
    
    CheckHomes -->|No| CheckDBs{databases<br/>count > 0?}
    
    CheckDBs -->|Yes| DBLoop[for db_obj in databases]
    DBLoop --> ExtractDBFields[Extract fields:<br/>sid= get_field "name"<br/>home= get_field "home"<br/>flags= get_field "flags"]
    
    ExtractDBFields --> CallGetDBStatus[get_db_status sid]
    
    CallGetDBStatus --> PSCheck[ps -ef grep -E<br/>db_pmon_SID or ora_pmon_sid]
    PSCheck --> PmonFound{Pmon<br/>found?}
    PmonFound -->|Yes| SetUp[status= "up"]
    PmonFound -->|No| SetDown[status= "down"]
    
    SetUp --> CheckUpStatus{status ==<br/>"up"?}
    SetDown --> CheckUpStatus
    
    CheckUpStatus -->|Yes| CallGetMode[get_db_mode sid home]
    CallGetMode --> SetEnv[Set temp environment:<br/>ORACLE_HOME=home<br/>ORACLE_SID=sid]
    SetEnv --> QueryInstance[sqlplus -S / as sysdba<br/>SELECT status FROM v$instance]
    QueryInstance --> CleanMode[Clean output:<br/>tr -d newlines<br/>sed trim spaces<br/>tr to lowercase]
    CleanMode --> ValidateMode{Result<br/>valid?}
    ValidateMode -->|Yes| UpdateStatus[status= mode<br/>open|mounted|started]
    ValidateMode -->|No| FallbackQuery[Try v$database.open_mode]
    FallbackQuery --> UpdateStatus
    UpdateStatus --> PrintDB
    
    CheckUpStatus -->|No| PrintDB[printf "%-17s : %-12s %-11s %s"<br/>"DB-instance flags" sid status home]
    
    PrintDB --> NextDB{More<br/>databases?}
    NextDB -->|Yes| DBLoop
    NextDB -->|No| ShowListenerSection
    
    CheckDBs -->|No| CheckDataSafeOnly
    
    ShowListenerSection --> ListenerHeader[echo blank line<br/>echo Listener Status<br/>echo separators]
    
    ListenerHeader --> FindListeners[ps -ef grep tnslsnr<br/>grep -v datasafe/oracle_cman_home]
    
    FindListeners --> InitLsnrCount[listener_count=0]
    InitLsnrCount --> ListenerLoop{More<br/>listener<br/>processes?}
    
    ListenerLoop -->|Yes| ExtractLsnrName[Extract listener_name<br/>awk print $NF]
    ExtractLsnrName --> InitLsnrStatus[lsnr_status= "unknown"]
    InitLsnrStatus --> CheckLsnrctl{command -v<br/>lsnrctl<br/>exists?}
    
    CheckLsnrctl -->|Yes| RunLsnrctl[lsnrctl status listener_name<br/>2>/dev/null]
    RunLsnrctl --> GrepReady[grep -q "ready"]
    GrepReady --> ReadyFound{Ready<br/>found?}
    ReadyFound -->|Yes| SetReady[lsnr_status= "READY"]
    ReadyFound -->|No| KeepUnknown
    CheckLsnrctl -->|No| KeepUnknown[Keep status= "unknown"]
    
    SetReady --> PrintListener
    KeepUnknown --> PrintListener[printf "%-17s : %-12s %-11s"<br/>"Listener" listener_name lsnr_status]
    
    PrintListener --> IncrementCount[listener_count++]
    IncrementCount --> ListenerLoop
    
    ListenerLoop -->|No| CheckLsnrCount{listener_count<br/>== 0?}
    CheckLsnrCount -->|Yes| ShowNoListeners[echo No database listeners running]
    CheckLsnrCount -->|No| CheckDataSafeOnly
    ShowNoListeners --> CheckDataSafeOnly
    
    CheckDataSafeOnly --> InitDSArray[datasafe_homes=]
    InitDSArray --> FilterDS[Loop other_homes<br/>Filter ptype=="datasafe"]
    FilterDS --> CheckDSCount{datasafe_homes<br/>count>0?}
    
    CheckDSCount -->|Yes| DSHeader[echo blank line<br/>echo Data Safe Status<br/>echo separators]
    DSHeader --> DSLoop[for ds_obj in datasafe_homes]
    DSLoop --> ExtractDSFields[Extract fields:<br/>name= get_field "name"<br/>home= get_field "home"]
    
    ExtractDSFields --> CheckDSPlugin{type -t<br/>plugin_check_status<br/>exists?}
    CheckDSPlugin -->|Yes| CallDSStatus[status= plugin_check_status home<br/>DataSafe plugin uses:<br/>ORACLE_HOME=cman_home<br/>cmctl status]
    CheckDSPlugin -->|No| SetDSUnknown[status= "unknown"]
    
    CallDSStatus --> PrintDS[printf "%-17s : %-12s %-11s %s"<br/>"Connector" name status home]
    SetDSUnknown --> PrintDS
    
    PrintDS --> NextDS{More<br/>datasafe?}
    NextDS -->|Yes| DSLoop
    NextDS -->|No| ShowFooter
    
    CheckDSCount -->|No| ShowFooter[echo blank line<br/>echo separators<br/>echo blank line]
    
    ShowFooter --> ReturnSuccess[Return 0]
    
    ReturnError --> End
    ReturnSuccess --> End([Complete])
    SetHelp --> Exit([Exit])
    ShowError --> ExitError([Exit 1])
    
    style Start fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style LoadCommon fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style LoadStatus fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style LoadRegistry fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style LoadPlugins fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    style MainFunc fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style CallShow fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    style CallGetAll fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style CallShowRegistry fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    
    style HomeLoop fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style CheckPluginType fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    style CallCheckStatus fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    
    style DBLoop fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style CallGetDBStatus fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style PSCheck fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style CallGetMode fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style QueryInstance fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    style FindListeners fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style ListenerLoop fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style RunLsnrctl fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    style DSLoop fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style CallDSStatus fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    
    style End fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style Exit fill:#e0e0e0,stroke:#616161,stroke-width:2px
    style ExitError fill:#ffcdd2,stroke:#c62828,stroke-width:2px
```
