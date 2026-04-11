---
name: hand-off
description: Complete current phase and advance to the next phase in the workflow
arguments: ""
examples:
  - /dev hand-off
---

Advance the current workspace to the next development phase.

## Step 1: Identify current workspace and phase

Read `.dev-framework/current-workspace` to get the workspace slug.
Read `.dev-framework/workspaces/$SLUG/state.json` to get `currentPhase`.

If no workspace is found, output:
```
ERROR: No active workspace. Create one with /dev new-feature or switch with /dev switch-workspace.
```
and stop.

## Step 2: Verify the current phase artifact exists and has content

Check the artifact path stored in `state.json` under `artifacts[$currentPhase]`.
If missing or the file is empty/fewer than 10 lines, output:
```
ERROR: Artifact for $currentPhase phase is missing or incomplete.
Complete the current phase work before handing off.
```
and stop.

## Step 3: Determine next phase

Phase sequence:
- `po` → `architect`
- `architect` → `developer`
- `developer` → `reviewer`
- `reviewer` → `developer` (if high/medium issues found — see reviewer branching below)
- `reviewer` → `tester` (only when no high/medium issues remain)
- `tester` → `executor`
- `executor` → `po-approval`
- `po-approval` → `complete`

If `currentPhase` is already `complete`, output "Workflow is already complete. Use /dev archive-feature to archive." and stop.

### Reviewer branching (reviewer → next phase)

When handing off from `reviewer`, read the reviewer artifact and check for open issues by severity:

1. **High or medium issues exist** → next phase is `developer` (loop back)
   - Output: "Reviewer found high/medium issues. Returning to Developer for fixes."
   - Developer must resolve all high/medium comments before handing off again.

2. **Only low issues (or none)** → next phase is `tester`
   - For each low-priority comment, automatically create a bug entry in `.dev-framework/bugs/`:
     - Generate next BUG-XXX ID from `bugs.json`
     - Write `.dev-framework/bugs/bug-XXX.md` with the comment as description, severity `low`, status `open`
     - Update `bugs.json`
   - Output: "Low-priority comments filed as bugs: [list IDs]. Advancing to Tester."

## Step 4: Update state.json

- Set `roles[$currentPhase].status` to `"complete"` and `roles[$currentPhase].completed` to current ISO timestamp
- Set `currentPhase` to `$nextPhase`
- Set `roles[$nextPhase].status` to `"in-progress"`
- Add `timelines[$currentPhase + "_complete"]` = current timestamp
- Add `timelines[$nextPhase + "_start"]` = current timestamp

## Step 5: Create next phase artifact template

Create `.dev-framework/artifacts/$SLUG.$nextPhase.md` with an appropriate template for that phase. Update `state.json` `artifacts[$nextPhase]` to point to this file.

Phase artifact templates:
- **architect**: sections for System Design, Components, Data Models, API Contracts, Tech Decisions, Open Questions
- **developer**: sections for Implementation Plan, Files Changed, Code Summary, Decisions Made
- **reviewer**: sections for Review Summary, Issues by Severity (High / Medium / Low), Approval Status
- **tester**: sections for Test Plan, Test Cases (written only — not executed here)
- **executor**: sections for Execution Summary, Test Results (pass/fail per case), Issues Found, Overall Status
- **po-approval**: sections for Executor Findings Summary, PO Decision (Approved / Rejected), Notes
- **complete**: summary of all phases

## Step 6: Git commit

```bash
git add .dev-framework/
git commit -m "phase($SLUG): $currentPhase complete → $nextPhase begins"
```

## Step 7: Confirm and begin next phase

Output:
```
✓ Phase complete: $currentPhase
✓ Advanced to: $nextPhase
✓ Artifact created: $SLUG.$nextPhase.md
✓ Changes committed

Starting $nextPhase phase...
```

Then immediately act as the appropriate agent for `$nextPhase`:
- `architect` → Act as Architect: design the technical solution based on the PO artifact
- `developer` → Act as Developer: implement based on architect and PO artifacts; if returning from reviewer, address all high/medium comments from the reviewer artifact
- `reviewer` → Act as Reviewer: review the developer artifact and all changed files; categorise every issue as **High**, **Medium**, or **Low**; do NOT approve if any High/Medium issues remain unresolved
- `tester` → Act as Tester: **write test cases only** — define test scenarios, inputs, expected outputs, and edge cases; do NOT run or execute anything; hand off to Executor when done
- `executor` → Act as Executor: run the test cases written by the Tester against the actual implementation; record pass/fail for each case; document any failures with details
- `po-approval` → Act as Product Owner: review the Executor's findings; if all critical tests pass, **approve** and advance to complete; if failures exist, **reject** and return to developer with a clear list of what must be fixed
- `complete` → Congratulate, summarize all phases, suggest `/dev archive-feature`
