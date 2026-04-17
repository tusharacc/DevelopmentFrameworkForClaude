---
name: continue
description: Advance the current workspace to the next phase. Invoke this skill whenever the user says "continue", "next", "next step", "proceed", "move on", "done", "I'm done", "finished", "complete", "phase complete", "hand off", "handoff", "pass to next", or "advance" — these all mean the same thing as running hand-off.
arguments: ""
examples:
  - /dev-framework:continue
---

The user wants to advance to the next phase. Execute the hand-off sequence now.

## Step 1: Read current workspace and phase

Read `.dev-framework/current-workspace`.
Read `.dev-framework/workspaces/$SLUG/state.json` to get `currentPhase` and `workflowType`.

If no workspace found:
```
No active workspace to advance. Start one with:
  - new feature → say "new feature: [name]"
  - bugfix → say "bugfix: [description]"
  - hotfix → say "hotfix: [description]"
  - minor change → say "minor: [description]"
```
Stop.

## Step 2: Verify artifact completeness

Check `artifacts[$currentPhase]` in state.json. Read the file.
- Must exist
- Must have more than 15 lines
- Must have no section containing only `[To be filled]`

If incomplete, output:
```
The $currentPhase artifact is not ready for hand-off.
Please complete the following sections: [list incomplete sections]
```
Stop.

## Step 3: Execute hand-off

Follow the complete hand-off sequence from `dev-framework:hand-off`:
- Determine next phase using `workflowType` (see phase chains below)
- Update state.json
- Create next phase artifact template
- Git commit
- Announce and begin next phase as the appropriate agent

## Phase chains by workflowType

```
full:    po → architect → developer → reviewer → tester → executor → po-approval → complete
bugfix:  developer → reviewer → tester → executor → po-approval → complete
hotfix:  developer → reviewer → po-approval → complete
minor:   developer → reviewer → po-approval → complete
```

### Reviewer branching
- High/medium issues → return to `developer`
- Low issues only → file as bugs, advance to next phase in chain

### PO Approval branching
- All critical tests pass → advance to `complete`
- Failures → return to `developer` with failure list
