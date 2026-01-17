```mermaid
flowchart TD
    Start([User: oraup.sh OPTIONS])
    
    Start --> ParseArgs[Parse Arguments<br/>--help, --verbose, --quiet]
    
    ParseArgs --> CheckHelp{--help<br/>flag?}
    CheckHelp -->|Yes| ShowHelp[Display usage<br/>Exit 0]
    CheckHelp -->|No| LoadLibs[Load Libraries:<br/>1. oradba_common.sh<br/>2. oradba_env_status.sh<br/>3. oradba_registry.sh<br/>4. All plugins/*.sh]
    
    LoadLibs --> GetOratab[get_oratab_path<br/>Locate oratab file]
    
    GetOratab --> ShowHeader[Display Header:<br/>Oracle Environment Status<br/>Column headers table]
    
    ShowHeader --> CheckRegistry{Registry API<br/>available?}
    
    CheckRegistry -->|No| ShowWarning[Display warning:<br/>Registry API unavailable<br/>Check installation]
    ShowWarning --> End
    
    CheckRegistry -->|Yes| GetAll[oradba_registry_get_all<br/>Unified registry query]
    
    GetAll --> CheckEmpty{Any<br/>installations<br/>found?}
    
    CheckEmpty -->|No| ShowEmpty[Display message:<br/>No Oracle installations<br/>Instructions to register]
    ShowEmpty --> End
    
    CheckEmpty -->|Yes| SeparateTypes[Separate by Type:<br/>- Databases array<br/>- Other Homes array]
    
    SeparateTypes --> CallRegistry[show_oracle_status_registry<br/>installations array]
    
    CallRegistry --> DisplayHomes{Other<br/>Homes exist?}
    
    DisplayHomes -->|Yes| LoopHomes[Loop through other_homes]
    LoopHomes --> ExtractHomeFields[Extract fields:<br/>- name<br/>- home path<br/>- product type]
    
    ExtractHomeFields --> LoadPlugin{Plugin<br/>available?}
    LoadPlugin -->|Yes| SourcePlugin[Source plugin file<br/>Load product functions]
    SourcePlugin --> CheckStatusFunc
    LoadPlugin -->|No| DefaultStatus[status = "available"]
    DefaultStatus --> CheckStatusFunc{plugin_check_status<br/>exists?}
    
    CheckStatusFunc -->|Yes| CallStatus[plugin_check_status home<br/>Get actual status]
    CallStatus --> MapType
    CheckStatusFunc -->|No| MapType[Map product type to display:<br/>datasafe → DataSafe Conn<br/>client → Client<br/>oud → OUD<br/>etc.]
    
    MapType --> PrintHome[printf formatted:<br/>TYPE : NAME STATUS PATH]
    
    PrintHome --> NextHome{More<br/>homes?}
    NextHome -->|Yes| LoopHomes
    NextHome -->|No| DisplayDBs
    
    DisplayHomes -->|No| DisplayDBs{Databases<br/>exist?}
    
    DisplayDBs -->|Yes| LoopDBs[Loop through databases]
    LoopDBs --> ExtractDBFields[Extract fields:<br/>- SID<br/>- home path<br/>- startup flags Y/N/D]
    
    ExtractDBFields --> GetDBStatus[get_db_status SID<br/>Check pmon process:<br/>- db_pmon_SID<br/>- ora_pmon_sid]
    
    GetDBStatus --> StatusCheck{Status<br/>== "up"?}
    StatusCheck -->|Yes| GetMode[get_db_mode SID home<br/>Query v$instance:<br/>OPEN/MOUNTED/STARTED]
    GetMode --> PrintDB
    StatusCheck -->|No| PrintDB[printf formatted:<br/>DB-instance flag : SID STATUS HOME]
    
    PrintDB --> NextDB{More<br/>databases?}
    NextDB -->|Yes| LoopDBs
    NextDB -->|No| CheckListeners
    
    DisplayDBs -->|No| CheckListeners{Any<br/>databases?}
    
    CheckListeners -->|Yes| ShowListenerHeader[Display Header:<br/>Listener Status]
    ShowListenerHeader --> FindListeners[ps -ef | grep tnslsnr<br/>Exclude datasafe/cman]
    
    FindListeners --> LoopListeners[Loop through listeners]
    LoopListeners --> ExtractLsnrName[Extract listener name<br/>from process]
    ExtractLsnrName --> GetLsnrStatus[lsnrctl status NAME<br/>Check if "ready"]
    GetLsnrStatus --> PrintListener[printf formatted:<br/>Listener : NAME STATUS]
    
    PrintListener --> NextListener{More<br/>listeners?}
    NextListener -->|Yes| LoopListeners
    NextListener -->|No| CheckDataSafe
    
    CheckListeners -->|No| CheckDataSafe{DataSafe<br/>connectors?}
    
    CheckDataSafe -->|Yes| ShowDSHeader[Display Header:<br/>Data Safe Status]
    ShowDSHeader --> LoopDataSafe[Loop through datasafe_homes]
    LoopDataSafe --> ExtractDSFields[Extract fields:<br/>- name<br/>- home path]
    ExtractDSFields --> CallDSPlugin[plugin_check_status home<br/>DataSafe plugin]
    CallDSPlugin --> PrintDS[printf formatted:<br/>Connector : NAME STATUS PATH]
    
    PrintDS --> NextDS{More<br/>connectors?}
    NextDS -->|Yes| LoopDataSafe
    NextDS -->|No| ShowFooter
    
    CheckDataSafe -->|No| ShowFooter[Display footer separator]
    
    ShowFooter --> End([Complete])
    
    ShowHelp --> Exit([Exit])
    
    style Start fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style LoadLibs fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style GetAll fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style SeparateTypes fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    style LoopHomes fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style LoadPlugin fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    style CallStatus fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    
    style LoopDBs fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style GetDBStatus fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style GetMode fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    style FindListeners fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style LoopListeners fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    style LoopDataSafe fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style CallDSPlugin fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    
    style End fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    style Exit fill:#e0e0e0,stroke:#616161,stroke-width:2px
```
