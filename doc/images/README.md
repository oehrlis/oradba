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

<!-- markdownlint-disable MD013 -->
| Diagram                    | Description                                               | File                                                         |
|----------------------------|-----------------------------------------------------------|--------------------------------------------------------------|
| **System Architecture**    | Complete layered architecture with Registry API & plugins | [architecture-system.md](architecture-system.md)             |
| **Environment Libraries**  | Modular library system (7 env libraries + plugins)        | [phase1-3-libraries.md](phase1-3-libraries.md)               |
| **Configuration (overview)** | 5-layer hierarchy (core→standard→local→customer→sid)    | [config-workflow-highlevel.md](config-workflow-highlevel.md) |
| **Configuration (detailed)** | Internal function calls, variable export, cleanup       | [config-workflow-detailed.md](config-workflow-detailed.md)   |
| **Configuration Sequence** | Library-based config loading sequence diagram             | [config-sequence.md](config-sequence.md)                     |
| **Plugin System**          | Plugin lifecycle, 13-function interface, integration      | [plugin-system.md](plugin-system.md)                         |
| **Registry API Flow**      | Unified installation metadata access                      | [registry-api-flow.md](registry-api-flow.md)                 |
<!-- markdownlint-enable MD013 -->

### Workflows & Operations

<!-- markdownlint-disable MD013 -->
| Diagram                  | Description                                      | File                                                         |
|--------------------------|--------------------------------------------------|--------------------------------------------------------------|
| **oraenv (overview)**    | Environment setup (interactive/non-interactive)  | [oraenv-workflow-highlevel.md](oraenv-workflow-highlevel.md) |
| **oraenv (detailed)**    | Complete function call flow                      | [oraenv-workflow-detailed.md](oraenv-workflow-detailed.md)   |
| **oraup (overview)**     | Status display (registry query, type separation) | [oraup-workflow-highlevel.md](oraup-workflow-highlevel.md)   |
| **oraup (detailed)**     | Detailed status checking and formatting          | [oraup-workflow-detailed.md](oraup-workflow-detailed.md)     |
| **Installation Flow**    | Self-extracting installer with integrity check   | [installation-flow.md](installation-flow.md)                 |
<!-- markdownlint-enable MD013 -->

**Viewing Mermaid Diagrams:**

- **VS Code**: Install [Mermaid Preview](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)
- **GitHub**: Native rendering in browser
- **Live Editor**: [mermaid.live](https://mermaid.live/) for editing/exporting

## Directory Structure

```text
doc/images/                      # All Mermaid diagrams
├── architecture-system.md       # Complete system architecture
├── phase1-3-libraries.md        # Environment management library architecture
├── config-workflow-highlevel.md # Configuration hierarchy overview
├── config-workflow-detailed.md  # Configuration detailed flow
├── config-sequence.md           # Configuration loading sequence diagram
├── plugin-system.md             # Plugin system lifecycle
├── registry-api-flow.md         # Registry API data flow
├── oraenv-workflow-highlevel.md # oraenv overview workflow
├── oraenv-workflow-detailed.md  # oraenv detailed workflow
├── oraup-workflow-highlevel.md  # oraup overview workflow
├── oraup-workflow-detailed.md   # oraup detailed workflow
├── installation-flow.md         # Installer process flow
└── README.md                    # This file
```

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
- **#B0E0E6** (Powder Blue): Output formatter

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
