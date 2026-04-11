# Tester Artifact — BUG-001

## Test Plan
Validate that the phase chain in `hand-off/SKILL.md` correctly sequences all phases, that reviewer branching works per severity, and that low-priority comments are filed as bugs.

---

## Test Cases

### TC-01: Developer → Reviewer transition
**Input**: Workspace in `developer` phase with a complete developer artifact (>10 lines)
**Action**: Run `/dev hand-off`
**Expected**: Phase advances to `reviewer`; reviewer artifact template created; reviewer agent is invoked

### TC-02: Reviewer → Developer loop (high/medium issues)
**Input**: Workspace in `reviewer` phase; reviewer artifact contains at least one High or Medium issue marked as unresolved
**Action**: Run `/dev hand-off`
**Expected**: Phase returns to `developer`; output says "Reviewer found high/medium issues. Returning to Developer for fixes."; `developer_start_2` added to timelines (not overwriting `developer_start`)

### TC-03: Reviewer → Tester (no high/medium issues)
**Input**: Workspace in `reviewer` phase; reviewer artifact contains only Low issues (or none)
**Action**: Run `/dev hand-off`
**Expected**: Phase advances to `tester`; low comments each get a new BUG-XXX entry in `bugs.json` and corresponding `bug-XXX.md` file; tester artifact template created

### TC-04: Tester writes test cases only — no execution
**Input**: Workspace in `tester` phase
**Action**: Tester agent produces artifact
**Expected**: Artifact contains Test Plan and Test Cases sections only; no "run", "execute", or "deploy" actions performed; executor is NOT invoked until `/dev hand-off` is called

### TC-05: Tester → Executor transition
**Input**: Workspace in `tester` phase with a complete tester artifact
**Action**: Run `/dev hand-off`
**Expected**: Phase advances to `executor`; executor artifact template created; executor agent is invoked

### TC-06: Executor → PO Approval transition
**Input**: Workspace in `executor` phase with completed test results
**Action**: Run `/dev hand-off`
**Expected**: Phase advances to `po-approval`; po-approval artifact template created; PO agent is invoked

### TC-07: PO approves → Complete
**Input**: Workspace in `po-approval` phase; all critical tests passed; PO decision = Approved
**Action**: Run `/dev hand-off`
**Expected**: Phase advances to `complete`; completion summary output; `/dev archive-feature` suggested

### TC-08: PO rejects → Developer
**Input**: Workspace in `po-approval` phase; PO decision = Rejected with noted failures
**Action**: Run `/dev hand-off`
**Expected**: Phase returns to `developer` with list of failures from executor; `developer_start_N` timeline entry appended

### TC-09: Timeline audit trail preserved across loops
**Input**: Workspace that has gone reviewer → developer → reviewer → tester
**Expected**: `state.json` timelines contains `developer_start`, `developer_complete`, `reviewer_start`, `reviewer_complete`, `developer_start_2`, `developer_complete_2`, `reviewer_start_2`, `reviewer_complete_2`, `tester_start`

### TC-10: All workspace types initialise with full 7-role set
**Input**: Run `/dev new-feature`, `/dev upgrade-feature`, `/dev bugfix` each with a new name
**Expected**: Each resulting `state.json` contains roles for all applicable phases including `executor` and `po-approval`
