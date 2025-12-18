# Documentation Images

This directory contains source diagrams and images for OraDBA documentation.

## Directory Structure

```text
doc/images/              # Source images (tracked in git)
├── *.png                # Exported PNG diagrams
├── source/              # Excalidraw source files
│   └── *.excalidraw     # Editable diagram sources
└── README.md            # This file

src/doc/images/          # Build artifact (NOT tracked, copied during build)
srv/doc/images/          # Build artifact (NOT tracked, copied during build)
```

## Image Workflow

**Source Location (tracked in git):**

- `doc/images/` - PNG exports and this README
- `doc/images/source/` - Excalidraw source files

**Build Process:**

- During `make docs-html` or `make docs-pdf`:
  1. Images copied from `doc/images/` → `src/doc/images/`
  2. Images copied from `doc/images/` → `srv/doc/images/`
  3. Documentation built with images in place
- Build artifacts cleaned with `make docs-clean-images`

**References in Documentation:**

- User docs (`src/doc/*.md`) use relative path: `images/diagram-name.png`
- Developer docs (`doc/*.md`) use relative path: `images/diagram-name.png`

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
