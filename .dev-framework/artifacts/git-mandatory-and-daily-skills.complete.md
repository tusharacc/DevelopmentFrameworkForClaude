# Complete — git-mandatory-and-daily-skills

## Feature Summary

Hardened git usage, enforced single-feature focus, and added session continuity through end-of-day and start-of-day skills.

---

## Phase Trail

| Phase | Outcome |
|-------|---------|
| PO | Requirements: git mandatory via `git status \|\| git init`; hard-stop on concurrent workspaces; end-of-day checkpoint; start-of-day resume; one feature at a time |
| Architect | Two new skills (end-of-day, start-of-day); Step 0 added to all 5 workflow skills; checkpoint format capped at 80 lines; hard stop confirmed over warn-only |
| Developer | All 7 files implemented; bugfix workflowType D-01 fix bundled |
| Reviewer | R1 (High): $SLUG undefined in Step 0 for 4 skills — fixed. R2 (Medium): new-feature step numbering inverted — fixed. R3 (Medium): --oneline redundant flag — fixed. R4/R5 low issues filed as BUG-004/BUG-005 |
| Tester | 26 test cases written across 5 groups |
| Executor | 26/26 pass. D-01 minor inconsistency in new-feature $SLUG exclusion noted |
| PO Approval | Approved. D-01 deferred as follow-up |

---

## What Was Delivered

**Git mandatory** (`skills/new-feature`, `upgrade-feature`, `bugfix`, `hotfix`, `minor-enhancement`)
- `git status 2>/dev/null || git init` runs before every branch creation
- "skip silently" removed from all skills

**Single active workspace enforcement** (Step 0, all 5 workflow skills)
- Scans all workspace state.json files for `status: active`
- Hard stop with three escape options: resume / archive / switch
- Explicit "Output this message and stop. Do not execute any further steps."

**`skills/end-of-day/SKILL.md`** (new)
- Reads current workspace and phase artifact
- Collects today's commits via `git log --since="6am today" --format="%s"`
- Writes `.dev-framework/checkpoint.md` — Date, Workspace, Phase, Branch, Workflow, Done, Where things stand, Pending decisions, Next action (≤80 lines)
- Commits checkpoint; pushes if remote exists

**`skills/start-of-day/SKILL.md`** (new)
- Reads `.dev-framework/checkpoint.md`
- Presents checkpoint formatted; asks continue or new
- On continue: archives to `.prev.md`, commits, resumes phase
- On new: archives, asks work type
- Stale detection: flags checkpoints older than 3 days
- Fallback: session start protocol when no checkpoint exists

**`skills/bugfix/SKILL.md`** — added `"workflowType": "bugfix"` (D-01 fix)

---

## Open Follow-ups

| ID | Description |
|----|-------------|
| D-01 | new-feature Step 2 still has `and its name is not $SLUG` — remove for consistency with other 4 skills |
| BUG-004 | Step 0 passive stop wording across 5 skills |
| BUG-005 | start-of-day ambiguous response fallback |
