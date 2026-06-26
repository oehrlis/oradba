# Risk Register - OraDBA v0.24.11

**Generated:** 2026-06-26 **Basis:** consolidated-findings.md (CF-NNN) and the 8 domain reviews
**Target:** v1.0.0 stable

Risk level is derived from Likelihood x Impact:

- High x High = Critical
- High x Medium or Medium x High = High
- Medium x Medium, High x Low, Low x High = Medium
- otherwise = Low

Owner-type: maintainer (code/architecture decision), release-eng (pipeline/process), security
(threat-model owner), docs (documentation owner). These are role hints, not individuals.

<!-- markdownlint-disable MD013 MD060 -->

| ID | Title | Source findings | Likelihood | Impact | Risk level | Mitigation | Owner-type | Residual risk |
|----|----|----|----|----|----|----|----|----|
| RISK-01 | Operational: control scripts abort silently on first normal operation due to zero-start `(( counter++ ))` under set -e | CF-001 / BASH-001 to BASH-006, BASH-014 | High | High | Critical | Apply \` |  | true`/`var=\$((var+1))`at all from-zero increments; add CI lint flagging standalone`(( var++ ))\` (RISK-13); regression tests per testing review |
| RISK-02 | Security: SYS/SYSTEM passwords exposed in predictable world-readable `/tmp` DBCA response file, persisted on failure | CF-002 / SEC-01 | Medium | High | High | `mktemp` 700 dir, `chmod 600` before writing, `trap EXIT` shred on all paths, prefer stdin to DBCA; remove failure-preservation of secret file | security | Low after fix; residual limited to shared-host operator-group exposure if 027 umask retained |
| RISK-03 | Security: malicious payload executes at root/oracle via unverified installer download or curl-pipe-bash | CF-006 / SEC-03, SEC-04, DEP-008, DEP-012 | Low | High | Medium | Verify companion `.sha256` before extraction, fail closed without a verify tool, make verified two-step the documented default, sign releases with pinned key | security | Medium until signing exists - checksum protects integrity but not authenticity of a compromised release account |
| RISK-04 | Architecture: cross-plugin contamination from 9 direct-source sites bypassing the isolation wrapper | CF-004 / ARCH-002, ARCH-011 | Medium | High | High | Make `execute_plugin_function_v2` the sole sanctioned entry for state-changing calls; audit/wrap each direct-source site; remove dead fallback (DECISION-REQUIRED reconciliation with fork cost) | maintainer | Medium until the pure-vs-risky function classification is decided and enforced |
| RISK-05 | Architecture/config: installation path defects recur where `ORADBA_BASE` and `ORADBA_PREFIX` diverge (plugin/oratab/config look in different trees) | CF-007 / ARCH-003 | High | Medium | High | Canonicalize on `ORADBA_BASE`, deprecate `ORADBA_PREFIX` as alias for one release, introduce shared bootstrap snippet resolving root from BASH_SOURCE | maintainer | Low after canonicalization; alias shim covers downstream consumers |
| RISK-06 | Quality: path-critical validator/env-builder/home-discovery functions regress silently (no behavioral coverage) | CF-008 / F-007 to F-011, F-014 | Medium | High | High | Add behavioral tests with mock Oracle-home fixtures for the build/validate/discovery path; add missing files to `.testmap.yml`; land tests on the path actually shipped (see RISK-08) | maintainer | Medium until coverage lands; testmap gaps otherwise disable CI smart-selection |
| RISK-07 | Quality: the six recent shipped defects recur because no regression test exists and the suite is happy-path biased (13:1) | CF-009 / F-001 to F-006, F-013 | Medium | High | High | Implement the named regression tests from the testing review; set a minimum error-path ratio (15%); add the arithmetic lint guard | maintainer | Low after the named tests exist; ongoing discipline needed to hold the ratio |
| RISK-08 | Architecture: maintaining two parallel env-build paths splits effort and ships ambiguous public API at v1.0.0 | CF-017 / ARCH-004, P-01, F-008 | High | Medium | High | DECISION-REQUIRED: complete migration to `oradba_build_environment` or explicitly demote it to alternate API and remove from public docs before v1.0.0 | maintainer | Medium until decided; the decision gates RISK-06 test targeting |
| RISK-09 | Release: artifacts ship with wrong version because the pipeline does not assert VERSION == git tag | CF-010 / RF-02 | Medium | High | High | Add \`\[ "$`(cat VERSION)" = "`${GITHUB_REF#refs/tags/v}" \] |  | exit 1`before build; mirror in`make release-check\` |
| RISK-10 | Release: a defective build reaches users because Docker integration tests are manual-only and the test gate treats bats exit 1 as success | CF-019, CF-027 / RF-03, RF-11, RF-01 | Medium | High | High | Wire a scheduled/required Docker integration run before release tags; parse TAP to distinguish failed from skipped tests; add an RC/freeze window for v1.0.0 | release-eng | Medium until both the integration gate and the TAP parsing are in place |
| RISK-11 | Portability: silent failures on macOS/BSD (the declared default target) from GNU-only tools and missing bash version guard | CF-011, CF-012 / DEP-001, DEP-002, DEP-004, DEP-005, BASH-010 to BASH-012 | High | Medium | High | Replace GNU-only flags with `df -k`/`shasum` fallbacks/`realpath` fallback; add bash 4+ startup guard; document Homebrew bash; add a macOS CI lane | maintainer | Low after fixes; residual on untested exotic BSD variants |
| RISK-12 | Operational: scripts abort with unhelpful "command not found" when Oracle/system CLI tools are absent (no pre-flight check) | CF-013 / DEP-003, DEP-006 | Medium | Medium | Medium | Add `command -v` / `-x` pre-flight checks following the `oradba_dbca.sh:223` pattern in dbctl, rman, lsnrctl, and sync scripts | maintainer | Low after checks added |
| RISK-13 | Process: the recurring defect classes (arithmetic-exit, formatting, tool-version skew) reappear without a CI lint/format guard | CF-009 (F-006), CF-034 / RF-04, RF-05, RF-13 | High | Medium | High | Add a CI lint rule for standalone `(( var++ ))`, add shfmt format-check, pin shellcheck in release.yml, wire a pre-push hook running `make lint` | release-eng | Low after guards added; this is the systemic preventive control for RISK-01/RISK-07 |
| RISK-14 | Security: wallet/catalog/SYS credentials recovered or exposed via reversible base64 file, cleartext logs, and process arguments | CF-020, CF-021 / SEC-02, SEC-05, SEC-08 | Medium | Medium | Medium | Refuse to read non-600 `.wallet_pwd` (or drop base64 mechanism), never log recovered passwords, pass catalog creds inside the restricted `.rcv` body or via SEPS alias, prefer stdin for dbca passwords | security | Medium - depends on deployment file permissions and operator log handling |
| RISK-15 | Security: code execution via `eval` on oratab/homes fields, and TOCTOU on predictable PID-based temp paths | CF-022, CF-023 / SEC-06, SEC-07, BASH-016, BASH-018 | Low | High | Medium | Replace `eval` with namerefs or strict allowlist validation; use `mktemp -d` with exclusive create and ownership check; register EXIT-trap cleanup | security | Medium - exploitability hinges on group-write permissions of oratab/homes files in supported configs |
| RISK-16 | Performance/UX: every env switch (and every login/pane/window) pays a large fixed cost from eager sourcing, double config load, and per-switch sqlplus spawns | CF-014, CF-015, CF-016 / P-01, P-02, P-13, P-03 to P-12 | High | Low | Medium | Gate `generate_pdb_aliases` behind alias flags + per-SID session guard (CF-015 is a v1.0.0 blocker); lazy-load path-specific libraries; remove double config load; replace subshell idioms with bash built-ins and caching | maintainer | Low for correctness; performance debt (RISK deferrable) mostly to v1.1.0 except the sqlplus gating |
| RISK-17 | Adoption/trust: documentation is broadly inaccurate at v1.0.0 (wrong Registry API schema/functions, stale versions and counts) | CF-024, CF-025 / DOC-001 to DOC-011, DOC-016, F-015 | High | Medium | High | Correct Registry API docs (delimiter, 8-field schema, real vs phantom functions); build-inject script versions; add `make validate-docs-counts` and a testmap-count CI check | docs | Low after corrections + automated count validation |
| RISK-18 | Supply-chain: release artifacts silently altered by mutable Docker tags, unpinned third-party actions, or unverified build downloads | CF-028 / DEP-009, DEP-010, DEP-011, DEP-014, RF-10 | Low | Medium | Low | Pin Docker images by digest, third-party actions by commit SHA, packages by version; checksum-verify the extension-template download; pin a `ref:` per extensions.yml entry | release-eng | Medium until pinning is complete - pipeline holds contents:write |
| RISK-19 | Process: v1.0.0 declared without an objective readiness bar; breaking changes ship without deprecation warnings | CF-034 / RF-01, RF-12, RF-14 | Medium | Medium | Medium | Author `doc/v1.0.0-readiness.md` with explicit criteria; add runtime deprecation warnings for v0.20.0 breaking renames; define the stability contract and a soak period | release-eng | Medium until the readiness doc and deprecation warnings exist |

<!-- markdownlint-enable MD013 MD060 -->

----------------------------------------------------------------------------------------------------

## Risk-level summary

| Risk level | Count | IDs |
| ---- | ---- | ---- |
| Critical | 1 | RISK-01 |
| High | 11 | RISK-02, RISK-04, RISK-05, RISK-06, RISK-07, RISK-08, RISK-09, RISK-10, RISK-11, RISK-13, RISK-17 |
| Medium | 6 | RISK-03, RISK-12, RISK-14, RISK-15, RISK-16, RISK-19 |
| Low | 1 | RISK-18 |

Total: 19 risks.

The most leveraged single mitigation is RISK-13 (CI lint/format/pin/hook guards): it is the systemic
preventive control that stops the RISK-01 and RISK-07 defect classes from recurring after they are
fixed. The highest acute exposure is RISK-01 (Critical - fires on first normal operation) and
RISK-02 (credential exposure on shared hosts).
