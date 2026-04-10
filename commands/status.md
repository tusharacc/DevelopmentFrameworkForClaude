---
name: status
description: Show current workspace status and progress
arguments: ""
examples:
  - /dev status
---

# /dev status

Display the current workspace state, phase, and progress through the workflow.

## Usage

```
/dev status
```

## Output Example

```
═══════════════════════════════════════════════════════════════
  DEVELOPMENT FRAMEWORK STATUS
═══════════════════════════════════════════════════════════════

CURRENT WORKSPACE: user-authentication
  Type: feature
  Status: active
  Branch: feature/user-authentication
  Created: 2026-04-10T10:30:00Z

WORKFLOW PROGRESS:
  ✓ PO Requirements        [COMPLETE] - 2026-04-10 10:30-11:15
  → Architect Design       [IN PROGRESS] - Started 2026-04-10 11:15
    Developer              [PENDING]
    Reviewer               [PENDING]
    Tester                 [PENDING]
  
ARTIFACTS:
  ✓ user-auth.po.md                  - Requirements gathered
  → user-auth.architect.md           - Design in progress
    user-auth.dev.md                 - Waiting for phase
    user-auth.review.md              - Waiting for phase
    user-auth.test.md                - Waiting for phase
    user-auth.observe.md             - Running parallel

ROLE ASSIGNMENTS:
  PO:        claude@dev     [complete]
  Architect: claude@dev     [in-progress]
  Developer: [unassigned]   [pending]
  Reviewer:  [unassigned]   [pending]
  Tester:    [unassigned]   [pending]

NEXT ACTION:
  When Architect finishes design review, run: /dev hand-off

═══════════════════════════════════════════════════════════════
```

## Information Displayed

### Workspace Summary
- **Name**: Feature/workspace name
- **Type**: feature|upgrade|bugfix|minor
- **Status**: active|blocked|archived
- **Branch**: Git branch name
- **Created**: Timestamp of workspace creation

### Workflow Progress
- Phase completion status (✓ complete, → in-progress, ○ pending)
- Start and completion times for each phase
- Total time in current phase

### Artifacts
- Which artifacts have been created and updated
- Last update timestamp for each artifact
- Quick link to view specific artifacts

### Role Assignments
- Who is assigned to each role
- Current status of each role
- Which roles are unassigned

### Next Steps
- Suggested next action
- Command to run to advance workflow
- Details on what's blocking progress (if any)

## Related Commands

- `/dev view-artifact <name>` - View specific artifact content
- `/dev hand-off` - Complete current phase and advance
- `/dev switch-workspace <name>` - Switch to different workspace
- `/dev list-workspaces` - Show all workspaces

## Notes

- Shows most recent active workspace if none specified
- Updates in real-time from state.json
- Shows observability status in parallel (if running)
- Indicates which phase is waiting for human action

## Without Active Workspace

If no workspace is active:

```
No active workspace found.

Active workspaces:
  • user-authentication (feature) - Phase: developer
  • bug-fix-login (bugfix) - Phase: po
  • mobile-redesign (upgrade) - Phase: complete

Switch to a workspace:
  /dev switch-workspace user-authentication
  /dev switch-workspace bug-fix-login

Or create a new one:
  /dev new-feature "new-feature-name"
```
