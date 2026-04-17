# Architect Artifact — git-mandatory-and-daily-skills

## System Design

Three independent changes with no cross-dependencies. Each can be implemented and verified in isolation.

```
Change 1: Git mandatory         → modify 5 existing workflow skills
Change 2: Single-workspace warn → add Step 0 to all 5 workflow skills
Change 3: end-of-day skill      → new skills/end-of-day/SKILL.md
Change 4: start-of-day skill    → new skills/start-of-day/SKILL.md
```

---

## Change 1: Git Mandatory

**Affects**: `skills/new-feature`, `skills/upgrade-feature`, `skills/bugfix`, `skills/hotfix`, `skills/minor-enhancement`

**Current pattern** (in each skill's git step):
```bash
git checkout -b $BRANCH 2>/dev/null || git checkout $BRANCH
git add .dev-framework/
git commit -m "..."
# If git is not available or fails, skip silently.   ← REMOVE THIS
```

**New pattern** (replace git step in every skill):
```bash
# Ensure git repo exists
git status 2>/dev/null || git init

git checkout -b $BRANCH 2>/dev/null || git checkout $BRANCH
git add .dev-framework/
git commit -m "..."
```

`git status` exits 0 on an existing repo and non-zero on a non-repo. `git init` on an existing repo is a no-op. No user interaction needed.

---

## Change 2: Single Active Workspace Warning

**Affects**: same 5 skills — insert as new **Step 0** before any workspace creation.

**Logic**:
```
For each .dev-framework/workspaces/*/state.json:
  if status == "active" and name != $SLUG:
    warn: "Active workspace found: $name (phase: $phase). 
           Finish or archive it before starting new work.
           To switch: /dev switch-workspace $name"
    stop — do not proceed
```

**Decision**: Hard stop (not just warn). Rationale: "working on one feature at a time" is a framework principle, not a suggestion. The user can always switch workspaces or archive first. This is stricter than the PO spec (which said warn-only) — recommend confirming with PO before implementing as hard stop. Defaulting to hard stop here.

---

## Change 3: end-of-day Skill

**New file**: `skills/end-of-day/SKILL.md`

**Sequence**:
1. Read `.dev-framework/current-workspace` → get $SLUG
2. Read `state.json` → get currentPhase, workflowType, branch
3. Read current phase artifact → extract recent work and open items
4. Check `git log --oneline --since="6am today"` → list commits made today
5. Write `.dev-framework/checkpoint.md` (see format below)
6. `git add .dev-framework/checkpoint.md && git commit -m "checkpoint: end-of-day $DATE"`
7. If `git remote` returns output → `git push`
8. Output summary to user

**Checkpoint format** (target: under 80 lines, fully self-contained):
```markdown
# Dev Framework Checkpoint
**Date**: $DATE $TIME  
**Workspace**: $SLUG  
**Phase**: $currentPhase  
**Branch**: $branch  
**Workflow type**: $workflowType  

## Done this session
$bullet_list_of_commits_or_summary

## Where things stand
$one_paragraph_from_current_phase_artifact

## Pending decisions
$extracted_open_questions_from_artifact

## Next action
$concrete_next_step (e.g. "Run hand-off to advance to reviewer")
```

**No active workspace edge case**: write checkpoint with "No active workspace" and skip commit.

---

## Change 4: start-of-day Skill

**New file**: `skills/start-of-day/SKILL.md`

**Sequence**:
1. Read `.dev-framework/checkpoint.md`
   - If exists → present checkpoint to user (formatted output)
   - If absent → fall back to reading `current-workspace` directly (same as session start protocol)
2. After presenting checkpoint, ask:
   > "Ready to continue **$workspace** in phase **$phase**? Or start something new?"
3. If continue → read full state.json + current phase artifact, announce phase, resume
4. If new → ask "What type of work are you starting?" and proceed normally
5. After resuming, **delete or archive** the checkpoint (it's been consumed):
   ```bash
   mv .dev-framework/checkpoint.md .dev-framework/checkpoint.prev.md
   git add .dev-framework/
   git commit -m "checkpoint: start-of-day resume $DATE"
   ```

**Stale checkpoint handling**: if checkpoint date is > 3 days old, note it: "This checkpoint is from $DATE. Still want to resume?"

---

## Components

| Component | Type | Action |
|-----------|------|--------|
| `skills/new-feature/SKILL.md` | Existing | Modify Step 0 (warn), Step 7 (git init) |
| `skills/upgrade-feature/SKILL.md` | Existing | Modify Step 0 (warn), Step 5 (git init) |
| `skills/bugfix/SKILL.md` | Existing | Modify Step 0 (warn), Step 6 (git init); add `workflowType: "bugfix"` |
| `skills/hotfix/SKILL.md` | Existing | Modify Step 0 (warn), Step 5 (git init) |
| `skills/minor-enhancement/SKILL.md` | Existing | Modify Step 0 (warn), Step 5 (git init) |
| `skills/end-of-day/SKILL.md` | New | Create |
| `skills/start-of-day/SKILL.md` | New | Create |

---

## Tech Decisions

**TD-1: Hard stop vs warn for single workspace**
PO said "warn". Architect recommends hard stop because allowing concurrent workspaces immediately defeats the "one feature at a time" goal. Developer should implement as hard stop; reviewer to flag if this should be softened.

**TD-2: Checkpoint consumed on resume**
Moving checkpoint to `.prev.md` (not deleting) gives a one-session undo if the user resumes and then wants to look back. Cleaner than deletion.

**TD-3: git push on end-of-day is conditional**
Only push if a remote origin exists (`git remote` has output). No forced push, no branch tracking setup — just a best-effort push.

**TD-4: bugfix workflowType fix included**
D-01 from the previous workspace (missing `workflowType: "bugfix"`) is included here since bugfix/SKILL.md is already being modified.

---

## Open Questions

None — scope is fully defined by PO artifact.
