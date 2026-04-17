# Tester Artifact — git-mandatory-and-daily-skills

## Test Plan

Validate four areas: git mandatory enforcement, single active workspace blocking, end-of-day skill, start-of-day skill. Tests are written only — Executor runs them.

---

## Test Cases

### Group A — Git Mandatory

**TC-01: git init runs when no repo exists**
- Setup: directory with no `.git/` folder; `.dev-framework/` present with no active workspace
- Action: invoke `dev-framework:new-feature "test feature"`
- Expected: Step 8 runs `git status` (fails), then `git init` runs, then branch is created and commit made
- Verify: `.git/` directory exists after skill completes; `git log` shows one commit

**TC-02: git init is a no-op on existing repo**
- Setup: directory with an existing `.git/` repo
- Action: invoke `dev-framework:new-feature "test feature"`
- Expected: `git status` succeeds, `git init` is NOT run; branch created normally; no double-init side effects

**TC-03: git mandatory applies to all 5 workflow types**
- Action: invoke new-feature, upgrade-feature, bugfix, hotfix, minor-enhancement each in a fresh directory with no `.git/`
- Expected: each skill runs `git status 2>/dev/null || git init` before branch creation; all 5 produce a `.git/` directory and an initial commit

**TC-04: "skip silently" instruction absent from all skills**
- Action: read all 5 workflow SKILL.md files
- Expected: no occurrence of "skip silently" or "if git is not available or fails, skip" in any of them

---

### Group B — Single Active Workspace Enforcement

**TC-05: New feature blocked when active workspace exists**
- Setup: `.dev-framework/workspaces/my-feature/state.json` with `"status": "active"`, `"currentPhase": "developer"`
- Action: invoke `dev-framework:new-feature "another feature"`
- Expected: Claude outputs STOP message naming `my-feature` (phase: developer) and does NOT create any new workspace directories or artifacts

**TC-06: Hotfix blocked when active workspace exists**
- Setup: same as TC-05
- Action: invoke `dev-framework:hotfix "api is down"`
- Expected: STOP message; no new workspace created

**TC-07: Minor enhancement blocked when active workspace exists**
- Setup: same as TC-05
- Action: invoke `dev-framework:minor-enhancement "rename config key"`
- Expected: STOP message; no new workspace created

**TC-08: Bugfix blocked when active workspace exists**
- Setup: same as TC-05
- Action: invoke `dev-framework:bugfix BUG-002`
- Expected: STOP message; no new workspace created

**TC-09: Upgrade blocked when active workspace exists**
- Setup: same as TC-05
- Action: invoke `dev-framework:upgrade-feature "auth v2"`
- Expected: STOP message; no new workspace created

**TC-10: No block when no active workspace exists**
- Setup: all workspaces have `"status": "complete"` or `"archived"`; or no workspaces at all
- Action: invoke `dev-framework:new-feature "my feature"`
- Expected: proceeds normally with no STOP message

**TC-11: STOP message includes three escape options**
- Setup: active workspace exists
- Action: invoke any workflow skill
- Expected: output contains all three: "say continue", "/dev archive-feature", "/dev switch-workspace"

---

### Group C — End-of-Day Skill

**TC-12: Checkpoint written with all required sections**
- Setup: active workspace `my-feature` in `developer` phase; developer artifact exists with content
- Action: invoke `dev-framework:end-of-day`
- Expected: `.dev-framework/checkpoint.md` created containing: Date, Workspace, Phase, Branch, Workflow, "Done this session", "Where things stand", "Pending decisions", "Next action"

**TC-13: Checkpoint is under 80 lines**
- Setup: same as TC-12
- Action: invoke end-of-day
- Expected: `wc -l .dev-framework/checkpoint.md` returns ≤ 80

**TC-14: Checkpoint committed to git**
- Setup: existing git repo with active workspace
- Action: invoke end-of-day
- Expected: `git log --oneline -1` shows a commit with message matching `checkpoint: end-of-day YYYY-MM-DD`

**TC-15: Checkpoint pushed if remote exists**
- Setup: git repo with `origin` remote configured
- Action: invoke end-of-day
- Expected: `git push` is executed; no error if push succeeds

**TC-16: Push skipped gracefully if no remote**
- Setup: git repo with no remotes (`git remote` returns empty)
- Action: invoke end-of-day
- Expected: skill completes without error; no push attempted; checkpoint still written and committed

**TC-17: End-of-day with no active workspace**
- Setup: `.dev-framework/current-workspace` absent or empty
- Action: invoke end-of-day
- Expected: checkpoint.md written with "No active workspace at end of session. Nothing in progress." No git commit attempted for workspace state.

**TC-18: git log uses correct format (no --oneline)**
- Action: read `skills/end-of-day/SKILL.md`
- Expected: git log command is `git log --since="6am today" --format="%s"` — no `--oneline` flag present

---

### Group D — Start-of-Day Skill

**TC-19: Checkpoint presented correctly on start-of-day**
- Setup: `.dev-framework/checkpoint.md` exists with all sections
- Action: invoke `dev-framework:start-of-day`
- Expected: checkpoint content displayed in formatted block; question asked: "Ready to continue $workspace (phase: $phase)? Or start something new?"

**TC-20: Checkpoint archived on resume**
- Setup: checkpoint exists; user responds "continue"
- Action: invoke start-of-day, respond "continue"
- Expected: `checkpoint.md` renamed to `checkpoint.prev.md`; git commit with message `checkpoint: start-of-day resume YYYY-MM-DD`; current workspace state read and phase announced

**TC-21: Checkpoint archived on "start something new"**
- Setup: checkpoint exists; user responds "new"
- Action: invoke start-of-day, respond "new"
- Expected: `checkpoint.md` renamed to `checkpoint.prev.md`; git commit made; user asked "What type of work are you starting?"

**TC-22: Falls back to session start protocol when no checkpoint**
- Setup: `.dev-framework/checkpoint.md` absent; `.dev-framework/current-workspace` contains active workspace
- Action: invoke start-of-day
- Expected: announces "Active workspace: $SLUG | Phase: $phase. Resuming." (session start protocol behaviour)

**TC-23: Falls back to type question when no checkpoint and no workspace**
- Setup: no checkpoint; no current-workspace
- Action: invoke start-of-day
- Expected: asks "What type of work are you starting?"

**TC-24: Stale checkpoint age noted**
- Setup: checkpoint.md with Date line showing 5 days ago
- Action: invoke start-of-day
- Expected: output includes "This checkpoint is from $DATE (5 days ago)" before presenting checkpoint contents

---

### Group E — bugfix workflowType fix (D-01)

**TC-25: bugfix state.json includes workflowType field**
- Action: read `skills/bugfix/SKILL.md`; find the state.json template
- Expected: template contains `"workflowType": "bugfix"`

**TC-26: bugfix hand-off routes correctly after reviewer**
- Setup: bugfix workspace; `state.json` has `workflowType: "bugfix"`, `currentPhase: "reviewer"`; reviewer artifact shows no high/medium issues
- Action: hand-off
- Expected: next phase = `tester` (not `po-approval`)
