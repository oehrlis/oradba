# Lessons Learned — oradba

## L1: set -e Exit Code Capture

Pattern: `cmd; var=$?` fails under `set -e` — the script exits before the assignment.
Fix: `cmd || var=$?`

**Why:** Three separate corrections across rc.3, rc.4, rc.5 in `oradba_dsctl.sh`
`execute_plugin_function_v2` call sites.

**How to apply:** Any command where the exit code must be captured for logic.

verify: look for plugin/function calls on one line followed by `var=$?` on the next

[promoted → rule: ai-toolkit/claude/rules/shell-scripts.md]

---

## L2: Bash Indirect Expansion Safety

Pattern: `${!var}` throws "unbound variable" under `set -u` when the variable named by
`var` is not in the environment.
Fix: `${!var:-}` — returns empty string; detection logic (e.g. `[[ -z … ]]`) still works.

**Why:** Caused `extensions.sh` info/list crash, `oradba_setup.sh` silent failure,
`oradba_common.sh` crash in verify_oracle_env.

**How to apply:** Any indirect expansion, especially config/extension property lookups
and environment variable presence checks.

verify: `grep -rn '\${!' src/ --include="*.sh" | grep -v ':-\|-}' | grep -v '#'`

[promoted → rule: ai-toolkit/claude/rules/shell-scripts.md]

---

## L3: Release Notes File Required Before Tagging

Pattern: GitHub Release workflow fails if `doc/releases/v<VERSION>.md` does not exist.
Fix: create the file before running `git tag v<VERSION>`.

**Why:** Workflow validates file existence; missing file → release pipeline failure.

**How to apply:** Before any `git tag v*` command in oradba.

verify: `ls doc/releases/v$(cat VERSION).md`

[promoted → rule: oradba/CLAUDE.md]

---

## L4: Subagent Worktree Verification

Pattern: Subagent silently reverted a verified fix (rc.4 "already started" → "started").
Fix: always `git diff main -- <file>` on every file the subagent claims to have changed.

**Why:** Two instances of silent regression introduction by subagents operating on
overlapping files.

**How to apply:** After any subagent completes code changes, before reporting done.

verify: `git diff HEAD~1 -- <changed-file>` shows expected changes only

[promoted → rule: ai-toolkit/claude/rules/claude-code.md]
