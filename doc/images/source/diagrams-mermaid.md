# OraDBA Mermaid Diagrams

This file contains Mermaid diagram definitions that can be imported into Excalidraw or rendered directly in markdown viewers.

## 1. CI/CD Pipeline

Shows the GitHub Actions workflows with smart test selection for CI and full test suite for releases.

```mermaid
flowchart TD
    A[Developer Push/PR] --> B{Event Type}
    
    B -->|Push to main/develop| C[CI Workflow]
    B -->|Tag v*.*.*| D[Release Workflow]
    
    C --> C1[Detect Changed Files]
    C1 --> C2[git diff origin/main]
    C2 --> C3[Run Linting]
    C3 --> C4{Changes Detected?}
    
    C4 -->|Yes| C5[Smart Test Selection]
    C4 -->|No| C6[Run Always-Run Tests]
    
    C5 --> C7[./scripts/select_tests.sh]
    C7 --> C8[Consult .testmap.yml]
    C8 --> C9[Select 5-50 Tests]
    
    C6 --> C10[3 Core Tests]
    
    C9 --> C11[Run Selected Tests]
    C10 --> C11
    
    C11 --> C12{Tests Pass?}
    C12 -->|Yes| C13[Build Artifacts]
    C12 -->|No| C14[❌ CI Failed]
    
    C13 --> C15[✅ CI Success 1-3 min]
    
    D --> D1[Verify CI Passed]
    D1 --> D2{CI Status}
    D2 -->|Failed| D3[❌ Release Blocked]
    D2 -->|Passed| D4[Run All Linters]
    
    D4 --> D5[Full Test Suite]
    D5 --> D6[Run ALL 492 Tests]
    D6 --> D7{Tests Pass?}
    
    D7 -->|No| D8[❌ Release Failed]
    D7 -->|Yes| D9[Build Installer]
    
    D9 --> D10[Generate Documentation]
    D10 --> D11[Create GitHub Release]
    D11 --> D12[Upload Artifacts]
    D12 --> D13[✅ Release Complete 8-10 min]
    
    style C15 fill:#90EE90
    style D13 fill:#90EE90
    style C14 fill:#FFB6C6
    style D3 fill:#FFB6C6
    style D8 fill:#FFB6C6
    style C5 fill:#87CEEB
    style D5 fill:#FFD700
```

## 2. Test Strategy

Shows the smart test selection architecture with configuration-driven test mapping.

```mermaid
flowchart TB
    subgraph Input["Input Detection"]
        A[Developer Makes Changes] --> B[git diff origin/main]
        B --> C[Changed Files List]
    end
    
    subgraph Config["Configuration"]
        D[.testmap.yml]
        D --> E[always_run 3 core tests]
        D --> F[mappings explicit source→test]
        D --> G[patterns regex matching]
    end
    
    subgraph Selection["Test Selection Logic"]
        C --> H[./scripts/select_tests.sh]
        E --> H
        F --> H
        G --> H
        
        H --> I{Parse Changed Files}
        I --> J[Always-Run Tests]
        I --> K[Match Explicit Mappings]
        I --> L[Match Pattern Rules]
        
        J --> M[Combine Unique Tests]
        K --> M
        L --> M
        
        M --> N{Any Tests Found?}
        N -->|Yes| O[Selected Tests 5-50 files]
        N -->|No| P[Fallback: All Tests 492 files]
    end
    
    subgraph Execution["Test Execution"]
        O --> Q[bats test files]
        P --> Q
        Q --> R[Run Tests in Parallel]
        R --> S{All Pass?}
        S -->|Yes| T[✅ Success]
        S -->|No| U[❌ Failure]
    end
    
    subgraph Examples["Example Mappings"]
        V[src/lib/common.sh affects 6 tests]
        W[src/bin/oradba_dbctl.sh → test_service_management.bats]
        X[*.md files → no tests needed]
    end
    
    style T fill:#90EE90
    style U fill:#FFB6C6
    style O fill:#87CEEB
    style P fill:#FFD700
    style D fill:#E6E6FA
```

## 3. Development Workflow

Shows the developer's decision tree with smart test selection for fast iteration.

```mermaid
flowchart TD
    A[Developer Makes Changes] --> B{What Changed?}
    
    B -->|Source Code| C[Edit .sh/.sql files]
    B -->|Documentation| D[Edit .md files]
    B -->|Tests| E[Edit .bats files]
    B -->|Config| F[Edit .conf/.yml files]
    
    C --> G{Need Preview?}
    D --> G
    E --> G
    F --> G
    
    G -->|Yes| H[make test DRY_RUN=1]
    H --> I[Shows Selected Tests No Execution]
    I --> J{Looks Good?}
    
    J -->|No| K[Update .testmap.yml]
    K --> G
    
    J -->|Yes| L[Run Tests]
    G -->|No| L
    
    L --> M{Which Tests?}
    
    M -->|Fast Feedback| N[make test]
    M -->|Comprehensive| O[make test-full]
    M -->|Pre-Commit| P[make pre-commit]
    
    N --> N1[Smart Selection 5-50 tests 1-3 min]
    O --> O1[All 492 Tests 8-10 min]
    P --> P1[Smart Tests + Lint 2-4 min]
    
    N1 --> Q{Tests Pass?}
    O1 --> Q
    P1 --> Q
    
    Q -->|No| R[❌ Fix Issues]
    R --> A
    
    Q -->|Yes| S{Ready to Commit?}
    
    S -->|Not Sure| T[Run Full Suite]
    T --> O
    
    S -->|Yes| U[git add & commit]
    U --> V[git push]
    
    V --> W[GitHub CI Triggers]
    W --> X[Smart Selection on CI]
    X --> Y{CI Pass?}
    
    Y -->|No| Z[❌ Review Failures]
    Z --> A
    
    Y -->|Yes| AA[✅ Merge to main]
    
    AA --> AB{Creating Release?}
    AB -->|No| AC[Done]
    AB -->|Yes| AD[Tag vX.Y.Z]
    AD --> AE[Release Workflow]
    AE --> AF[Full Test Suite All 492 Tests]
    AF --> AG{Pass?}
    AG -->|No| AH[❌ Release Blocked]
    AG -->|Yes| AI[✅ Build & Release]
    
    style N1 fill:#87CEEB
    style O1 fill:#FFD700
    style P1 fill:#DDA0DD
    style AA fill:#90EE90
    style AI fill:#90EE90
    style R fill:#FFB6C6
    style Z fill:#FFB6C6
    style AH fill:#FFB6C6
```

## 4. Performance Comparison

Visual representation of time savings with smart test selection.

```mermaid
gantt
    title Test Execution Time Comparison
    dateFormat X
    axisFormat %s
    
    section Full Suite
    All 492 Tests (8 min)    :done, full1, 0, 480
    
    section Smart Selection
    Typical Change (1 min)   :done, smart1, 0, 60
    Library Change (2 min)   :done, smart2, 0, 120
    Doc Only (30 sec)        :done, smart3, 0, 30
    
    section Time Saved
    7 minutes saved          :crit, save1, 60, 420
```

## 5. Test Selection Decision Tree

Simplified view of how tests are selected.

```mermaid
flowchart LR
    A[Changed File] --> B{File Type?}
    
    B -->|Core Script oraenv.sh| C[Always Run]
    B -->|Library common.sh| D[Multiple Tests]
    B -->|Feature dbctl.sh| E[Specific Test]
    B -->|Documentation *.md| F[No Tests]
    B -->|Test File *.bats| G[Run Self]
    
    C --> H[3 Core Tests]
    D --> I[6 Affected Tests]
    E --> J[1 Feature Test]
    F --> K[0 Tests]
    G --> L[1 Test File]
    
    H --> M[Final Set]
    I --> M
    J --> M
    K --> M
    L --> M
    
    M --> N[Deduplicate & Sort]
    N --> O[Execute Selected Tests]
    
    style C fill:#FFD700
    style D fill:#87CEEB
    style E fill:#90EE90
    style F fill:#FFB6C6
```

## Usage Notes

### Importing to Excalidraw

1. Copy the Mermaid code block for your desired diagram
2. In Excalidraw, use "Insert" → "Mermaid to Excalidraw"
3. Paste the Mermaid code
4. Adjust styling, colors, and layout as needed
5. Export as PNG to `doc/images/`

### Rendering in GitHub

These diagrams will render automatically in GitHub markdown viewers.

### Updating Diagrams

When the smart test selection logic changes:

1. Update the relevant Mermaid diagram here
2. Regenerate the Excalidraw version
3. Export new PNG files
4. Commit all three formats (Mermaid, .excalidraw, .png)

## 6. Architecture System

Shows the OraDBA system architecture with its layered components.

```mermaid
flowchart TB
    subgraph Users["User Layer"]
        U1[DBA/Developer]
        U2[Automation Scripts]
        U3[CI/CD Pipelines]
    end
    
    subgraph CLI["Command-Line Interface"]
        C1[oraenv.sh Environment Setup]
        C2[dbstatus.sh Status Display]
        C3[50+ Shell Aliases sq, cdh, taa, etc.]
        C4[Service Management orastart, dbctl, etc.]
    end
    
    subgraph Core["Core Libraries"]
        L1[common.sh Logging, Validation]
        L2[db_functions.sh DB Operations]
        L3[aliases.sh Alias Generation]
    end
    
    subgraph Config["Configuration System"]
        CF1[System Defaults oradba_core.conf]
        CF2[Standard Settings oradba_standard.conf]
        CF3[Customer Overrides oradba_customer.conf]
        CF4[SID Configs sid.*.conf]
        CF5[Environment Variables]
    end
    
    subgraph Scripts["Script Collections"]
        S1[SQL Scripts sql/]
        S2[RMAN Scripts rcv/]
        S3[Monitoring Long ops, Jobs]
    end
    
    subgraph Oracle["Oracle Database Layer"]
        O1[Oracle Homes]
        O2[Oracle Instances]
        O3[Listeners]
        O4[Oratab]
    end
    
    U1 --> C1
    U1 --> C2
    U1 --> C3
    U1 --> C4
    U2 --> CLI
    U3 --> CLI
    
    C1 --> L1
    C2 --> L1
    C2 --> L2
    C3 --> L3
    C4 --> L2
    
    L1 --> Config
    L2 --> Config
    L3 --> Config
    
    CF1 -.->|Override| CF2
    CF2 -.->|Override| CF3
    CF3 -.->|Override| CF4
    CF4 -.->|Override| CF5
    
    C1 --> S1
    C1 --> S2
    C1 --> S3
    
    CLI --> O4
    Core --> O1
    Core --> O2
    Core --> O3
    Scripts --> O2
    
    style Users fill:#E6E6FA
    style CLI fill:#87CEEB
    style Core fill:#90EE90
    style Config fill:#FFE4B5
    style Scripts fill:#DDA0DD
    style Oracle fill:#FFB6C6
```

## 7. oraenv.sh Execution Flow

Shows the complete environment setup process.

```mermaid
flowchart TD
    A[User: source oraenv.sh SID] --> B{SID Provided?}
    
    B -->|No| C[List Available SIDs]
    C --> D[User Selects SID]
    D --> E[Validate SID]
    
    B -->|Yes| E
    
    E --> F{SID in Oratab?}
    F -->|No| G[❌ Error: SID not found]
    F -->|Yes| H[Parse Oratab Entry]
    
    H --> I[Extract ORACLE_HOME]
    I --> J{ORACLE_HOME Exists?}
    J -->|No| K[❌ Error: Invalid ORACLE_HOME]
    J -->|Yes| L[Set ORACLE_SID]
    
    L --> M[Set ORACLE_HOME]
    M --> N[Calculate ORACLE_BASE]
    N --> O[Load Configuration Files]
    
    O --> P[Load oradba_core.conf]
    P --> Q[Load oradba_standard.conf]
    Q --> R[Load oradba_customer.conf]
    R --> S{SID Config Exists?}
    S -->|Yes| T[Load sid.SID.conf]
    S -->|No| U[Skip SID config]
    
    T --> V[Update PATH]
    U --> V
    
    V --> W[Update LD_LIBRARY_PATH]
    W --> X[Set TNS_ADMIN]
    X --> Y[Set NLS Variables]
    Y --> Z[Export ORACLE_ Variables]
    
    Z --> AA{CDB Database?}
    AA -->|Yes| AB[Generate PDB Aliases]
    AA -->|No| AC[Skip PDB Aliases]
    
    AB --> AD[Generate Standard Aliases]
    AC --> AD
    
    AD --> AE[Source aliases.sh]
    AE --> AF[Display Environment Info]
    AF --> AG[✅ Environment Ready]
    
    style AG fill:#90EE90
    style G fill:#FFB6C6
    style K fill:#FFB6C6
    style AB fill:#87CEEB
```

## 8. Configuration Hierarchy

Shows the 5-level configuration override system.

```mermaid
flowchart TB
    subgraph Level1["Level 1: System Defaults"]
        L1[oradba_core.conf Hardcoded defaults PREFIX, VERSION, etc.]
    end
    
    subgraph Level2["Level 2: Standard Settings"]
        L2[oradba_standard.conf Standard paths ORACLE_BASE patterns]
    end
    
    subgraph Level3["Level 3: Customer Overrides"]
        L3[oradba_customer.conf Site-specific RMAN catalog, TNS_ADMIN]
    end
    
    subgraph Level4["Level 4: SID Configuration"]
        L4[sid.SID.conf Database-specific Custom aliases, paths]
    end
    
    subgraph Level5["Level 5: Runtime"]
        L5[Environment Variables Command-line Args Highest priority]
    end
    
    subgraph Result["Final Configuration"]
        R[Active Environment All variables resolved]
    end
    
    L1 -->|Lowest Priority| L2
    L2 --> L3
    L3 --> L4
    L4 -->|Highest Priority| L5
    L5 --> R
    
    L1 -.->|Can be overridden by| L2
    L2 -.->|Can be overridden by| L3
    L3 -.->|Can be overridden by| L4
    L4 -.->|Can be overridden by| L5
    
    style L1 fill:#FFE4B5
    style L2 fill:#F0E68C
    style L3 fill:#FFD700
    style L4 fill:#FFA500
    style L5 fill:#FF6347
    style R fill:#90EE90
```

## 9. Configuration Loading Sequence

Shows the complete configuration loading and environment setup sequence.

```mermaid
sequenceDiagram
    participant User
    participant oraenv.sh
    participant Oratab
    participant Config as Config Files
    participant Aliases as aliases.sh
    participant Oracle as Oracle Env
    
    User->>oraenv.sh: source oraenv.sh FREE
    oraenv.sh->>oraenv.sh: Validate arguments
    
    oraenv.sh->>Oratab: Parse oratab
    Oratab-->>oraenv.sh: Return ORACLE_HOME path
    
    oraenv.sh->>oraenv.sh: Validate ORACLE_HOME exists
    
    oraenv.sh->>Config: Load oradba_core.conf
    Config-->>oraenv.sh: System defaults
    
    oraenv.sh->>Config: Load oradba_standard.conf
    Config-->>oraenv.sh: Standard settings
    
    oraenv.sh->>Config: Load oradba_customer.conf
    Config-->>oraenv.sh: Customer overrides
    
    oraenv.sh->>Config: Load sid.FREE.conf
    Config-->>oraenv.sh: SID-specific config
    
    oraenv.sh->>Oracle: Export ORACLE_SID=FREE
    oraenv.sh->>Oracle: Export ORACLE_HOME
    oraenv.sh->>Oracle: Export ORACLE_BASE
    oraenv.sh->>Oracle: Update PATH
    oraenv.sh->>Oracle: Update LD_LIBRARY_PATH
    oraenv.sh->>Oracle: Set TNS_ADMIN
    oraenv.sh->>Oracle: Set NLS_LANG
    
    oraenv.sh->>Aliases: Check if CDB
    Aliases-->>oraenv.sh: CDB=true
    
    oraenv.sh->>Aliases: Generate PDB aliases
    Aliases-->>oraenv.sh: PDB shortcuts created
    
    oraenv.sh->>Aliases: Generate standard aliases
    Aliases-->>oraenv.sh: 50+ aliases loaded
    
    oraenv.sh->>User: Display environment info
    oraenv.sh-->>User: ✅ Environment ready
```

## 10. Installation Flow

Shows the self-extracting installer process.

```mermaid
flowchart TD
    A[User Downloads oradba_install.sh] --> B[Execute Installer]
    
    B --> C{Installation Mode?}
    
    C -->|Default| D[Embedded Payload Mode]
    C -->|--local FILE| E[Local Tarball Mode]
    C -->|--github| F[GitHub Download Mode]
    
    D --> G[Extract base64 Payload from installer script]
    E --> H[Read local tarball file]
    F --> I[Download from GitHub releases]
    
    G --> J[Decode base64]
    H --> J
    I --> J
    
    J --> K[Verify Tarball Integrity]
    K --> L{Valid Checksum?}
    
    L -->|No| M[❌ Installation Failed]
    L -->|Yes| N{Update Mode?}
    
    N -->|Yes| O[Check Installed Version]
    O --> P{Version Newer?}
    P -->|No| Q[❌ No update needed]
    P -->|Yes| R[Backup Existing Install]
    
    N -->|No| S{Prefix Exists?}
    S -->|Yes| T[❌ Already Installed]
    S -->|No| U[Create Directories]
    
    R --> V[Preserve Config Files]
    V --> W[Remove Old Installation]
    W --> U
    
    U --> X[Extract Tarball]
    X --> Y[Create bin/ structure]
    Y --> Z[Create lib/ structure]
    Z --> AA[Create etc/ structure]
    AA --> AB[Create sql/ structure]
    AB --> AC[Create rcv/ structure]
    
    AC --> AD[Set Permissions]
    AD --> AE{--user Specified?}
    
    AE -->|Yes| AF[chown to user:group]
    AE -->|No| AG[Keep current ownership]
    
    AF --> AH[Run Integrity Check]
    AG --> AH
    
    AH --> AI{Verification Pass?}
    AI -->|No| AJ[Rollback to Backup]
    AJ --> AK[❌ Installation Failed]
    
    AI -->|Yes| AL[Create .install_info]
    AL --> AM[Generate Uninstall Script]
    AM --> AN[Display Success Message]
    AN --> AO[✅ Installation Complete]
    
    style AO fill:#90EE90
    style M fill:#FFB6C6
    style Q fill:#FFB6C6
    style T fill:#FFB6C6
    style AK fill:#FFB6C6
    style R fill:#FFD700
```

## 11. Alias Generation Flow

Shows how shell aliases are dynamically generated based on database type.

```mermaid
flowchart TD
    A[oraenv.sh Sourced] --> B[Environment Variables Set]
    B --> C[Source lib/aliases.sh]
    
    C --> D[Load Standard Aliases]
    D --> E[Generate SQL*Plus Aliases sq, sqh, sqlplush]
    E --> F[Generate RMAN Aliases rmanc, rmanh, rmanch]
    F --> G[Generate Navigation Aliases cdh, cdo, cdn, cda]
    G --> H[Generate Diagnostic Aliases taa, tah, tal, tac]
    H --> I[Generate File Edit Aliases via, vio, vit, vip]
    I --> J[Generate DB Operations dbstart, dbstop, lsnrstart]
    
    J --> K{Is CDB?}
    
    K -->|No| L[Skip PDB Aliases]
    K -->|Yes| M[Query PDBs from Database]
    
    M --> N{Database Running?}
    N -->|No| O[Use Cached PDB List]
    N -->|Yes| P[SELECT name FROM v$pdbs]
    
    P --> Q[Extract PDB Names]
    O --> Q
    
    Q --> R{PDBs Found?}
    R -->|No| L
    R -->|Yes| S[Generate PDB Aliases]
    
    S --> T[For Each PDB]
    T --> U[Create <pdbname> Alias]
    U --> V[sqlplus sys@PDB as sysdba]
    V --> W[Create <pdbname>h Alias]
    W --> X[rlwrap sqlplus sys@PDB]
    X --> Y[Create cd<pdbname> Alias]
    Y --> Z[cd $ORACLE_BASE/.../PDB]
    
    Z --> AA{More PDBs?}
    AA -->|Yes| T
    AA -->|No| AB[Store PDB List Cache]
    
    L --> AC[Export All Aliases]
    AB --> AC
    
    AC --> AD[Display Alias Summary]
    AD --> AE[✅ Aliases Ready]
    
    style AE fill:#90EE90
    style M fill:#87CEEB
    style S fill:#DDA0DD
```

## Diagram Sources

- **CI/CD Pipeline**: Shows GitHub Actions workflows with smart vs full test selection
- **Test Strategy**: Architecture of smart test selection system with .testmap.yml
- **Development Workflow**: Developer decision tree for testing and releasing
- **Performance Comparison**: Visual time savings comparison
- **Test Selection Decision**: Simplified logic for test selection
- **Architecture System**: OraDBA layered system architecture
- **oraenv.sh Flow**: Complete environment setup process
- **Configuration Hierarchy**: 5-level configuration override system
- **Configuration Sequence**: Sequence diagram of config loading
- **Installation Flow**: Self-extracting installer process
- **Alias Generation**: Dynamic alias generation with PDB support
