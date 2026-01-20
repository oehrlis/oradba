# Installation Flow

Self-extracting installer with embedded payload and integrity verification.

```mermaid
flowchart TD
    A[User Downloads<br/>oradba_install.sh] --> B[Execute Installer]
    
    B --> C{Installation<br/>Mode?}
    
    C -->|Default| D[Embedded Payload<br/>base64 in Script]
    C -->|--local FILE| E[Local Tarball<br/>File Path]
    C -->|--github| F[GitHub Download<br/>Latest Release]
    
    D --> G[Extract base64 Payload]
    E --> H[Read Local File]
    F --> I[Download from GitHub]
    
    G --> J[Decode & Verify]
    H --> J
    I --> J
    
    J --> K{Valid<br/>Checksum?}
    
    K -->|No| M[❌ Installation Failed<br/>Invalid Tarball]
    
    K -->|Yes| N{Update<br/>Mode?}
    
    N -->|Yes| O[Check Installed Version]
    O --> P{Version<br/>Newer?}
    P -->|No| Q[❌ No Update Needed<br/>Same/Older Version]
    P -->|Yes| R[Backup Existing Install]
    
    N -->|No| S{Prefix<br/>Exists?}
    S -->|Yes| T[❌ Already Installed<br/>Use --update]
    S -->|No| U[Create Directories]
    
    R --> V[Preserve Config Files]
    V --> W[Remove Old Installation]
    W --> U
    
    U --> X[Extract Tarball]
    
    X --> Y[Create Structure:<br/>bin/ lib/ etc/<br/>sql/ rcv/ log/]
    
    Y --> Z[Set Permissions]
    
    Z --> AA{--user<br/>Specified?}
    
    AA -->|Yes| AB[chown to User:Group]
    AA -->|No| AC[Keep Current Owner]
    
    AB --> AD[Integrity Check]
    AC --> AD
    
    AD --> AE{Verification<br/>Pass?}
    
    AE -->|No| AF[Rollback to Backup]
    AF --> AG[❌ Installation Failed<br/>Verification Error]
    
    AE -->|Yes| AH[Create .install_info]
    
    AH --> AI[Generate<br/>oradba_local.conf]
    
    AI --> AJ[Create Uninstall Script]
    
    AJ --> AK[Display Success Message]
    
    AK --> AL[✅ Installation Complete]
    
    style AL fill:#90EE90
    style M fill:#FFB6C6
    style Q fill:#FFB6C6
    style T fill:#FFB6C6
    style AG fill:#FFB6C6
    style R fill:#FFD700
    style AD fill:#87CEEB
```

## Description

The installation process provides:

1. **Multiple Sources**: Embedded payload, local file, or GitHub download
2. **Integrity Verification**: SHA256 checksum validation
3. **Update Support**: Preserves configs when updating
4. **Backup & Rollback**: Automatic backup with rollback on failure
5. **Permission Handling**: Optional user/group ownership
6. **Auto-Configuration**: Generates oradba_local.conf
7. **Uninstall Script**: Creates removal script

## Installation Modes

- **Default**: Uses embedded base64-encoded tarball
- **--local FILE**: Uses local tarball file
- **--github**: Downloads latest release from GitHub

## Safety Features

- Checksum verification before extraction
- Version check to prevent downgrades
- Backup existing installation before update
- Integrity check after extraction
- Rollback on verification failure
- Uninstall script for clean removal
