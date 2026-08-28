# Self-Evolving System — oradba

Last evolve run: 2026-07-03

## History

<!-- markdownlint-disable MD013 MD060 -->
| Date | Corrections reviewed | Promotions | Verify checks | Result |
|------|---------------------|------------|---------------|--------|
| 2026-07-03 | 7 | 4 | 5 (4 PASS, 1 FAIL fixed) | Bootstrap; 2 violations fixed |
<!-- markdownlint-enable -->

## Promoted Rules

<!-- markdownlint-disable MD013 MD060 -->
| Lesson | Target | Date |
|--------|--------|------|
| L1: set -e exit code | ai-toolkit/claude/rules/shell-scripts.md (v0.5.0) | 2026-07-03 |
| L2: indirect expansion | ai-toolkit/claude/rules/shell-scripts.md (v0.5.0) | 2026-07-03 |
| L3: release notes file | oradba/CLAUDE.md | 2026-07-03 |
| L4: subagent verify | ai-toolkit/claude/rules/claude-code.md (v0.4.0) | 2026-07-03 |
<!-- markdownlint-enable -->

## Next evolve

Suggested after 10+ more sessions or when a new pattern appears 2+ times.

## Evolve runs

- 2026-08-28: run in `oradba`. 7 corrections reviewed (all already resolved),
  4 lessons verified: 2 PASS, 1 N/A, **2 FAIL** with live defects (L1 in the
  systemd entry point, L2 in `oraenv.sh`). 5 new lessons proposed (L5-L9),
  2 rule promotions proposed for ai-toolkit.
  Output: `tasks/evolve-promotions.md`.
