# Configuration Hierarchy

6-level configuration override system with library-based processing.

```mermaid
flowchart TB
    subgraph Processing["Processing Libraries"]
        P1[oradba_env_parser.sh<br/>Parse & Merge Configs]
        P2[oradba_env_builder.sh<br/>Build Environment]
        P3[oradba_env_validator.sh<br/>Validate Installation]
    end
    
    subgraph Level1["Level 1: Core Defaults"]
        L1[oradba_core.conf<br/>System Defaults<br/>Installation Paths<br/>VERSION, PREFIX]
    end
    
    subgraph Level2["Level 2: Standard Settings"]
        L2[oradba_standard.conf<br/>Standard Oracle Paths<br/>Common Patterns<br/>Default Aliases]
    end
    
    subgraph Level3["Level 3: Local Auto-Detection"]
        L3[oradba_local.conf<br/>Auto-Detected Settings<br/>Coexistence Mode<br/>Local Paths]
    end
    
    subgraph Level4["Level 4: Customer Overrides"]
        L4[oradba_customer.conf<br/>Site-Specific Settings<br/>RMAN Catalog<br/>Custom TNS_ADMIN]
    end
    
    subgraph Level5["Level 5: SID Configuration"]
        L5[sid.SID.conf<br/>Database-Specific<br/>Custom Aliases<br/>Specific Paths]
        L5D[sid._DEFAULT_.conf<br/>Template for New SIDs]
    end
    
    subgraph Level6["Level 6: Runtime"]
        L6[Environment Variables<br/>Command-Line Args<br/>Highest Priority]
    end
    
    subgraph Result["Final Environment"]
        R[Active Oracle Environment<br/>All Variables Resolved]
    end
    
    L1 -->|Priority 1<br/>Lowest| P1
    L2 -->|Priority 2| P1
    L3 -->|Priority 3| P1
    L4 -->|Priority 4| P1
    L5 -->|Priority 5| P1
    L5D -.->|Template| L5
    L6 -->|Priority 6<br/>Highest| P1
    
    P1 --> |Merged Config| P2
    P2 --> |Built Environment| P3
    P3 --> |Validated| R
    
    L1 -.->|Overridden by| L2
    L2 -.->|Overridden by| L3
    L3 -.->|Overridden by| L4
    L4 -.->|Overridden by| L5
    L5 -.->|Overridden by| L6
    
    style L1 fill:#FFE4B5
    style L2 fill:#F0E68C
    style L3 fill:#FFD700
    style L4 fill:#FFA500
    style L5 fill:#FF6347
    style L6 fill:#FF4500
    style R fill:#90EE90
    style P1 fill:#87CEEB
    style P2 fill:#90EE90
    style P3 fill:#DDA0DD
```

## Description

The configuration hierarchy provides flexible override system:

1. **Level 1 - Core**: System defaults, installation paths (read-only)
2. **Level 2 - Standard**: Standard Oracle paths and patterns
3. **Level 3 - Local**: Auto-detected settings, coexistence mode
4. **Level 4 - Customer**: Site-specific customizations (recommended)
5. **Level 5 - SID**: Database-specific settings (optional)
6. **Level 6 - Runtime**: Environment variables (highest priority)

## Processing Flow

1. **Parser** (oradba_env_parser.sh) reads all 6 levels in order
2. **Merge** combines configurations with later levels overriding earlier
3. **Builder** (oradba_env_builder.sh) constructs environment variables
4. **Validator** (oradba_env_validator.sh) verifies Oracle installation
5. **Result** is complete, validated Oracle environment

## Key Features

- **Flexible Overrides**: Each level can override previous levels
- **Auto-Detection**: Level 3 automatically detects local settings
- **SID Templates**: sid._DEFAULT_.conf provides template
- **Runtime Priority**: Environment variables always win
- **Library Processing**: Modular, testable components
