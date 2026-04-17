# Tester Artifact — mandatory-plugin-enforcement

## Test Plan
Validate that enforcement works at both layers (CLAUDE.md + hooks) across all workflow types, change-type routing, hand-off triggers, and phase gates.

---

## Test Cases

### Group A — Session Start Enforcement

**TC-01: Resume active workspace on session start**
- Setup: `.dev-framework/current-workspace` contains `my-feature`; `state.json` has `currentPhase: "developer"`, `status: "active"`
- Expected: Claude announces "Active workspace: **my-feature** | Phase: **developer**. Resuming." before responding to any request

**TC-02: Prompt for change type when no workspace exists**
- Setup: `.dev-framework/current-workspace` is empty or absent
- Action: User sends a development request ("add a login page")
- Expected: Claude asks "What type of work are you starting?" before doing anything

**TC-03: Prompt to archive when workspace is complete**
- Setup: `state.json` has `status: "complete"`
- Expected: Claude prompts to archive before allowing new work to begin

**TC-04: Graceful init when .dev-framework/ absent**
- Setup: No `.dev-framework/` directory
- Expected: Claude creates `.dev-framework/workspaces`, `artifacts`, `bugs`, `archived` then runs session start protocol

---

### Group B — Intent Detection and Workflow Routing

**TC-05: "fix X" routes to bugfix**
- Input: "fix the authentication timeout issue"
- Expected: Claude announces "Detected: bugfix. Starting bugfix workflow." and invokes `dev-framework:bugfix`

**TC-06: "add X" routes to new-feature**
- Input: "add a password reset flow"
- Expected: Claude announces "Detected: new-feature." and invokes `dev-framework:new-feature`

**TC-07: "production is down" routes to hotfix**
- Input: "production is down, the API is returning 500"
- Expected: Claude announces "Detected: hotfix." and invokes `dev-framework:hotfix`

**TC-08: "rename X" routes to minor-enhancement**
- Input: "rename the config key timeout to request_timeout"
- Expected: Claude announces "Detected: minor-enhancement." and invokes `dev-framework:minor-enhancement`

**TC-09: "rewrite X" routes to upgrade**
- Input: "rewrite the auth module for v2"
- Expected: Claude announces "Detected: upgrade." and invokes `dev-framework:upgrade-feature`

**TC-10: Ambiguous request prompts clarification**
- Input: "the login page looks off" (could be bug or minor enhancement)
- Expected: Claude asks one clarifying question before starting any workflow

---

### Group C — Phase Gate Enforcement

**TC-11: Code write blocked outside developer phase**
- Setup: Active workspace in `po` phase
- Action: User asks "write the database model"
- Expected: Claude declines — "The current phase is po. Writing code is only allowed in the developer phase."

**TC-12: Code write allowed in developer phase**
- Setup: Active workspace in `developer` phase
- Action: User asks "implement the user model"
- Expected: Claude proceeds with implementation

**TC-13: Phase skip declined**
- Input: "skip the review and move to testing"
- Expected: Claude declines — "The dev framework requires every phase to be completed. Phases cannot be skipped."

**TC-14: Review task blocked in developer phase**
- Setup: Active workspace in `developer` phase
- Action: User asks "review the code quality now"
- Expected: Claude declines — review is only permitted in the reviewer phase

---

### Group D — Hook: Write/Edit Gate

**TC-15: Write blocked outside developer phase**
- Setup: Current phase = `reviewer`; hook receives `{ "tool_name": "Write", "tool_input": { "file_path": "src/auth.py" } }`
- Expected: `check-phase.sh` exits 2 with message containing "BLOCKED" and current phase

**TC-16: Write allowed in developer phase**
- Setup: Current phase = `developer`
- Expected: `check-phase.sh` exits 0

**TC-17: Write to .dev-framework/ always allowed**
- Setup: Current phase = `tester`; file_path = `.dev-framework/artifacts/foo.tester.md`
- Expected: `check-phase.sh` exits 0 (framework files exempt)

**TC-18: Write to skills/ always allowed**
- Setup: Current phase = `po`; file_path = `skills/new-feature/SKILL.md`
- Expected: `check-phase.sh` exits 0

**TC-19: JSON with single quotes does not crash hook**
- Setup: `file_path` contains a single quote (e.g. `src/it's-a-file.py`)
- Expected: `check-phase.sh` handles it safely (no Python syntax error), exits 2 with block message

**TC-20: No workspace — hook allows all writes**
- Setup: `.dev-framework/current-workspace` absent
- Expected: `check-phase.sh` exits 0

---

### Group E — Hook: Bash Gate

**TC-21: Bash file-write blocked outside developer phase**
- Setup: Current phase = `reviewer`; command = `echo "x" > src/main.py`
- Expected: `check-bash-phase.sh` exits 2 with block message

**TC-22: Bash read-only command always allowed**
- Setup: Current phase = `po`; command = `cat src/main.py`
- Expected: `check-bash-phase.sh` exits 0

**TC-23: Bash write to .dev-framework/ always allowed**
- Setup: Current phase = `reviewer`; command = `echo "done" > .dev-framework/artifacts/x.md`
- Expected: `check-bash-phase.sh` exits 0

**TC-24: Bash allowed in developer phase**
- Setup: Current phase = `developer`; command = `sed -i 's/foo/bar/' src/config.py`
- Expected: `check-bash-phase.sh` exits 0

---

### Group E — Hand-off Trigger Vocabulary

**TC-25: "continue" triggers hand-off**
- Setup: Active workspace in `developer` phase with complete artifact
- Input: "continue"
- Expected: `dev-framework:continue` invoked; phase advances to `reviewer`

**TC-26: "done" triggers hand-off**
- Input: "done"
- Expected: Same as TC-25

**TC-27: "next step" triggers hand-off**
- Input: "next step"
- Expected: Same as TC-25

**TC-28: Hand-off blocked on incomplete artifact**
- Setup: Tester artifact contains `[To be filled]` sections
- Input: "continue"
- Expected: Claude outputs incomplete section list and does NOT advance phase

---

### Group F — Workflow Type Phase Chains

**TC-29: hotfix skips tester and executor**
- Setup: hotfix workspace; current phase = `reviewer`; reviewer approved (no high/medium issues)
- Action: hand-off
- Expected: next phase = `po-approval` (not `tester`)

**TC-30: minor-enhancement skips tester and executor**
- Setup: minor workspace; current phase = `reviewer`; approved
- Action: hand-off
- Expected: next phase = `po-approval`

**TC-31: bugfix includes tester and executor**
- Setup: bugfix workspace; current phase = `reviewer`; approved
- Action: hand-off
- Expected: next phase = `tester`

**TC-32: full workflow includes all phases**
- Setup: new-feature workspace; traverse po → architect → developer → reviewer → tester → executor → po-approval
- Expected: each hand-off lands on the correct next phase in sequence
