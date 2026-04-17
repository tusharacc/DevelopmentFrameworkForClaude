# Developer Artifact — git-mandatory-and-daily-skills

## Implementation Plan

7 changes across 7 files. All implemented.

## Files Changed

| File | Change |
|------|--------|
| `skills/new-feature/SKILL.md` | Added Step 0 (active workspace check); replaced Step 7 git section with `git status \|\| git init`; removed "skip silently" |
| `skills/upgrade-feature/SKILL.md` | Added Step 0 (active workspace check); added `git status \|\| git init` to Step 5 |
| `skills/bugfix/SKILL.md` | Added Step 0 (active workspace check); added `workflowType: "bugfix"` to state.json template; added `git status \|\| git init` to Step 6 |
| `skills/hotfix/SKILL.md` | Added Step 0 (active workspace check); added `git status \|\| git init` to Step 5 |
| `skills/minor-enhancement/SKILL.md` | Added Step 0 (active workspace check); added `git status \|\| git init` to Step 5 |
| `skills/end-of-day/SKILL.md` | Created — 7-step checkpoint write, commit, push |
| `skills/start-of-day/SKILL.md` | Created — reads checkpoint, presents it, resumes or routes to new work |

## Code Summary

**Git mandatory pattern** (identical across all 5 skills):
```bash
git status 2>/dev/null || git init
git checkout -b $BRANCH 2>/dev/null || git checkout $BRANCH
git add .dev-framework/
git commit -m "..."
```
`git status` is idempotent — succeeds on any existing repo, fails only on a non-repo directory, at which point `git init` runs once.

**Active workspace check pattern** (Step 0, identical across all 5 skills):
Scans `workspaces/*/state.json` for `status: active`. If found (and not the current slug), outputs a hard-stop message with three escape options: resume, archive, switch.

**Checkpoint format** (end-of-day output): structured markdown under 80 lines — Date, Workspace, Phase, Branch, Workflow, Done this session, Where things stand, Pending decisions, Next action.

**start-of-day resume flow**: reads checkpoint → presents it → on "continue" archives checkpoint to `.prev.md` and resumes current phase; on "new" archives and routes to workflow type selection.

## Decisions Made

- **Hard stop** (not warn) on concurrent active workspace — aligns with architect TD-1. Reviewer to confirm or soften.
- `workflowType: "bugfix"` added to bugfix SKILL.md as D-01 fix from previous workspace.
- Checkpoint archived to `.prev.md` on resume (not deleted) — one-session look-back preserved.
- Push in end-of-day is best-effort (`|| true`) — no failure if no remote.
