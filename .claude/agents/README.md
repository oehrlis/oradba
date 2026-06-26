# OraDBA Framework Review - Claude Code Setup

Model-tiered, automation-first architecture and code review for the OraDBA Bash
framework (v0.24.11 -> v1.0.0). Analysis and planning only - no framework code is
modified. All output lands under `doc/review/`.

## Install

Files are placed at:

```
.claude/commands/framework-review.md     # orchestrator (the prompt)
.claude/agents/                           # 13 subagents (model-tiered)
```

Restart the Claude Code session after copying files to disk (subagents load at
session start). Run the main session on Opus, then:

```
/framework-review --from-scratch     # full run
/framework-review --resume           # resume from existing doc/review/ artifacts
```

## Model tiering (the "right model per task" mechanism)

Each subagent pins its model in YAML frontmatter. The orchestrator does not
override it. To hard-cap cost for a run, set `CLAUDE_CODE_SUBAGENT_MODEL` (forces
all subagents to one model) - but that defeats the tiering, so use only for
budget tests.

| Tier   | Agents                                                                 | Why |
|--------|------------------------------------------------------------------------|-----|
| haiku  | scan-inventory, scan-static, scan-tests                                | Deterministic data gathering, read-only, no judgment |
| sonnet | review-bash, review-testing, review-performance, review-deps, review-docs, review-release | Scoped domain analysis and synthesis |
| opus   | review-architecture, review-security, consolidate, roadmap            | High-judgment: design, threat modeling, conflict resolution, planning |

Orchestrator runs on the main session model (use Opus). Phase 1 and Phase 2 are
dispatched in parallel.

## Flow

```
Phase 0  Grounding (orchestrator/opus)
Phase 1  scans      (haiku, parallel)   -> doc/review/_scans/*
Phase 2  reviews    (opus+sonnet, par.) -> doc/review/findings/*
Phase 3  consolidate(opus)              -> consolidated-findings, debt, risk
         >>> HUMAN DECISION GATE 1
Phase 4  roadmap    (opus)              -> roadmap.md, clarifications.md
         >>> HUMAN DECISION GATE 2
Phase 5  assembly   (orchestrator/opus) -> REVIEW.md
```

`doc/review/roadmap.md` supersedes `.claude/review-plan.md`.

## Guarantees baked into the agents

- Read-only on framework code; writes only review artifacts.
- No installer execution, no full bats run, no privileged actions.
- Every finding carries `file:line` evidence; unverifiable items go to
  `clarifications.md`, never invented.
- All human questions consolidated in `clarifications.md` only.
- Markdown uses hyphen-minus only (no em-/en-dash).

## Tuning notes

- Tighten cost further: move `review-deps` and `review-docs` to haiku if your
  framework is small; keep architecture/security on opus.
- `effort:` frontmatter (low|medium|high|max) can be added per agent if you want
  to throttle reasoning depth independently of the model; left at default here.
- Add `permissionMode: plan` to any reviewer if you want a hard no-write guard
  beyond the tool allowlist.
