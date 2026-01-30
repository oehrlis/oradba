# OraDBA Documentation Images & Diagrams

This directory contains Mermaid diagrams for OraDBA documentation. All diagrams
are text-based Mermaid code that renders automatically in VS Code, GitHub, and
modern documentation sites.

## Mermaid-Only Workflow (v0.19.0+)

OraDBA uses a **Mermaid-first approach** for all diagrams:

- **Phase 1 (COMPLETE)**: Created source Mermaid files (now in root)
- **Phase 2 (COMPLETE)**: Embedded Mermaid in architecture.md, development.md, and all 20 user docs (v0.19.x)
- **Phase 3 (PLANNED)**: Automated Mermaid rendering for PDF generation (Pandoc integration)

**Benefits**:

- ✅ Native rendering in GitHub and VS Code
- ✅ Version control friendly (text-based, clear diffs)
- ✅ Easy to maintain and update
- ✅ No build step required for viewing
- ✅ Interactive and zoomable
- ✅ Single source of truth per diagram

## Quick Navigation

- **[Architecture & Core Systems](#architecture--core-systems)** - System architecture, libraries, config
- **[Workflows & Operations](#workflows--operations)** - Environment setup, status display, installation
- **[Directory Structure](#directory-structure)** - File organization

## Mermaid Diagrams

### Architecture & Core Systems

| Diagram                     | Description                                               | File                                                         |
|-----------------------------|-----------------------------------------------------------|--------------------------------------------------------------|
| **System Architecture**     | Complete layered architecture with Registry API & plugins | [architecture-system.md](architecture-system.md)             |
| **Environment Libraries**   | Modular library system (parser, builder, validator)       | [phase1-3-libraries.md](phase1-3-libraries.md)               |
| **Configuration System**    | 5-layer hierarchy (core→standard→local→customer→sid)      | [config-workflow-highlevel.md](config-workflow-highlevel.md) |
| **Configuration Hierarchy** | 6-level config with processing libraries                  | [config-hierarchy.md](config-hierarchy.md)                   |
| **Configuration Details**   | Internal function calls, variable export, cleanup         | [config-workflow-detailed.md](config-workflow-detailed.md)   |
| **Configuration Sequence**  | Library-based config loading sequence diagram             | [config-sequence.md](config-sequence.md)                     |
| **Plugin System**           | Plugin lifecycle, 11-function interface, integration       | [plugin-system.md](plugin-system.md)                         |
| **Registry API Flow**       | Unified installation metadata access                      | [registry-api-flow.md](registry-api-flow.md)                 |

### Workflows & Operations

| Diagram                   | Description                                      | File                                                         |
|---------------------------|--------------------------------------------------|--------------------------------------------------------------|
| **oraenv Workflow**       | Environment setup (interactive/non-interactive)  | [oraenv-workflow-highlevel.md](oraenv-workflow-highlevel.md) |
| **oraenv Execution Flow** | Complete environment setup process               | [oraenv-flow.md](oraenv-flow.md)                             |
| **oraenv Details**        | Complete function call flow                      | [oraenv-workflow-detailed.md](oraenv-workflow-detailed.md)   |
| **oraup Workflow**        | Status display (registry query, type separation) | [oraup-workflow-highlevel.md](oraup-workflow-highlevel.md)   |
| **oraup Details**         | Detailed status checking and formatting          | [oraup-workflow-detailed.md](oraup-workflow-detailed.md)     |
| **Installation Flow**     | Self-extracting installer with integrity check   | [installation-flow.md](installation-flow.md)                 |

**Viewing Mermaid Diagrams:**

- **VS Code**: Install [Mermaid Preview](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)
- **GitHub**: Native rendering in browser
- **Live Editor**: [mermaid.live](https://mermaid.live/) for editing/exporting

## Directory Structure

```text
doc/images/                  # All Mermaid diagrams
├── architecture-system.md   # System architecture (embedded in architecture.md)
├── oraenv-flow.md          # Environment setup flow (embedded in architecture.md)
├── phase1-3-libraries.md   # Library architecture (embedded in architecture.md)
├── config-hierarchy.md     # 6-level configuration (embedded in architecture.md)
├── installation-flow.md    # Installer process (embedded in architecture.md)
├── config-sequence.md      # Config loading sequence (embedded in architecture.md)
├── config-workflow-*.md    # Configuration workflow diagrams (2 files)
├── oraenv-workflow-*.md    # oraenv workflow diagrams (2 files)
├── oraup-workflow-*.md     # oraup workflow diagrams (2 files)
├── plugin-system.md        # Plugin system diagram
├── registry-api-flow.md    # Registry API flow
└── README.md               # This file
```

**Phase 2 Status**:

- ✅ All source files in root directory (flat structure)
- ✅ Embedded 6 diagrams in architecture.md
- ✅ Embedded 6 diagrams in user docs (introduction.md, quickstart.md, environment.md, configuration.md, installation.md)
- ✅ Legacy PNG/Excalidraw files removed
- ✅ All 20 user docs updated to v0.19.x (no PNG references)
- 🔄 TODO: Update MkDocs/GitHub Pages configuration

## Usage in Documentation

### Developer Docs (doc/*.md)

Embed Mermaid directly in markdown files:

```markdown
## System Architecture

\`\`\`mermaid
graph TB
    A[Component A] --> B[Component B]
\`\`\`
```

### User Docs (src/doc/*.md)

Same approach - embed Mermaid code blocks directly in documentation.

### PDF Generation (Phase 3)

Planned integration with Pandoc for automatic Mermaid rendering in PDF output.

## Creating New Diagrams

### Mermaid Workflow

1. **Draft**: Use [Mermaid Live Editor](https://mermaid.live/) for initial creation
2. **Consistency**: Follow existing diagram patterns and color schemes
3. **Create**: Create standalone .md file in this directory for reusable diagrams
4. **Embed**: Add Mermaid code block directly in documentation files
5. **Validate**: Test rendering in VS Code and GitHub
6. **Document**: Update this README with new diagram entry

### Color Coding Standards

Consistent colors across all diagrams:

- **#E6E6FA** (Lavender): User layer, entry points
- **#87CEEB** (Sky Blue): CLI layer, parser
- **#98FB98** (Pale Green): Registry API
- **#FFD700** (Gold): Plugin system, builder
- **#DDA0DD** (Plum): Environment libraries, validator
- **#90EE90** (Light Green): Core libraries, success states
- **#FFE4B5** (Moccasin): Configuration system, status
- **#FFB6C6** (Pink): Oracle layer, error states
- **#FFA07A** (Light Salmon): Change tracking
- **#F0E68C** (Khaki): Config manager

### Diagram Types

- **Flowchart**: Process flows, decision trees (`flowchart TD` or `flowchart LR`)
- **Graph**: System architecture, component relationships (`graph TB` or `graph LR`)
- **Sequence**: Interaction sequences, library calls (`sequenceDiagram`)
- **State**: State machines, lifecycle (`stateDiagram-v2`)

## References

- [Mermaid Documentation](https://mermaid.js.org/)
- [Mermaid Live Editor](https://mermaid.live/)
- [GitHub Mermaid Support](https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/)
- [VS Code Mermaid Extension](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)
