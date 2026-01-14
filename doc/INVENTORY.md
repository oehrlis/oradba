# Development Documentation Inventory

**Date:** 2026-01-14  
**Purpose:** Categorize dev docs for v1.0.0 consolidation

---

## ✅ Keep & Update (Core Documentation)

These are essential developer docs that need to be current for v1.0.0.

| File | Size | Status | Action Needed |
|------|------|--------|---------------|
| **README.md** | 5.1K | Needs Update | Create navigation index for all dev docs |
| **architecture.md** | 9.5K | ✅ Current | Just updated in Phase 5.3 - verify only |
| **development.md** | 42K | Needs Review | Large file - consolidate CI/linting sections into it |
| **api.md** | 43K | Needs Review | Large file - verify API docs are current |
| **extension-system.md** | 21K | Needs Review | Consolidate extension-docs-* into this |
| **oradba-env-design.md** | 46K | Needs Review | Environment library design - keep as reference |
| **release-testing-checklist.md** | 13K | ✅ Keep | Use for v1.0.0 testing |

**Total:** 7 files to keep and update

---

## 🔄 Consolidate (Merge into Core Docs)

These contain good content that belongs in main docs.

| File | Size | Merge Into | Rationale |
|------|------|------------|-----------|
| **ci_optimization.md** | 8.5K | development.md | CI/CD section belongs in development guide |
| **markdown-linting.md** | 3.0K | development.md | Code quality section belongs in development guide |
| **extension-docs-implementation.md** | 8.1K | extension-system.md | Consolidate all extension docs into one |
| **extension-docs-integration.md** | 6.8K | extension-system.md | Consolidate all extension docs into one |

**Total:** 4 files to consolidate (merge and delete)

---

## 🗑️ Remove/Archive (Temporary Planning Docs)

These were useful during development but are no longer needed for v1.0.0.

| File | Size | Category | Reason for Removal |
|------|------|----------|-------------------|
| **function-header-standardization.md** | 6.1K | Planning | Temporary - Phase 5.3/5.4 planning doc |
| **legacy-code-analysis.md** | 12K | Planning | Historical analysis - no longer relevant |
| **smart-test-selection.md** | 5.7K | Planning | Test optimization planning - obsolete |
| **structure.md** | 13K | Planning | Old structure documentation - outdated |
| **test-requirements.md** | 5.9K | Planning | Test planning - merge key points into development.md |
| **version-management.md** | 7.5K | Planning | Version strategy planning - obsolete after v1.0.0 |

**Total:** 6 files to remove/archive

---

## 📁 Other Files/Directories

| Item | Type | Status |
|------|------|--------|
| images/ | Directory | Keep - used by documentation |
| releases/ | Directory | Keep - historical releases |
| templates/ | Directory | Keep - documentation templates |
| metadata.yml | Config | Keep - documentation metadata |
| scripts.xlsx | Data | Review - may be outdated |
| .DS_Store | System | Ignore |
| v1.0.0-release-plan.md | Planning | Keep - current release plan |

---

## Summary

| Category | Count | Action |
|----------|-------|--------|
| ✅ Keep & Update | 7 | Review and update for v1.0.0 |
| 🔄 Consolidate | 4 | Merge into core docs, then delete |
| 🗑️ Remove/Archive | 6 | Move to archive/ or delete |
| 📁 Keep As-Is | 4 dirs + 2 files | No changes needed |

**Total Files:** 18 markdown files  
**After Consolidation:** 7-8 markdown files (reduction of ~55%)

---

## Next Steps

1. **Create doc/archive/ directory** for historical docs
2. **Consolidate** the 4 files (CI, linting, extension docs)
3. **Archive** the 6 planning docs
4. **Update** the 7 core docs
5. **Create navigation** in README.md

---

## Consolidation Details

### 1. Merge ci_optimization.md → development.md

**Content to merge:**
- CI/CD pipeline setup
- GitHub Actions configuration
- Build optimization strategies
- Automated testing integration

**Target section:** "CI/CD and Automation" (create if doesn't exist)

### 2. Merge markdown-linting.md → development.md

**Content to merge:**
- Markdown linting setup
- markdownlint configuration
- Linting rules and rationale
- How to fix common issues

**Target section:** "Code Quality" or "Documentation Standards"

### 3. Merge extension-docs-* → extension-system.md

**Content to merge:**
- Implementation details from extension-docs-implementation.md
- Integration patterns from extension-docs-integration.md
- Create comprehensive extension development guide

**Target sections:**
- "Extension Implementation"
- "Extension Integration"
- "Extension Best Practices"

### 4. Archive planning docs

**Move to doc/archive/:**
- function-header-standardization.md (completed)
- legacy-code-analysis.md (historical)
- smart-test-selection.md (obsolete planning)
- structure.md (outdated)
- test-requirements.md (planning, key points extracted)
- version-management.md (strategy decided, now at v1.0.0)

---

**Status:** Inventory Complete  
**Next Task:** Create archive directory and begin consolidation
