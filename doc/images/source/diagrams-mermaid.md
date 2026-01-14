# OraDBA Mermaid Diagrams

This file contains Mermaid diagram definitions that can be imported into Excalidraw or rendered directly in markdown viewers.

## 1. CI/CD Pipeline

Shows the GitHub Actions workflows with smart test selection for CI, full test suite for releases, and documentation deployment.

```mermaid
flowchart TD
    A[Developer Push/PR] --> B{Event Type}
    
    B -->|Push to main/develop| C[CI Workflow]
    B -->|Tag v*.*.*| D[Release Workflow]
    B -->|Push to main VERSION/docs| E[Docs Workflow]
    
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
    
    E --> E1{Triggered By?}
    E1 -->|VERSION change| E2[Release Documentation]
    E1 -->|Doc files change| E3[Updated Documentation]
    E2 --> E4[Build with MkDocs]
    E3 --> E4
    E4 --> E5[Deploy to GitHub Pages]
    E5 --> E6[✅ Docs Live 2-3 min]
    
    style C15 fill:#90EE90
    style D13 fill:#90EE90
    style E6 fill:#90EE90
    style C14 fill:#FFB6C6
    style D3 fill:#FFB6C6
    style D8 fill:#FFB6C6
    style C5 fill:#87CEEB
    style D5 fill:#FFD700
    style E4 fill:#DDA0DD
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
        C1[oraenv.sh Environment Wrapper]
        C2[oradba_env.sh Main Environment Builder]
        C3[oradba_homes.sh Oracle Homes Manager]
        C4[dbstatus.sh Status Display]
        C5[50+ Shell Aliases sq, cdh, taa, etc.]
        C6[Service Management orastart, dbctl, etc.]
    end
    
    subgraph Core["Core Libraries"]
        L1[common.sh oradba_log, Validation, Utilities]
        L2[db_functions.sh DB Operations]
        L3[aliases.sh Safe Alias Generation]
    end
    
    subgraph Phase1_3["Phase 1-3 Libraries"]
        P1[oradba_env_parser.sh Config File Parser]
        P2[oradba_env_builder.sh Environment Builder]
        P3[oradba_env_validator.sh Validation Engine]
        P4[oradba_env_config.sh Config Manager]
        P5[oradba_env_status.sh Status Display]
        P6[oradba_env_changes.sh Change Detection]
    end
    
    subgraph Config["Configuration System Phase 1-4"]
        CF1[Core: oradba_core.conf]
        CF2[Standard: oradba_standard.conf]
        CF3[Local: oradba_local.conf Auto-Generated]
        CF4[Customer: oradba_customer.conf Site-Specific]
        CF5[SID: sid.*.conf Database-Specific]
        CF6[Defaults: sid._DEFAULT_.conf]
        CF7[Oracle Homes: oradba_homes.conf]
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
    U1 --> C4
    U1 --> C5
    U1 --> C6
    U2 --> CLI
    U3 --> CLI
    
    C1 --> C2
    C2 --> Phase1_3
    C3 --> Phase1_3
    C4 --> L1
    C4 --> L2
    C5 --> L3
    C6 --> L2
    
    Phase1_3 --> Config
    L1 --> Config
    L2 --> Config
    L3 --> Config
    
    CF1 -.->|Override| CF2
    CF2 -.->|Override| CF3
    CF3 -.->|Override| CF4
    CF4 -.->|Override| CF5
    CF5 -.->|Uses| CF6
    CF7 -.->|Manages| O1
    
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
    A[User: source oraenv.sh SID] --> B[oraenv.sh Wrapper Script]
    
    B --> C{SID Provided?}
    
    C -->|No| D[List Available SIDs/Homes]
    D --> E[User Selects SID/Home]
    E --> F[Call oradba_env.sh]
    
    C -->|Yes| F
    
    F --> G[oradba_env.sh Main Builder]
    G --> H[Load Phase 1-3 Libraries]
    
    H --> I[oradba_env_parser.sh]
    I --> J[Parse Configuration Files:<br/>1. oradba_core.conf<br/>2. oradba_standard.conf<br/>3. oradba_local.conf<br/>4. oradba_customer.conf<br/>5. sid.SID.conf sid._DEFAULT_.conf]
    
    J --> K[oradba_env_builder.sh]
    K --> L{SID or Oracle Home?}
    
    L -->|SID| M[Query oratab for ORACLE_HOME]
    L -->|Home Name| N[Query oradba_homes.conf]
    
    M --> O[Resolve ORACLE_HOME path]
    N --> O
    
    O --> P{ORACLE_HOME Valid?}
    P -->|No| Q[❌ Error: Invalid ORACLE_HOME]
    P -->|Yes| R[Set Base Environment:<br/>ORACLE_SID, ORACLE_HOME<br/>ORACLE_BASE auto-derived]
    
    R --> S[oradba_env_validator.sh]
    S --> T[Validate Configuration:<br/>- Check ORACLE_HOME exists<br/>- Verify binaries present<br/>- Detect product type<br/>- Detect version]
    
    T --> U{Validation Pass?}
    U -->|No| V[❌ Error: Validation failed]
    U -->|Yes| W[Build Environment:<br/>PATH, LD_LIBRARY_PATH<br/>TNS_ADMIN, NLS_LANG<br/>SQLPATH, ORACLE_DOC_PATH]
    
    W --> X{Coexistence Mode?}
    X -->|Yes BasEnv| Y[Enable safe_alias mode]
    X -->|No| Z[Standard alias mode]
    
    Y --> AA[Generate Aliases]
    Z --> AA
    
    AA --> AB{CDB Database?}
    AB -->|Yes| AC[Detect PDBs]
    AB -->|No| AD[Skip PDB aliases]
    
    AC --> AE[Generate PDB Aliases]
    AE --> AF[Generate Standard Aliases]
    AD --> AF
    
    AF --> AG[Source aliases.sh]
    AG --> AH[oradba_env_status.sh]
    AH --> AI[Display Environment Summary:<br/>- ORACLE_SID / Home<br/>- Version & Product Type<br/>- Key Paths<br/>- Loaded Configs]
    
    AI --> AJ[✅ Environment Ready]
    
    style AJ fill:#90EE90
    style Q fill:#FFB6C6
    style V fill:#FFB6C6
    style I fill:#87CEEB
    style K fill:#FFD700
    style S fill:#DDA0DD
```

## 8. Configuration Hierarchy

Shows the 5-level configuration override system.

```mermaid
flowchart TB
    subgraph Processing["Phase 1-3 Processing"]
        P1[Parser: oradba_env_parser.sh]
        P2[Builder: oradba_env_builder.sh]
        P3[Validator: oradba_env_validator.sh]
    end
    
    subgraph Level1["Level 1: Core Defaults"]
        L1[oradba_core.conf System defaults PREFIX, VERSION, PATHS]
    end
    
    subgraph Level2["Level 2: Standard Settings"]
        L2[oradba_standard.conf Standard paths Oracle patterns]
    end
    
    subgraph Level3["Level 3: Local Settings"]
        L3[oradba_local.conf Auto-detected Coexistence mode Installation paths]
    end
    
    subgraph Level4["Level 4: Customer Overrides"]
        L4[oradba_customer.conf Site-specific RMAN catalog, TNS_ADMIN]
    end
    
    subgraph Level5["Level 5: SID Configuration"]
        L5[sid.SID.conf Database-specific Custom aliases, paths]
        L5D[sid._DEFAULT_.conf Template for new SIDs]
    end
    
    subgraph Level6["Level 6: Runtime"]
        L6[Environment Variables Command-line Args Highest priority]
    end
    
    subgraph Result["Final Configuration"]
        R[Active Environment All variables resolved]
    end
    
    L1 -->|Priority 1| P1
    L2 -->|Priority 2| P1
    L3 -->|Priority 3| P1
    L4 -->|Priority 4| P1
    L5 -->|Priority 5| P1
    L5D -.->|Template for| L5
    L6 -->|Priority 6 Highest| P1
    
    P1 --> P2
    P2 --> P3
    P3 --> R
    
    L1 -.->|Overridden by| L2
    L2 -.->|Overridden by| L3
    L3 -.->|Overridden by| L4
    L4 -.->|Overridden by| L5
    L5 -.->|Overridden by| L6
    
    style L1 fill:#FFE4B5
    style L1B fill:#F5DEB3
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
    participant oraenv.sh as oraenv.sh (Wrapper)
    participant oradba_env as oradba_env.sh (Builder)
    participant Parser as oradba_env_parser.sh
    participant Builder as oradba_env_builder.sh
    participant Validator as oradba_env_validator.sh
    participant Config as Config Files
    participant Homes as oradba_homes.conf
    participant Oratab
    participant Aliases as aliases.sh
    participant Status as oradba_env_status.sh
    
    User->>oraenv.sh: source oraenv.sh FREE
    oraenv.sh->>oraenv.sh: Parse arguments
    oraenv.sh->>oradba_env: Call oradba_env.sh FREE
    
    oradba_env->>Parser: Load parser library
    Parser->>Config: Parse oradba_core.conf
    Config-->>Parser: Core settings
    
    Parser->>Config: Parse oradba_standard.conf
    Config-->>Parser: Standard settings
    
    Parser->>Config: Parse oradba_local.conf
    Config-->>Parser: Local settings (coexistence mode)
    
    Parser->>Config: Parse oradba_customer.conf
    Config-->>Parser: Customer overrides
    
    Parser->>Config: Parse sid.FREE.conf or sid._DEFAULT_.conf
    Config-->>Parser: SID-specific settings
    
    Parser-->>oradba_env: Merged configuration
    
    oradba_env->>Builder: Load builder library
    
    alt FREE is SID
        Builder->>Oratab: Query oratab for FREE
        Oratab-->>Builder: ORACLE_HOME=/path/to/home
    else FREE is Home Name
        Builder->>Homes: Query oradba_homes.conf
        Homes-->>Builder: ORACLE_HOME=/path/to/home
    end
    
    Builder->>Builder: Derive ORACLE_BASE
    Builder->>Builder: Build PATH, LD_LIBRARY_PATH
    Builder->>Builder: Set TNS_ADMIN, SQLPATH
    Builder-->>oradba_env: Environment built
    
    oradba_env->>Validator: Load validator library
    Validator->>Validator: Check ORACLE_HOME exists
    Validator->>Validator: Verify binaries present
    Validator->>Validator: Detect product type
    Validator->>Validator: Detect Oracle version
    Validator-->>oradba_env: Validation passed
    
    oradba_env->>Aliases: Generate aliases
    Aliases->>Aliases: Check coexistence mode
    Aliases->>Aliases: Detect CDB/PDBs
    Aliases->>Aliases: Create safe aliases
    Aliases-->>oradba_env: 50+ aliases ready
    
    oradba_env->>Status: Display environment
    Status->>Status: Format output
    Status-->>User: Environment summary
    
    oradba_env-->>oraenv.sh: Environment ready
    oraenv.sh-->>User: ✅ Environment loaded
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
    S -->|No| SA[Detect BasEnv Installation]
    
    SA --> SB{BasEnv Found?}
    SB -->|Yes| SC[Enable Coexistence Mode]
    SB -->|No| SD[Standalone Mode]
    SC --> U[Create Directories]
    SD --> U
    
    R --> V[Preserve Config Files]
    V --> W[Remove Old Installation]
    W --> U
    
    U --> X[Extract Tarball]
    X --> Y[Create Directory Structure:<br/>bin/, lib/, etc/, sql/, rcv/, logs/]
    
    Y --> AD[Set Permissions]
    AD --> AE{--user Specified?}
    
    AE -->|Yes| AF[chown to user:group]
    AE -->|No| AG[Keep current ownership]
    
    AF --> AH[Run Integrity Check]
    AG --> AH
    
    AH --> AI{Verification Pass?}
    AI -->|No| AJ[Rollback to Backup]
    AJ --> AK[❌ Installation Failed]
    
    AI -->|Yes| AL[Create .install_info]
    AL --> ALA[Generate oradba_local.conf]
    ALA --> AM[Generate Uninstall Script]
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
    
    C --> CA{Coexist Mode?}
    CA -->|Yes| CB[Use safe_alias function]
    CA -->|No| CC[Use standard alias]
    CB --> D[Load Standard Aliases]
    CC --> D
    D --> E[Generate Core Aliases:<br/>SQL*Plus: sq, sqh, sqlplush<br/>RMAN: rmanc, rmanh, rmanch<br/>Navigation: cdh, cdo, cdn, cda<br/>Diagnostic: taa, tah, tal, tac<br/>File Edit: via, vio, vit, vip<br/>DB Ops: dbstart, dbstop, lsnrstart]
    E --> EA{Alias Exists in BasEnv?}
    EA -->|Yes & Coexist| EB[Skip Conflicting Aliases]
    EA -->|No| K{Is CDB?}
    EA -->|Yes & Force| K
    EB --> K
    
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
    T --> U[Generate PDB Aliases:<br/><pdbname>: sqlplus sys@PDB as sysdba<br/><pdbname>h: rlwrap sqlplus sys@PDB<br/>cd<pdbname>: cd to PDB directory]
    
    U --> AA{More PDBs?}
    AA -->|Yes| T
    AA -->|No| AB[Store PDB List Cache]
    
    L --> AC[Export All Aliases]
    AB --> AC
    
    AC --> AD[Display Alias Summary]
    AD --> AE[✅ Aliases Ready]
    
    style AE fill:#90EE90
    style M fill:#87CEEB
    style S fill:#DDA0DD
    style CA fill:#FFD700
    style EA fill:#FFD700
    style EB fill:#FFA500
```

## 12. SID Config Auto-Creation Flow (v0.14.0)

Shows the automatic creation of SID-specific configuration files from templates.

```mermaid
flowchart TD
    A[load_config SID called] --> B{ORADBA_AUTO_CREATE_SID_CONFIG=true?}
    
    B -->|No| C[Skip auto-creation]
    B -->|Yes| D{sid.SID.conf exists?}
    
    D -->|Yes| E[Load existing config]
    D -->|No| F{SID in ORADBA_REALSIDLIST?}
    
    F -->|No| G[❌ Skip: Dummy/Test SID]
    F -->|Yes| H[Read ORATAB_FILE]
    
    H --> I{Parse oratab for SID}
    I -->|Not found| J[❌ Skip: SID not in oratab]
    I -->|Found| K{Template exists?}
    
    K -->|No| L[❌ Error: Missing sid.ORACLE_SID.conf.example]
    K -->|Yes| M[Load template]
    
    M --> N[create_sid_config function]
    N --> O[Apply Template Transformations:<br/>- Replace ORCL with SID<br/>- Replace orcl with lowercase SID<br/>- Update timestamp<br/>- Update creation comment]
    O --> S[Write to etc/sid.SID.conf]
    
    S --> T{Syntax valid?}
    T -->|No| U[❌ Error: Invalid syntax]
    T -->|Yes| V[✅ Config created]
    
    V --> W[Load new config]
    E --> W
    C --> X[Continue without SID config]
    
    W --> Y[Environment ready]
    X --> Y
    G --> X
    J --> X
    
    style V fill:#90EE90
    style E fill:#87CEEB
    style G fill:#FFB6C6
    style J fill:#FFB6C6
    style L fill:#FF0000
    style U fill:#FF0000
    style N fill:#FFD700
```

## 13. Phase 1-3 Library Architecture (v0.19.0-v0.21.0)

Shows the new library-based configuration system introduced in Phase 1-3.

```mermaid
flowchart TB
    subgraph Entry["Entry Points"]
        E1[oraenv.sh Wrapper]
        E2[oradba_env.sh Main Builder]
        E3[oradba_homes.sh Home Manager]
    end
    
    subgraph Phase1["Phase 1: Configuration Parser"]
        P1[oradba_env_parser.sh]
        P1A[parse_config_file]
        P1B[merge_configs]
        P1C[resolve_variables]
    end
    
    subgraph Phase2["Phase 2: Environment Builder"]
        P2[oradba_env_builder.sh]
        P2A[build_oracle_env]
        P2B[derive_oracle_base]
        P2C[construct_path]
        P2D[set_tns_admin]
    end
    
    subgraph Phase3["Phase 3: Validation & Display"]
        P3A[oradba_env_validator.sh]
        P3A1[validate_oracle_home]
        P3A2[detect_product_type]
        P3A3[detect_version]
        
        P3B[oradba_env_config.sh]
        P3B1[get_config_value]
        P3B2[set_config_value]
        
        P3C[oradba_env_status.sh]
        P3C1[show_environment]
        P3C2[show_config_sources]
        
        P3D[oradba_env_changes.sh]
        P3D1[track_changes]
        P3D2[show_diff]
    end
    
    subgraph ConfigFiles["Configuration Files"]
        C1[oradba_core.conf]
        C2[oradba_standard.conf]
        C3[oradba_local.conf]
        C4[oradba_customer.conf]
        C5[sid.SID.conf]
        C6[sid._DEFAULT_.conf]
        C7[oradba_homes.conf]
    end
    
    subgraph Common["Common Libraries"]
        L1[common.sh Logging & Utilities]
        L2[aliases.sh Safe Alias Generation]
    end
    
    E1 --> E2
    E2 --> P1
    E3 --> P1
    
    P1 --> P1A
    P1 --> P1B
    P1 --> P1C
    
    ConfigFiles --> P1A
    P1C --> P2
    
    P2 --> P2A
    P2 --> P2B
    P2 --> P2C
    P2 --> P2D
    
    P2 --> P3A
    P2 --> P3B
    P2 --> P3C
    
    P3A --> P3A1
    P3A --> P3A2
    P3A --> P3A3
    
    P3B --> P3B1
    P3B --> P3B2
    
    P3C --> P3C1
    P3C --> P3C2
    
    P3D --> P3D1
    P3D --> P3D2
    
    P1 --> L1
    P2 --> L1
    P3A --> L1
    P3C --> L1
    
    E2 --> L2
    
    style Phase1 fill:#87CEEB
    style Phase2 fill:#90EE90
    style Phase3 fill:#FFD700
    style ConfigFiles fill:#FFE4B5
    style Common fill:#DDA0DD
```

## Diagram Sources

- **CI/CD Pipeline**: Shows GitHub Actions workflows with smart vs full test selection and documentation deployment
- **Test Strategy**: Architecture of smart test selection system with .testmap.yml
- **Development Workflow**: Developer decision tree for testing and releasing
- **Performance Comparison**: Visual time savings comparison
- **Test Selection Decision**: Simplified logic for test selection
- **Architecture System**: OraDBA layered system architecture with Phase 1-3 libraries and Phase 1-4 configuration system
- **oraenv.sh Flow**: Complete environment setup with Phase 1-3 library integration and oradba_env.sh wrapper
- **Configuration Hierarchy**: 6-level configuration with Phase 1-3 processing (parser, builder, validator)
- **Configuration Sequence**: Library-based configuration loading with oradba_env_parser.sh, builder, and validator
- **Installation Flow**: Self-extracting installer with BasEnv detection and oradba_local.conf generation
- **Alias Generation**: Dynamic alias generation with safe_alias() coexistence mode
- **SID Config Auto-Creation**: Automatic config generation from sid._DEFAULT_.conf template (v0.14.0)
- **Phase 1-3 Library Architecture**: Detailed view of library relationships and function calls (v0.19.0-v0.21.0)

## Version History

- **v0.22.0**: Updated diagrams to reflect Phase 1-4 configuration system
  - Added Phase 1-3 library components to Architecture diagram
  - Updated Configuration Hierarchy to show 6 levels with Phase 1-3 processing
  - Revised oraenv.sh flow to show wrapper → oradba_env.sh → libraries pattern
  - Updated Configuration Sequence to show library-based loading
  - Added new Phase 1-3 Library Architecture diagram
- **v0.14.0**: Added SID config auto-creation diagrams
- **v0.13.x**: Initial CI/CD and test selection diagrams
