# Extension Documentation Integration - Implementation Summary

## Overview

Implemented a **pull-based** system where the main OraDBA repository maintains
control over which extensions are documented and when their documentation is
synchronized.

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│ Extension Repos (separate repositories)                 │
│ ├── yourextension/doc/index.md                          │
│ ├── yourextension/doc/configuration.md                  │
│ └── yourextension/doc/reference.md                      │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Pull during build
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Main OraDBA Repo                                        │
│ ├── .github/extensions.yml (Registry)                   │
│ ├── .github/scripts/sync_extension_docs.py              │
│ ├── .github/workflows/docs.yml (Updated)                │
│ ├── src/doc/19-extensions-catalog.md (Index)            │
│ └── src/doc/extensions/                                 │
│     └── yourextension/ (Auto-synced)                    │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Deploy
                        ▼
┌─────────────────────────────────────────────────────────┐
│ GitHub Pages: https://code.oradba.ch/oradba/           │
│ ├── /                  (Main docs)                      │
│ ├── /extensions/       (Extension catalog)              │
│ └── /extensions/<name>/ (Individual extensions)         │
└─────────────────────────────────────────────────────────┘
```

## Files Created/Modified

### Main Repo (oradba)

**New Files:**

1. `.github/extensions.yml` - Registry of official extensions
2. `.github/scripts/sync_extension_docs.py` - Python script to sync extension docs
3. `src/doc/19-extensions-catalog.md` - Extensions catalog index page
4. `doc/extension-docs-integration.md` - Guide for extension developers

**Modified Files:**

1. `mkdocs.yml` - Added Extensions section to navigation
2. `.github/workflows/docs.yml` - Added extension sync step and triggers

## How It Works

### 1. Extension Registry (`.github/extensions.yml`)

Centralized YAML file listing all official extensions:

```yaml
extensions:
  - name: oradba_extension
    display_name: OraDBA Extension Template
    repo: oehrlis/oradba_extension
    docs_path: doc
    description: Template and example for creating extensions
    category: Development
    maintainer: Stefan Oehrli
    status: active
```

### 2. Documentation Sync Process

When docs are built:

1. **Workflow triggered** by:
   - Push to main (doc changes)
   - Release published
   - Manual workflow dispatch
   - Repository dispatch from extensions
   - Changes to extensions.yml

2. **Python script runs** (`.github/scripts/sync_extension_docs.py`):
   - Reads extensions.yml
   - Clones/updates each extension repo
   - Copies docs from `<extension>/doc/` to `src/doc/extensions/<name>/`
   - Updates the catalog index page

3. **MkDocs builds** the complete site including extension docs

4. **GitHub Pages deploys** to <https://code.oradba.ch/oradba/>

### 3. Extension Catalog

The catalog page (`src/doc/19-extensions-catalog.md`) is automatically updated:

- Lists all active extensions from registry
- Links to their documentation
- Shows repository, category, status

## URL Structure

```text
https://code.oradba.ch/oradba/
├── /                              Main OraDBA docs
├── /18-extensions/                Extension system guide
├── /19-extensions-catalog/        Extensions catalog
└── /extensions/
    ├── /oradba_extension/         Extension 1 docs
    │   ├── /index
    │   ├── /configuration
    │   └── /reference
    └── /oradba_monitoring/        Extension 2 docs
        ├── /index
        └── /configuration
```

## For Extension Developers

### Required: doc/ Directory Structure

**Important:** Extension documentation is maintained separately from the main
OraDBA documentation. It will be linked from the main site but is **not included
in the main OraDBA PDF documentation**.

```text
your-extension/
├── doc/
│   ├── index.md           # Required - main page
│   ├── installation.md    # Recommended
│   ├── configuration.md   # Recommended
│   ├── reference.md       # Recommended
│   └── images/            # Optional
└── ... (rest of extension)
```

### Getting Listed

1. Ensure `docs/` directory exists with proper content
2. Fork oradba repo
3. Add extension to `.github/extensions.yml`
4. Create PR
5. After approval, docs automatically sync

### Triggering Updates

**Automatic:** Docs sync on every OraDBA doc build

**Manual:** Extension can trigger rebuild:

```yaml
# In extension repo: .github/workflows/docs-notify.yml
- name: Notify OraDBA
  run: |
    curl -X POST \
      -H "Authorization: token ${{ secrets.ORADBA_DISPATCH_TOKEN }}" \
      https://api.github.com/repos/oehrlis/oradba/dispatches \
      -d '{"event_type":"extension-docs-update"}'
```

## Benefits

### ✅ Advantages

1. **Main repo controls** what extensions are documented
2. **No write access needed** for extension repos
3. **Automatic synchronization** on doc builds
4. **Simple to add** new extensions (just edit YAML)
5. **Unified documentation** site with all extensions
6. **Version independent** - always shows latest docs
7. **No webhooks** or complex setup required
8. **Easy to test** - run sync script locally

### 📋 Maintenance

- **Add extension:** Edit `.github/extensions.yml` and commit
- **Remove extension:** Set `status: archived` in registry
- **Update docs:** Docs auto-sync on next build
- **Force sync:** Run workflow manually via GitHub Actions UI

## Testing

### Local Testing

```bash
# Test the sync script
cd /path/to/oradba
python .github/scripts/sync_extension_docs.py

# Check synced docs
ls -la src/doc/extensions/

# Build docs locally
pip install mkdocs-material pyyaml
mkdocs serve
```

### Extension Testing

```bash
# In extension repo
mkdocs serve --config-file test-mkdocs.yml
```

## Next Steps

### For Main Repo

1. ✅ Commit these changes
2. Push to GitHub
3. Verify workflow runs successfully
4. Check deployed site at <https://code.oradba.ch/oradba/>

### For Extension Repos (e.g., oradba_extension)

1. Create `doc/` directory
2. Add documentation files
3. Test locally with mkdocs
4. Commit and push
5. Verify sync in main repo

## Security Considerations

- ✅ Only official extensions (in registry) are pulled
- ✅ Read-only access to extension repos
- ✅ No tokens needed for public repos
- ✅ Main repo maintains full control
- ⚠️ Extensions should not execute code during doc build (pure markdown)

## Future Enhancements

**Optional improvements:**

1. **Versioning:** Pin extension docs to specific versions/tags
2. **Validation:** Validate extension docs structure before sync
3. **Caching:** Cache extension repos between builds
4. **Analytics:** Track which extension docs are viewed
5. **Search:** Ensure extension docs are included in site search
6. **API:** Provide API to query available extensions

---

**Status:** ✅ Ready to implement  
**Impact:** Low risk - additive changes only  
**Testing:** Local testing recommended before deployment
