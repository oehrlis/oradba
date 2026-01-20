# Archived Documentation

This directory contains historical and temporary documentation that was useful
during development but is no longer needed for v0.19.0+ release.

## Archived Files

### Legacy API Documentation

- **api_v1.0.0_legacy.md** - Original API documentation with v1.0.0/basenv references (superseded by complete rewrite for v0.19.0+)

### Legacy Analysis and Inventory

- **code_analysis_report.md** - Historical code analysis from v1.0.0 preparation (pre-v0.19.0 architecture)
- **functions_inventory.md** - Function inventory from v1.0.0 era (outdated after Registry API and Plugin System)
- **scripts.xlsx** - Script inventory spreadsheet (historical reference)

### Release Planning (v1.0.0 Era)

- **v1.0.0-release-plan.md** - Original v1.0.0 release planning (superseded by v0.19.0+ architecture)
- **release-testing-checklist.md** - Pre-release testing checklist (historical)

### Planning Documents (Phase 5 Development)

- **function-header-standardization.md** - Phase 5.3/5.4 planning for function header updates (completed)
- **test-requirements.md** - Test planning and requirements (key points integrated into development.md)
- **smart-test-selection.md** - Test optimization strategy planning (superseded by actual implementation)
- **version-management.md** - Version strategy planning (decided: v0.19.0+ approach)

### Historical Analysis

- **legacy-code-analysis.md** - Analysis of old codebase before Phase 1-4 rewrite (historical reference)
- **structure.md** - Old project structure documentation (outdated after v0.19.0+ changes)
- **oradba-env-design-old.md** - Original environment design (superseded by v0.19.0+ Registry API)

### Detailed Implementation Docs (Consolidated)

- **ci_optimization.md** - CI/CD optimization details (covered in development.md)
- **markdown-linting.md** - Markdown linting setup (covered in development.md)
- **extension-docs-implementation.md** - Extension implementation details (covered in extension-system.md)
- **extension-docs-integration.md** - Extension integration patterns (covered in extension-system.md)

### Completed Phase Reports (v1.0.0 Preparation)

- **phase2-user-docs-plan.md** - Phase 2: User Documentation Review (completed 2026-01-14)
- **phase4_code_quality_report.md** - Phase 4: Code Quality & Standards (completed 2026-01-14)
- **phase5_changelog_report.md** - Phase 5: CHANGELOG Consolidation (completed 2026-01-14)
- **phase6_readme_report.md** - Phase 6: README & Main Docs (completed 2026-01-14)
- **phase7_preparation_report.md** - Phase 7: Testing preparation
- **phase7_manual_testing_guide.md** - Phase 7: Manual testing guide
- **phase8_github_issues.md** - Phase 8: GitHub issues tracking
- **post_v1.0.0_issues.md** - Post-release issue tracking

## Why Archived?

These documents were valuable during development phases but are no longer relevant for:

- Current development (v0.19.0+)
- New contributors
- User documentation
- Maintenance

Core concepts have been integrated into main documentation. These are preserved here for historical reference only.

## v0.19.0+ Architecture Changes

The transition to v0.19.0+ brought significant architectural changes:
- **Registry API** - Unified interface for all Oracle installations
- **Plugin System** - 6 product-specific plugins (database, datasafe, client, iclient, oud, java)
- **No Backward Compatibility** - Clean removal of basenv coexistence mode
- **Complete Documentation Rewrite** - All documentation updated to reflect new architecture

Documents referencing v1.0.0, basenv coexistence, or outdated architectures have been archived here.

---

**Last Updated:** 2026-01-20  
**OraDBA Version:** v0.19.0+
