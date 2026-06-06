# Architect Artifact — assign-model-for-commands

## Overview
Pure frontmatter editing across 29 files. No logic changes, no new files, no scripts. The `model:` key is inserted after the `name:` line in each skill's frontmatter. For agents, the existing `model: sonnet` value is replaced where needed. All files already have valid `---` frontmatter delimiters.

## Component Map

### Agents — 3 value changes, 3 no-ops

| File | Change |
|---|---|
| `agents/architect-design.md` | `model: sonnet` → `model: opus` |
| `agents/developer-executor.md` | `model: sonnet` → `model: haiku` |
| `agents/tester-validation.md` | `model: sonnet` → `model: haiku` |
| `agents/po-requirements.md` | no change (already `sonnet`) |
| `agents/reviewer-quality.md` | no change (already `sonnet`) |
| `agents/observer-observability.md` | no change (already `sonnet`) |

### Skills — insert `model:` after `name:` line

**Haiku (20 skills):**
- `skills/start-of-day/skill.md`
- `skills/end-of-day/skill.md`
- `skills/status/skill.md`
- `skills/list-bugs/skill.md`
- `skills/list-workspaces/skill.md`
- `skills/view-bug/skill.md`
- `skills/switch-workspace/skill.md`
- `skills/new-feature/skill.md`
- `skills/hand-off/skill.md`
- `skills/handoff-orchestrator/skill.md`
- `skills/continue/skill.md`
- `skills/bugfix/skill.md`
- `skills/hotfix/skill.md`
- `skills/minor-enhancement/skill.md`
- `skills/upgrade-feature/skill.md`
- `skills/archive-feature/skill.md`
- `skills/framework-manager/skill.md`
- `skills/artifact-generator/skill.md`
- `skills/bug-manager/skill.md`
- `skills/create-bug/skill.md`

**Sonnet (3 skills):**
- `skills/explore/skill.md`
- `skills/init-brownfield/skill.md`
- `skills/observe/skill.md`

## Implementation Plan

### Step 1 — Update agents (3 edits)
For each agent needing a model change, use Edit to replace the `model:` line value. No structural changes.

### Step 2 — Update skills (23 edits)
For each skill, insert `model: <tier>` immediately after the `name: <slug>` line. The insertion pattern is identical for every skill — only the tier value differs. Edit tool, one file at a time.

### Step 3 — Verify
Run:
```bash
grep -rc "^model:" skills/ agents/
grep -r "^model:" skills/ agents/ | sort
```
Expected: 29 total hits (23 skills + 6 agents). Confirm tier distribution:
- `model: opus` → 1 (architect-design)
- `model: sonnet` → 6 (3 agents + 3 skills)
- `model: haiku` → 22 (3 agents + 20 skills... wait: 2 agents + 20 skills = 22)

Exact counts:
- `grep "model: opus"` → 1 line
- `grep "model: sonnet"` → 6 lines (po-requirements, reviewer-quality, observer-observability agents + explore, init-brownfield, observe skills)
- `grep "model: haiku"` → 22 lines (developer-executor, tester-validation agents + 20 skills)

### Step 4 — Commit
```
feat(assign-model-for-commands): assign model tiers to all skills and agents
```

## Risk Assessment

**Low risk overall.** No logic is touched. The only failure modes are:
- Inserting `model:` outside the frontmatter block — mitigated by always targeting the `name: <exact-slug>` line which is unambiguous in each file.
- Duplicate `model:` key if one already exists — mitigated by the audit confirming zero skills currently have `model:` in frontmatter.
- Agent files: the 3 no-change agents still need to be read to confirm their current value before skipping — do not blindly skip without verification.
