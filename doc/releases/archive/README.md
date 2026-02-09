# Archived Release Notes

This directory contains archived release notes for OraDBA versions before v0.19.0's architecture refactoring.

## Current Release

- **[v0.19.0](../v0.19.0.md)** - Architecture Refactoring (2026-01-21)
  - Registry API: Unified installation management
  - Plugin System: 9 product types with standardized interface (11 required functions)
  - Environment Builder: 6 specialized environment libraries
  - Complete test coverage: 1452 tests (100% passing)
  - Full documentation: 437 functions (100% documented)

## Archived Releases

### Consolidated Historical Releases

- **[Consolidated v0.10.0 - v0.18.5](consolidated-v0.10.0-v0.18.5.md)** - Major milestone releases
  - v0.18.5 (2026-01-13): Pre-1.0 final release
  - v0.18.0 (2026-01-10): Oracle Homes support
  - v0.17.0 (2026-01-09): Pre-Oracle installation support
  - v0.15.0 (2026-01-07): Extension system enhancements
  - v0.14.0 (2026-01-05): Critical RMAN bug fix + features
  - v0.13.0 (2026-01-02): RMAN wrapper script
  - v0.12.0 (2026-01-02): Extension system
  - v0.10.0 (2026-01-01): Enterprise service management & smart testing

### Complete Release History

For complete release history including all patch releases:

- **[CHANGELOG.md](../../CHANGELOG.md)** - Detailed change log with all versions
- **[GitHub Releases](https://github.com/oehrlis/oradba/releases)** - All releases with downloads and assets

## Historical Context

OraDBA v0.19.0 represents a complete architectural rewrite. Earlier releases
(v0.2.0 - v0.18.5) used a different architecture and are maintained for
historical reference only. The consolidated document preserves the evolution of
OraDBA through multiple major milestones.

**Key Architectural Changes in v0.19.0:**

- **Before**: Direct oratab parsing + mixed product handling
- **After**: Registry API + Plugin System with standardized interfaces

## Git Tags

All git tags remain available for historical reference and checkout:

- Use `git tag -l` to list all tags
- Use `git checkout v0.XX.X` to checkout specific versions
- See [GitHub Releases](https://github.com/oehrlis/oradba/releases) for tag-based releases
