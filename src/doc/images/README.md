# Documentation Images

This directory contains diagram images for OraDBA documentation.

## Contents

PNG files exported from Excalidraw diagrams. See [../diagrams-todo.md](../diagrams-todo.md) for the complete list and status.

## Source Files

Excalidraw source files (`.excalidraw`) are stored in the `source/` subdirectory.

## Usage

Images are referenced in documentation using relative paths:

```markdown
![System Architecture](images/architecture-system.png)
```

## Export Settings

All images should be exported from Excalidraw with:

- Format: PNG
- Scale: 2x (for retina displays)
- Background: Transparent or white
- Embed scene: Yes (includes source data in PNG)

## File Naming Convention

- Lowercase with hyphens
- Descriptive names
- Component prefix when applicable
- Example: `architecture-system.png`, `config-hierarchy.png`
