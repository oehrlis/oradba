# OraDBA System Architecture

Complete layered architecture showing Registry API, Plugin System, Environment Management Libraries, and Oracle integration.

```mermaid
graph TB
    subgraph Users["User Layer"]
        U1[DBA/Developer]
        U2[Automation Scripts]
        U3[CI/CD Pipelines]
    end
    
    subgraph CLI["Command-Line Interface"]
        C1[oraenv.sh<br/>Environment Wrapper]
        C2[oradba_env.sh<br/>Main Environment Builder]
        C3[oradba_homes.sh<br/>Oracle Homes Manager]
        C4[oraup.sh<br/>Status Display]
    end
    
    subgraph Registry["Registry API v0.19.0+"]
        R1[oradba_registry.sh<br/>Unified Installation Access]
        R2[Registry Functions:<br/>get_all, get_by_name<br/>get_by_type, get_databases]
    end
    
    subgraph Plugins["Plugin System v0.19.0+"]
        PL1[database_plugin.sh]
        PL2[datasafe_plugin.sh]
        PL3[client_plugin.sh]
        PL4[iclient_plugin.sh]
        PL5[oud_plugin.sh]
        PL6[java_plugin.sh]
    end
    
    subgraph EnvLibs["Environment Management Libraries"]
        E1[oradba_env_parser.sh<br/>Configuration Parser]
        E2[oradba_env_builder.sh<br/>Environment Builder]
        E3[oradba_env_validator.sh<br/>Validation Engine]
        E4[oradba_env_config.sh<br/>Config Manager]
        E5[oradba_env_status.sh<br/>Status Display]
        E6[oradba_env_changes.sh<br/>Change Detection]
    end
    
    subgraph Core["Core Libraries"]
        L1[oradba_common.sh<br/>Logging & Utilities]
        L2[oradba_db_functions.sh<br/>Database Operations]
        L3[oradba_aliases.sh<br/>Safe Alias Generation]
    end
    
    subgraph Config["Configuration System"]
        CF1[oradba_core.conf<br/>System Defaults]
        CF2[oradba_standard.conf<br/>Standard Settings]
        CF3[oradba_local.conf<br/>Auto-Detected]
        CF4[oradba_customer.conf<br/>Site-Specific]
        CF5[sid.*.conf<br/>Database-Specific]
        CF6[oradba_homes.conf<br/>Oracle Homes Registry]
    end
    
    subgraph Oracle["Oracle Database Layer"]
        O1[Oracle Homes<br/>RDBMS, Client, DataSafe, OUD, Java]
        O2[Oracle Instances<br/>CDB & PDBs]
        O3[Listeners]
        O4[oratab]
    end
    
    U1 --> C1
    U1 --> C4
    U2 --> CLI
    U3 --> CLI
    
    C1 --> C2
    C2 --> R1
    C3 --> R1
    C4 --> R1
    
    R1 --> R2
    R2 --> Plugins
    
    Plugins --> O1
    
    C2 --> EnvLibs
    EnvLibs --> Core
    
    E1 --> Config
    E2 --> Config
    E3 --> Plugins
    E5 --> Plugins
    
    Core --> Oracle
    
    CF6 --> O1
    O4 --> R1
    
    style Users fill:#E6E6FA
    style CLI fill:#87CEEB
    style Registry fill:#98FB98
    style Plugins fill:#FFD700
    style EnvLibs fill:#DDA0DD
    style Core fill:#90EE90
    style Config fill:#FFE4B5
    style Oracle fill:#FFB6C6
```

## Description

The OraDBA system architecture consists of:

1. **User Layer**: DBAs, automation scripts, CI/CD pipelines
2. **CLI Layer**: Main entry points (oraenv.sh, oradba_env.sh, oradba_homes.sh, oraup.sh)
3. **Registry API** (v0.19.0+): Unified interface for Oracle installation metadata
4. **Plugin System** (v0.19.0+): 6 product-specific plugins with 8-function interface
5. **Environment Management Libraries**: Parser, Builder, Validator, Config, Status, Changes
6. **Core Libraries**: Common utilities, database operations, alias management
7. **Configuration System**: 6-level hierarchical configuration
8. **Oracle Layer**: Integration with Oracle Homes, instances, listeners, oratab

## Key Components

- **Registry API**: Single source of truth for Oracle installations (oratab + oradba_homes.conf)
- **Plugin System**: Product-specific logic for database, datasafe, client, iclient, oud, java
- **Environment Libraries**: Modular, testable components for environment setup
- **Hierarchical Config**: 6 levels from core defaults to runtime overrides
