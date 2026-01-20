# Registry API Data Flow

This diagram shows how the Registry API (v0.19.0+) provides unified access to Oracle installation metadata from both oratab and oradba_homes.conf, with integrated plugin system for product type detection.

```mermaid
flowchart TD
    Start([User Request:<br/>SID or Oracle Home name])
    
    Start --> RegistryAPI[Registry API<br/>oradba_registry.sh]
    
    RegistryAPI --> QueryType{Query<br/>Type?}
    
    QueryType -->|get_all| GetAll[Get All Installations]
    QueryType -->|get_by_name| GetByName[Get Specific Installation]
    QueryType -->|get_by_type| GetByType[Get by Product Type]
    QueryType -->|get_databases| GetDB[Get Databases Only]
    
    GetAll --> ReadSources
    GetByName --> ReadSources
    GetByType --> ReadSources
    GetDB --> ReadOratab
    
    ReadSources[Read Installation Sources]
    
    ReadSources --> AutoSync{Auto-sync<br/>enabled?}
    AutoSync -->|Yes| SyncOratab[oradba_registry_sync_oratab<br/>Sync databases from oratab]
    SyncOratab --> ReadBoth
    AutoSync -->|No| ReadBoth
    
    ReadBoth[Read Both Sources] --> ReadOratab[Read oratab<br/>/etc/oratab]
    ReadBoth --> ReadHomes[Read Oracle Homes Registry<br/>oradba_homes.conf]
    
    ReadOratab --> OratexistabData[Database Entries:<br/>FREE:path:N<br/>ORCLCDB:path:Y]
    ReadHomes --> HomesData[Oracle Home Entries:<br/>client19:path:client:...<br/>dsconn:path:datasafe:...<br/>jdk17:path:java:...]
    
    OratexistabData --> DetectDB{Detect<br/>Product<br/>Type}
    HomesData --> DetectOther{Use<br/>Configured<br/>Type}
    
    DetectDB -->|Use plugin| DBPlugin[database_plugin.sh<br/>plugin_validate_home]
    DetectDB -->|Fallback| DefaultDB[type=database]
    
    DetectOther --> TypeCheck{Type<br/>Valid?}
    TypeCheck -->|datasafe| DSPlugin[datasafe_plugin.sh]
    TypeCheck -->|client| ClientPlugin[client_plugin.sh]
    TypeCheck -->|iclient| IClientPlugin[iclient_plugin.sh]
    TypeCheck -->|oud| OUDPlugin[oud_plugin.sh]
    TypeCheck -->|java| JavaPlugin[java_plugin.sh]
    TypeCheck -->|database| DBPlugin
    
    DBPlugin --> Validate
    DSPlugin --> Validate
    ClientPlugin --> Validate
    IClientPlugin --> Validate
    OUDPlugin --> Validate
    JavaPlugin --> Validate
    DefaultDB --> Validate
    
    Validate[Plugin Validation<br/>plugin_validate_home]
    
    Validate --> FormatEntry[Format Registry Entry<br/>type:name:home:version:flags:order:alias:desc]
    
    FormatEntry --> Examples[Example Entries:<br/>database:FREE:path:23.0:N:1::Oracle 23ai<br/>client:client19:path:19.0::2:c19:Oracle Client<br/>datasafe:dsconn:path:N/A::3::Data Safe<br/>iclient:ic21:path:21.13::4::Instant Client<br/>oud:oud12c:path:12.2::5::OUD 12c<br/>java:jdk17:path:17.0::6::Java 17]
    
    Examples --> Return[Return Formatted Data<br/>Colon-delimited]
    
    Return --> UsedBy{Used By}
    
    UsedBy -->|oraenv.sh| Oraenv[Environment Setup<br/>Source SID/Home]
    UsedBy -->|oradba_env.sh| OradbaEnv[show/status/validate<br/>commands]
    UsedBy -->|oradba_homes.sh| OradbaHomes[Oracle Homes<br/>Management]
    UsedBy -->|oraup.sh| Oraup[Status Display<br/>All installations]
    
    Oraenv --> EndUse
    OradbaEnv --> EndUse
    OradbaHomes --> EndUse
    Oraup --> EndUse
    
    EndUse([Unified Oracle<br/>Installation Data])
    
    style Start fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style RegistryAPI fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    style ReadOratab fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style ReadHomes fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style SyncOratab fill:#ce93d8,stroke:#6a1b9a,stroke-width:2px
    
    style DBPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style DSPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style ClientPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style IClientPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style OUDPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style JavaPlugin fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    style FormatEntry fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style Examples fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    style Oraenv fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style OradbaEnv fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style OradbaHomes fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style Oraup fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    
    style EndUse fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
```
