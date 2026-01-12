# Extension Documentation Integration Guide

This guide explains how to integrate your OraDBA extension documentation with the
main OraDBA documentation site at <https://code.oradba.ch/oradba/>.

**Important:** Extension documentation is maintained separately and linked from the
main site. It is **not included in the main OraDBA PDF documentation** - only the
catalog page listing available extensions is part of the main docs.

## Documentation Structure

Your extension repository should include a `doc/` directory with your documentation
in Markdown format:

```text
your-extension/
├── bin/              # Extension scripts
├── sql/              # SQL scripts
├── lib/              # Libraries
├── doc/              # 📚 Documentation (required for integration)
│   ├── index.md      # Main page (required)
│   ├── installation.md
│   ├── configuration.md
│   ├── reference.md
│   ├── changelog.md
│   └── images/       # Optional images
├── README.md
└── .extension        # Extension metadata
```

## Documentation Requirements

### Required Files

1. **`doc/index.md`** - Main documentation page
   - Overview of the extension
   - Quick start guide
   - Installation instructions
   - Link to other documentation pages

### Recommended Files

1. **`doc/configuration.md`** - Configuration options and examples
2. **`doc/reference.md`** - Command/script reference
3. **`CHANGELOG.md`** - Version history and changes (Keep a Changelog format)

### Markdown Format

- Use standard Markdown
- Use relative links for navigation between pages
- Place images in `doc/images/` directory
- Follow Material for MkDocs conventions for admonitions, tabs, etc.

**Example index.md:**

```markdown
# My Extension Name

Brief description of what your extension does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Quick Start

\`\`\`bash
# Install the extension
oradba_extension.sh install myextension

# Use it
source oraenv.sh MYDB
myextension-command
\`\`\`

## Documentation

- [Installation](installation.md)
- [Configuration](configuration.md)
- [Command Reference](reference.md)
- [Changelog](changelog.md)

## Support

- [GitHub Issues](https://github.com/yourorg/myextension/issues)
- [Repository](https://github.com/yourorg/myextension)
```

## Integration Process

### 1. Prepare Your Documentation

Ensure your `doc/` directory is complete and follows the structure above.

**Note:** Your extension documentation will be linked from the main OraDBA
documentation but is **not included in the PDF version** of the main docs.
Only the extensions catalog page is part of the main documentation.

### 2. Submit for Inclusion

To have your extension documentation included in the main OraDBA docs:

1. **Fork the OraDBA repository**
2. **Edit `.github/extensions.yml`**
3. **Add your extension entry:**

```yaml
extensions:
  # ... existing extensions ...
    # Path to doc directory in your repo (default: doc
  - name: myextension
    display_name: My Extension Name
    repo: yourorg/myextension
    docs_path: docs  # Path to docs in your repo (default: docs)
    description: Brief description of your extension
    category: Operations  # or: Development, Monitoring, Backup, etc.
    maintainer: Your Name
    status: active
```

1. **Create a Pull Request** to the main OraDBA repository
2. **Wait for review** - Your extension will be reviewed for quality and compatibility

### 3. Automatic Updates

Once approved, your documentation will be automatically pulled and published:

- **On OraDBA doc builds** - Your docs are fetched from your repo
- **Location:** `https://code.oradba.ch/oradba/extensions/<your-extension>/`
- **Updates:** Pulled automatically when OraDBA docs are rebuilt

## Triggering Documentation Updates

### Automatic (Recommended)

Documentation is automatically synced when:

- OraDBA main documentation is built (on releases, main branch updates)
- Registry file (`.github/extensions.yml`) is updated

### Manual Trigger from Extension Repo

Your extension can trigger a documentation rebuild of the main site:

```yaml
# .github/workflows/docs-notify.yml in your extension repo
name: Notify OraDBA Docs Update

on:
  release:
    types: [published]
  workflow_dispatch:

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger OraDBA docs rebuild
        run: |
          curl -X POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${{ secrets.ORADBA_DISPATCH_TOKEN }}" \
            https://api.github.com/repos/oehrlis/oradba/dispatches \
            -d '{"event_type":"extension-docs-update","client_payload":{"extension":"${{ github.repository }}"}}'
```

**Note:** You'll need a GitHub token with `repo` scope. Contact the OraDBA maintainer to set this up.

## Best Practices

### Writing Documentation

1. **Be Clear and Concise** - Users should quickly understand what your extension does
2. **Include Examples** - Show real-world usage scenarios
3. **Keep It Updated** - Update docs when you release new versions
4. **Use Standard Markdown** - Avoid HTML when possible
5. **Test Links** - Ensure all internal links work

### Directory Structure

```text
doc/
├── index.md              # Landing page
├── getting-started.md    # Installation & setup
├── configuration.md      # Config options
├── usage/                # Usage guides
│   ├── basic.md
│   └── advanced.md
├── reference/            # Reference docs
│   ├── commands.md
│   └── scripts.md
├── images/               # Images
│   └── architecture.png
└── changelog.md          # Version history
```

### Material for MkDocs Features

You can use Material for MkDocs features:

```markdown
!!! note "Important Note"
    This is an admonition block

!!! warning "Compatibility"
    Requires OraDBA v0.18.0 or later

=== "Tab 1"
    Content for tab 1

=== "Tab 2"
    Content for tab 2

[Button Text](link){ .md-button }
```

## Testing Locally

Test your documentation locally before submission:

```bash
# Install MkDocs and Material theme
pip install mkdocs-material

# Create a temporary mkdocs.yml
cat > mkdocs.yml <<EOF
site_name: My Extension Docs
theme:
  name: material
docs_dir: doc
EOF

# Serve locally
mkdocs serve

# Visit http://127.0.0.1:8000
```

## Support

- **Questions:** Open an issue in the main [OraDBA repository](https://github.com/oehrlis/oradba/issues)
- **Documentation:** See the [OraDBA Extension System Guide](https://code.oradba.ch/oradba/18-extensions/)
- **Examples:** Review the [Extension Template](https://github.com/oehrlis/oradba_extension)

## Example Extensions

See these official extensions for examples:

- [oradba_extension](https://github.com/oehrlis/oradba_extension) - Template and reference implementation

---

**Questions?** Contact the OraDBA maintainer or open a discussion in the repository.
