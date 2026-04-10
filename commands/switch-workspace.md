---
name: switch-workspace
description: Switch to a different active workspace
arguments: workspace-name
examples:
  - /dev switch-workspace "user-authentication"
  - /dev switch-workspace auth-v2
---

# /dev switch-workspace

Switch the current active workspace to a different one. Useful when managing multiple features in progress.

## Usage

```
/dev switch-workspace <workspace-name>
```

## What Happens

1. **Verify Workspace Exists**
   - Checks if workspace directory exists
   - Verifies state.json is valid
   - Fails if workspace not found

2. **Update Current Workspace**
   - Saves new workspace name to `.dev-framework/current-workspace`
   - Updates context in system

3. **Checkout Git Branch**
   - Checks out the workspace's git branch
   - Updates working directory to match branch
   - Fails if branch doesn't exist

4. **Display Status**
   - Shows new workspace state
   - Shows current phase
   - Shows what's needed next

## Example

```bash
# List active workspaces
/dev list-workspaces

# Output:
# [*] user-authentication   - Phase: developer
# [ ] mobile-redesign       - Phase: architect
# [ ] bug-fix-login         - Phase: developer

# Switch to mobile-redesign
/dev switch-workspace mobile-redesign

# Output:
# ✓ Switched to workspace: mobile-redesign
# ✓ Git branch: feature/mobile-redesign
# ✓ Current phase: architect
#
# Status:
# ────────────────────────────────────────
# Workspace: mobile-redesign (upgrade)
# Phase: architect (in progress)
# Branch: feature/mobile-redesign
# Next: /dev hand-off (when architect complete)
# ────────────────────────────────────────
```

## After Switching

Commands now operate on new workspace:
```bash
/dev status              # Shows mobile-redesign status
/dev view-artifact       # Shows mobile-redesign artifacts
/dev hand-off            # Advances mobile-redesign phase
```

## Multiple Workspaces in Progress

```bash
# Day 1: Work on authentication
/dev new-feature "User authentication"
[work...]

# Day 2: Start mobile redesign
/dev new-feature "Mobile redesign"
[work...]

# Day 3: Switch back to authentication
/dev switch-workspace user-authentication
[continue work...]

# Day 4: Check progress on mobile redesign
/dev switch-workspace mobile-redesign
/dev status
```

## Error Cases

### Workspace Not Found
```
ERROR: Workspace not found: invalid-name

Available workspaces:
  • user-authentication
  • mobile-redesign
  • bug-fix-login

Use exact workspace name with: /dev switch-workspace name
```

### Archived Workspace
```
ERROR: Cannot switch to archived workspace: completed-feature

To view archived workspace:
  /dev list-workspaces --archived
  /dev view-artifact completed-feature.po.md
```

### Invalid Git Branch
```
⚠ Warning: Git branch not found
  Expected: feature/workspace-name
  Git checkout may fail
  
Status: Workspace marked as current but branch missing
```

## Workspace Isolation

Each workspace has:
```
workspace-name/
├── state.json        # Phase, timeline, roles
├── context.md        # Documentation
└── git-info.json     # Branch info
```

Switching workspaces:
- ✓ Changes current workspace context
- ✓ Checks out correct git branch
- ✓ `/dev status` shows correct phase
- ✓ Artifacts remain in `.dev-framework/artifacts/`

## Artifact Access

Artifacts are shared (not per-workspace):
```bash
/dev switch-workspace user-auth
/dev view-artifact user-auth.po.md        # Works

/dev switch-workspace mobile-redesign
/dev view-artifact user-auth.po.md        # Still works!
/dev view-artifact mobile-redesign.po.md  # Also works
```

All artifacts in `/.dev-framework/artifacts/` are accessible regardless of current workspace.

## Git Branch Management

Switching workspaces also checks out git branch:

```bash
# Workspace 1 is on feature/auth branch
/dev switch-workspace user-auth
git branch  # feature/auth* (current)

# Workspace 2 is on feature/redesign branch
/dev switch-workspace mobile-redesign
git branch  # feature/redesign* (current)

# Back to workspace 1
/dev switch-workspace user-auth
git branch  # feature/auth* (current again)
```

This ensures your git branch matches your workspace.

## Tips for Multiple Workspaces

1. **Name Clearly**: Use descriptive names so switching is unambiguous
2. **Track Progress**: Use `/dev status` after switching to see where you are
3. **Don't Lose Context**: Status shows phase and next action
4. **Separate Branches**: Each workspace has own git branch
5. **Review Artifacts**: All artifacts available regardless of workspace

## Related Commands

- `/dev list-workspaces` - See all active workspaces
- `/dev new-feature` - Create new workspace (auto-switches to it)
- `/dev status` - Check current workspace and phase
- `/dev view-artifact` - View any artifact regardless of workspace

## Use Cases

**Parallel Development**:
- Multiple developers working on different features
- Switch between features during day
- Maintain separate workspace state

**Testing Changes**:
- Work on feature A
- Switch to feature B to test interaction
- Switch back to A to continue

**Context Switching**:
- When interrupted by urgent bug fix
- Create bugfix workspace
- Switch back to original feature when done

**Code Review**:
- Switch to different workspace
- Review artifacts and phase progress
- Switch back to own work

## Notes

- Current workspace marker: `[*]` in `/dev list-workspaces`
- Workspace context persists: `.dev-framework/current-workspace`
- Git branch checked out automatically
- Non-existent branch: warning but continues
- Archived workspaces: cannot switch (use `/dev list-workspaces --archived`)

This command enables smooth multi-workspace management!

Good luck switching! 🔄
