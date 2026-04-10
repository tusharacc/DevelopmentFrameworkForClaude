---
name: hand-off
description: Complete current phase and advance to next phase (triggers artifact creation, state update, and next agent)
arguments: ""
examples:
  - /dev hand-off
---

# /dev hand-off

Advance the current workspace to the next phase. This is the main command for orchestrating workflow progression.

## Usage

```
/dev hand-off
```

## What Happens

1. **Verify Current Phase Complete**
   - Checks that artifact exists and has content
   - Verifies workspace state is valid
   - Fails if phase not ready to hand off

2. **Advance to Next Phase**
   - Updates currentPhase in state.json
   - Records completion time for current phase
   - Records start time for next phase

3. **Generate Next Artifact**
   - Creates template artifact for next phase
   - Registers artifact path in state.json
   - Pre-populates with context from previous phases

4. **Auto-Commit to Git**
   - Stages `.dev-framework/` changes
   - Commits with message: `phase(feature-name): phase-name complete`
   - Creates audit trail of workflow progress

5. **Invoke Next Agent**
   - Starts the agent for the next phase
   - Passes workspace context and artifacts
   - Next role begins their work

## Example Workflow

```bash
# Start feature
/dev new-feature "User authentication"

# PO gathers requirements
[PO Agent works...]
[Creates user-auth.po.md with requirements]

# Hand off to Architect
/dev hand-off

# Output:
# ════════════════════════════════════════
#   PHASE HANDOFF: user-authentication
# ════════════════════════════════════════
#
# [1/5] Verifying phase completion...
# ✓ Phase po verified as complete
#
# [2/5] Advancing to next phase...
# ✓ Advanced from po to architect
#
# [3/5] Generating next artifact...
# ✓ Generated artifact: user-auth.architect.md
#
# [4/5] Auto-committing changes...
# ✓ Auto-committed: phase(user-authentication): po complete
#
# [5/5] Invoking next agent...
# Invoking agent: architect-design
# Workspace: user-authentication
# Phase: architect
#
# [Architect Agent starts gathering design requirements]
#
# ════════════════════════════════════════
#   HANDOFF COMPLETE
# ════════════════════════════════════════

# Architect completes design
[Architect Agent works...]
[Creates user-auth.architect.md with architecture design]

# Hand off to Developer
/dev hand-off

# [Same handoff flow repeats]
```

## Phase Sequence

```
PO
  ↓ /dev hand-off
Architect
  ↓ /dev hand-off
Developer
  ↓ /dev hand-off
Reviewer
  ↓ /dev hand-off
Tester
  ↓ /dev hand-off
Complete
```

**Note**: Observability runs in parallel, not in sequence.

## Artifacts Created at Each Handoff

| Handoff | From | To | Artifact Created |
|---------|------|-----|---------|
| 1st | init | PO | (none, PO creates) |
| 2nd | PO | Architect | architect artifact template |
| 3rd | Architect | Developer | developer artifact template |
| 4th | Developer | Reviewer | reviewer artifact template |
| 5th | Reviewer | Tester | tester artifact template |
| 6th | Tester | Complete | (workflow complete) |

## State Updates

Each handoff updates `state.json`:
- currentPhase: advanced to next
- roles[previous_role].status: "complete"
- roles[next_role].status: "pending"
- timelines[previous_phase + "_complete"]: timestamp
- timelines[next_phase + "_start"]: timestamp
- artifacts[next_phase]: artifact path

## Git Commits

Each handoff creates a commit:
```
phase(user-authentication): po complete

Created/updated artifacts:
- artifacts/user-auth.po.md
- artifacts/user-auth.architect.md (template)

Workspace state:
- currentPhase: architect
- roles.po.status: complete
- roles.architect.status: pending
```

## Error Cases

### Missing Artifact
```
ERROR: Artifact not found for po phase
Action: Current role must create artifact before handoff
Retry: /dev hand-off (when artifact is ready)
```

### Incomplete Artifact
```
ERROR: Artifact appears incomplete (5 lines)
Action: Current role must complete artifact work
Retry: /dev hand-off (when artifact is more complete)
```

### No Active Workspace
```
ERROR: No active workspace
Action: Create one with /dev new-feature or switch with /dev switch-workspace
```

### Git Commit Fails
```
⚠ Commit may have failed
Action: Check git status and resolve conflicts manually
Note: Workflow continues despite commit failure
```

## Special Cases

### Bug Fix Handoff
For bug fixes (`/dev bugfix`), phases are abbreviated:
- Skips PO phase (requirements not needed for bugfix)
- Skips Architect phase (design not needed for bugfix)
- Starts directly at Developer phase

Handoff still works the same way, just fewer phases.

### Minor Change Handoff
For minor changes, may have fewer phases:
- Skips PO phase
- Skips Architect phase
- Skips Tester phase (just code review needed)

### Workflow Restart
If issues found during later phases:
- Tester can request changes → Developer phase resumes
- Reviewer can request changes → Developer phase resumes
- Developer fixes issues and re-creates artifact
- Same `/dev hand-off` workflow continues

## Related Commands

- `/dev status` - See current phase before handoff
- `/dev view-artifact` - Review artifact to ensure complete
- `/dev new-feature` - Create workspace for handoff
- `/dev phase` - Direct phase control (if needed)
- `/dev archive-feature` - After workflow complete

## Tips

1. **Review Before Handoff**: Use `/dev view-artifact` to verify completion
2. **Update Status**: Use `/dev status` to see current state
3. **Check Git**: Verify changes staged before handoff
4. **Clear Communication**: Leave notes in artifact for next phase
5. **Complete Work**: Don't handoff until truly done

## Workflow Timeline Example

```
Day 1, 10:00 AM
  /dev new-feature "Authentication v2"
  → PO Agent invoked

Day 1, 11:30 AM
  /dev hand-off
  → Advanced to Architect
  → Architect Agent invoked

Day 1, 2:00 PM
  /dev hand-off
  → Advanced to Developer
  → Developer Agent invoked

Day 2, 4:00 PM
  /dev hand-off
  → Advanced to Reviewer
  → Reviewer Agent invoked

Day 2, 5:30 PM
  /dev hand-off
  → Advanced to Tester
  → Tester Agent invoked

Day 3, 10:00 AM
  /dev hand-off
  → Workflow COMPLETE
  → Ready for /dev archive-feature
```

## Success Criteria

Handoff is successful when:
- ✓ Previous phase artifact exists and has content
- ✓ Workspace state advanced to next phase
- ✓ Next artifact template created
- ✓ Changes auto-committed to git
- ✓ Next agent invoked
- ✓ No error messages displayed

## Notes

- Handoff is the core workflow progression mechanism
- One `/dev hand-off` = one phase complete + one phase begins
- All state changes are atomic (all or nothing)
- Observability runs in parallel, not blocking handoff
- Git commits create full audit trail
- Artifacts are versioned in git for history

This command is central to the framework's sequential workflow orchestration.

Good luck with your handoff! 🤝
