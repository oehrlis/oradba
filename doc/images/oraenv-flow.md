# oraenv.sh Execution Flow

Complete environment setup process from user request to active environment.

```mermaid
flowchart TD
    A[User: source oraenv.sh SID] --> B[oraenv.sh Wrapper]
    
    B --> C{SID/Name<br/>Provided?}
    
    C -->|No| D[List Available<br/>SIDs/Homes]
    D --> E[User Selects]
    E --> F[Call oradba_env.sh]
    
    C -->|Yes| F
    
    F --> G[oradba_env.sh<br/>Main Builder]
    
    G --> H[Load Environment<br/>Management Libraries]
    
    H --> I[Parser: Load Configs]
    I --> J[Merge 6 Levels:<br/>1. core 2. standard<br/>3. local 4. customer<br/>5. SID 6. runtime]
    
    J --> K[Builder: Query Registry]
    
    K --> L{SID or<br/>Home Name?}
    
    L -->|SID| M[Query oratab]
    L -->|Home Name| N[Query oradba_homes.conf]
    
    M --> O[Get ORACLE_HOME]
    N --> O
    
    O --> P{Valid<br/>ORACLE_HOME?}
    
    P -->|No| Q[❌ Error:<br/>Invalid Home]
    
    P -->|Yes| R[Set Base Environment<br/>ORACLE_SID, ORACLE_HOME<br/>Auto-derive ORACLE_BASE]
    
    R --> S[Validator: Check Installation]
    
    S --> T[Plugin System:<br/>Detect Type & Version<br/>Validate Home]
    
    T --> U{Validation<br/>Pass?}
    
    U -->|No| V[❌ Error:<br/>Validation Failed]
    
    U -->|Yes| W[Builder: Construct Environment<br/>PATH, LD_LIBRARY_PATH<br/>TNS_ADMIN, SQLPATH]
    
    W --> X[Alias Generator:<br/>Generate Shortcuts]
    
    X --> Y{CDB<br/>Database?}
    
    Y -->|Yes| Z[Detect & Create<br/>PDB Aliases]
    Y -->|No| AA[Skip PDB Aliases]
    
    Z --> AB[Generate Aliases]
    AA --> AB
    
    AB --> AC[Status Display:<br/>Show Environment Summary]
    
    AC --> AD[✅ Environment Ready]
    
    style AD fill:#90EE90
    style Q fill:#FFB6C6
    style V fill:#FFB6C6
    style I fill:#87CEEB
    style K fill:#FFD700
    style S fill:#DDA0DD
    style T fill:#FFD700
```

## Description

The oraenv.sh execution flow shows:

1. **User Input**: SID or Oracle Home name
2. **Wrapper**: oraenv.sh validates input
3. **Main Builder**: oradba_env.sh coordinates process
4. **Parser**: Loads and merges 6 configuration levels
5. **Registry API**: Queries oratab or oradba_homes.conf
6. **Plugin System**: Validates installation and detects type
7. **Builder**: Constructs complete environment
8. **Aliases**: Generates database and PDB shortcuts
9. **Status**: Displays environment summary

## Key Features

- Interactive or non-interactive mode
- Registry API provides unified installation access
- Plugin system handles product-specific logic
- Automatic ORACLE_BASE derivation
- PDB alias generation for multitenant databases
- Comprehensive validation before activation
