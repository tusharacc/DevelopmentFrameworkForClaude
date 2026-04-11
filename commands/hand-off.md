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
- `reviewer` → `tester`
- `tester` → `complete`

If `currentPhase` is already `complete`, output "Workflow is already complete. Use /dev archive-feature to archive." and stop.

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
- **reviewer**: sections for Review Summary, Issues Found (Critical/Minor), Approval Status
- **tester**: sections for Test Plan, Test Cases, Results, Pass/Fail Status
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
- `developer` → Act as Developer: implement based on architect and PO artifacts
- `reviewer` → Act as Reviewer: review the developer artifact and implementation
- `tester` → Act as Tester: create and execute a test plan against acceptance criteria
- `complete` → Congratulate, summarize the workflow, suggest `/dev archive-feature`
