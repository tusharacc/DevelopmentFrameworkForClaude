# Complete — mandatory-plugin-enforcement

## Feature Summary

Hardened the dev framework so it is followed without exception in every Claude Code session. Every development task in this repository now goes through the correct workflow automatically — no manual slash commands required.

---

## Phase Trail

| Phase | Outcome |
|-------|---------|
| PO | Requirements gathered: mandatory session enforcement, intent detection, 5 workflow types, 2-layer phase gates, hand-off vocabulary, reviewer severity branching |
| Architect | Two-layer design: CLAUDE.md (conversational) + hooks (tool-level). workflowType field as single source of truth for phase sequencing. |
| Developer | CLAUDE.md, hooks/hooks.json, check-phase.sh, check-bash-phase.sh, skills/continue, skills/hand-off, skills/hotfix, skills/minor-enhancement updated. All reviewer issues fixed. |
| Reviewer | 6 issues found (1 high, 3 medium, 2 low). All resolved before hand-off. |
| Tester | 32 test cases written across session start, intent routing, phase gates, Write/Edit hook, Bash hook, hand-off triggers, workflow chains. |
| Executor | 32/32 tests pass. 2 minor non-blocking defects noted (D-01: missing workflowType in bugfix skill; D-02: install pattern over-breadth). |
| PO Approval | Approved. D-01 deferred as follow-up minor enhancement. |

---

## What Was Delivered

**`CLAUDE.md`** (auto-loaded every session)
- Session start protocol: reads current workspace, announces phase, or prompts for work type
- Intent classifier: routes plain-language requests to the correct workflow without slash commands
- Phase gate table: defines what Claude may/may not do in each phase
- Hand-off trigger vocabulary: "continue", "done", "next step", etc. all invoke `dev-framework:continue`
- Workflow phase chains for all 5 types
- Artifact verification rules before hand-off
- Reviewer severity branching rules
- PO approval rules
- Graceful init if `.dev-framework/` is absent

**`hooks/hooks.json`**
- PreToolUse hook on Write/Edit → `check-phase.sh`
- PreToolUse hook on Bash → `check-bash-phase.sh`

**`hooks/check-phase.sh`**
- Blocks Write/Edit to source files outside developer phase
- Exempts `.dev-framework/`, `CLAUDE.md`, `hooks/`, `skills/`, `agents/`, `.claude`
- Reads JSON via stdin (no shell-interpolation vulnerability)

**`hooks/check-bash-phase.sh`**
- Blocks file-writing Bash patterns (`>`, `tee`, `sed -i`, `cp`, `mv`, `rm`, etc.) outside developer phase
- Same exemptions as check-phase.sh

**`skills/continue/SKILL.md`**
- Broad description ensures Claude auto-invokes on all hand-off trigger words
- Verifies artifact completeness before advancing
- Reads workflowType for workflow-aware phase sequencing

**`skills/hand-off/SKILL.md`**
- Phase chains driven by workflowType (full / bugfix / hotfix / minor)
- Reviewer branching: high/medium → developer; low → file bugs + advance
- Audit trail: revisited phases append `_start_2`, `_start_3` timestamps

**`skills/hotfix/SKILL.md`**
- workflowType: "hotfix" — Developer → Reviewer → PO Approval → Complete

**`skills/minor-enhancement/SKILL.md`**
- workflowType: "minor" — Developer → Reviewer → PO Approval → Complete

**`skills/new-feature/SKILL.md`**, **`skills/upgrade-feature/SKILL.md`**
- Added explicit `"workflowType": "full"` to state.json templates

---

## Known Follow-up

**D-01**: Add `"workflowType": "bugfix"` to `skills/bugfix/SKILL.md` state.json template. File as minor enhancement.
