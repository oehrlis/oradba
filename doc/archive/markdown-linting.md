# Markdown Linting

This project uses markdownlint to ensure consistent markdown formatting.

## Configuration

Markdownlint configuration is defined in:

- `.markdownlint.json` - JSON format configuration
- `.markdownlint.yaml` - YAML format configuration (alternative)

## Rules

Key rules enforced:

- **MD001**: Heading levels increment by one
- **MD003**: ATX-style headers (using `#`)
- **MD007**: List indentation (2 spaces)
- **MD013**: Line length limit (120 characters, excluding code blocks and tables)
- **MD024**: No duplicate headings (siblings only)
- **MD033**: Limited inline HTML (br, details, summary, kbd allowed)
- **MD041**: First line heading not required (disabled for flexibility)

## Linting Locally

### Using markdownlint-cli

```bash
# Install
npm install -g markdownlint-cli

# Lint all markdown files
markdownlint '**/*.md'

# Lint specific files
markdownlint README.md CONTRIBUTING.md

# Fix automatically (where possible)
markdownlint --fix '**/*.md'
```

### Using markdownlint-cli2

```bash
# Install
npm install -g markdownlint-cli2

# Lint all markdown files
markdownlint-cli2 '**/*.md'

# Fix automatically
markdownlint-cli2-fix '**/*.md'
```

### Using VS Code

Install the "markdownlint" extension by David Anson.
The extension will automatically use the `.markdownlint.json` configuration.

## CI Integration

Markdown linting can be added to CI/CD:

```yaml
- name: Lint Markdown
  run: |
    npm install -g markdownlint-cli
    markdownlint '**/*.md' --ignore node_modules
```

## Common Issues

### Line Too Long (MD013)

**Problem**: Lines exceed 120 characters

**Solution**: Break long lines, especially in paragraphs:

```markdown
<!-- Bad -->
This is a very long line that exceeds the maximum line length and should be broken into multiple lines for better readability.

<!-- Good -->
This is a very long line that exceeds the maximum line length and should be broken
into multiple lines for better readability.
```

### Duplicate Headings (MD024)

**Problem**: Multiple headings with same text

**Solution**: Use unique headings or enable `siblings_only` option (already enabled)

### Inline HTML (MD033)

**Problem**: HTML tags not allowed

**Solution**: Use markdown alternatives or add to allowed list:

```markdown
<!-- Bad -->
<div>Content</div>

<!-- Good -->
Use markdown formatting instead

<!-- Allowed -->
<br>
<details><summary>Collapsible</summary>Content</details>
```

## Best Practices

1. **One sentence per line** in paragraphs for easier diffs
2. **Use ATX headers** (`#` style) instead of underlines
3. **Specify language** in code blocks
4. **Keep lines under 120 characters** (excluding code/tables)
5. **No trailing whitespace**
6. **Blank line** before/after headings and lists
7. **Consistent list markers** (dashes for unordered)
8. **Proper link formatting** with descriptive text

## Reference

- [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Markdown style guide](https://google.github.io/styleguide/docguide/style.html)
