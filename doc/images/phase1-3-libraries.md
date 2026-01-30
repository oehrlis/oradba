# Environment Management Library Architecture

Modular library system for parsing, building, and validating Oracle environments.

```mermaid
graph TB
    subgraph Entry["Entry Points"]
        E1[oraenv.sh<br/>Wrapper]
        E2[oradba_env.sh<br/>Main Builder]
        E3[oradba_homes.sh<br/>Home Manager]
    end
    
    subgraph Registry["Registry API"]
        RE1[oradba_registry.sh<br/>Unified Installation Access]
        RE2[get_all / get_by_name<br/>get_by_type / get_databases]
    end
    
    subgraph Plugins["Plugin System"]
        PL1[Plugin Interface]
        PL2[6 Product Plugins:<br/>database, datasafe, client<br/>iclient, oud, java]
        PL3[8 Required Functions:<br/>detect, validate, adjust<br/>status, metadata, etc]
    end
    
    subgraph Parser["Parser Library"]
        P1[oradba_env_parser.sh]
        P1A[parse_config_file]
        P1B[merge_configs]
        P1C[resolve_variables]
    end
    
    subgraph Builder["Builder Library"]
        P2[oradba_env_builder.sh]
        P2A[build_oracle_env]
        P2B[derive_oracle_base]
        P2C[construct_path]
        P2D[set_tns_admin]
    end
    
    subgraph Validator["Validator Library"]
        P3A[oradba_env_validator.sh]
        P3A1[validate_oracle_home]
        P3A2[detect_product_type<br/>Uses Plugins]
        P3A3[detect_version]
    end
    
    subgraph ConfigMgr["Config Manager"]
        P3B[oradba_env_config.sh]
        P3B1[get_config_value]
        P3B2[set_config_value]
    end
    
    subgraph Status["Status Display"]
        P3C[oradba_env_status.sh]
        P3C1[show_environment]
        P3C2[show_config_sources]
        P3C3[check_db_status]
    end
    
    subgraph Changes["Change Tracker"]
        P3D[oradba_env_changes.sh]
        P3D1[track_changes]
        P3D2[show_diff]
        P3D3[auto_reload]
    end
    
    subgraph ConfigFiles["Configuration Files"]
        C1[oradba_core.conf<br/>System Defaults]
        C2[oradba_standard.conf<br/>Standard Settings]
        C3[oradba_local.conf<br/>Auto-Detected]
        C4[oradba_customer.conf<br/>Site-Specific]
        C5[sid.*.conf<br/>Database-Specific]
        C6[oradba_homes.conf<br/>Oracle Homes]
    end
    
    subgraph Common["Common Libraries"]
        L1[oradba_common.sh<br/>Logging & Utilities]
        L2[oradba_aliases.sh<br/>Safe Alias Generation]
    end
    
    E1 --> E2
    E2 --> RE1
    E3 --> RE1
    
    RE1 --> RE2
    RE2 --> Plugins
    
    E2 --> Parser
    
    Parser --> P1A
    Parser --> P1B
    Parser --> P1C
    
    ConfigFiles --> P1A
    P1C --> Builder
    
    Builder --> P2A
    Builder --> P2B
    Builder --> P2C
    Builder --> P2D
    
    Builder --> Validator
    Builder --> ConfigMgr
    Builder --> Status
    Builder --> Changes
    
    Validator --> P3A1
    Validator --> P3A2
    Validator --> P3A3
    
    P3A2 --> Plugins
    
    ConfigMgr --> P3B1
    ConfigMgr --> P3B2
    
    Status --> P3C1
    Status --> P3C2
    Status --> P3C3
    
    P3C3 --> Plugins
    
    Changes --> P3D1
    Changes --> P3D2
    Changes --> P3D3
    
    Parser --> L1
    Builder --> L1
    Validator --> L1
    Status --> L1
    
    E2 --> L2
    
    style Entry fill:#E6E6FA
    style Registry fill:#98FB98
    style Plugins fill:#FFD700
    style Parser fill:#87CEEB
    style Builder fill:#90EE90
    style Validator fill:#DDA0DD
    style ConfigMgr fill:#F0E68C
    style Status fill:#FFE4B5
    style Changes fill:#FFA07A
    style ConfigFiles fill:#FFE4B5
    style Common fill:#DDA0DD
```

## Description

The Environment Management Library architecture provides:

1. **Registry API**: Unified interface for Oracle installation metadata
2. **Plugin System**: Product-specific logic with 11-function interface
3. **Parser Library**: Loads and merges 6 configuration levels
4. **Builder Library**: Constructs Oracle environment variables
5. **Validator Library**: Checks Oracle Home validity using plugins
6. **Config Manager**: Runtime configuration access
7. **Status Display**: Environment summary with plugin integration
8. **Change Tracker**: Detects configuration changes and auto-reloads

## Key Features

- **Modular Design**: Each library has specific responsibility
- **Plugin Integration**: Uses plugins for product-specific operations
- **Registry API**: Single source of truth for installations
- **Hierarchical Config**: 6-level configuration with override
- **Testable**: Each library independently tested
- **Extensible**: Easy to add new product types via plugins
