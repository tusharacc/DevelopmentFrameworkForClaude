---
name: new-feature
description: Start a new feature workflow (creates workspace, initializes state, begins PO phase)
arguments: feature-name
examples:
  - /dev new-feature "User authentication"
  - /dev new-feature auth-v2
---

# /dev new-feature

Start a new feature with full development workflow: PO → Architect → Developer → Reviewer → Tester.

## Usage

```
/dev new-feature <feature-name>
```

## What Happens

1. **Workspace Creation**
   - Creates `/.dev-framework/workspaces/feature-name/`
   - Initializes `state.json` with metadata
   - Creates `context.md` for workspace documentation
   - Creates git branch `feature/feature-name`

2. **Artifact Generation**
   - Creates empty PO requirements artifact
   - Creates templates for all phases
   - Registers artifacts in state.json

3. **Initialization**
   - Sets workspace as current
   - Updates git branch
   - Auto-commit: "feat(framework): new workspace feature-name"

4. **Next Step**
   - Invoke PO agent to gather requirements
   - Ready for `/dev hand-off` when PO completes

## Example

```bash
/dev new-feature "User authentication system"

# Output:
# ✓ Workspace created: user-authentication-system
# ✓ Branch created: feature/user-authentication-system
# ✓ Artifacts initialized
# 
# PO Agent starting...
# [PO Agent gathers requirements]
# 
# When complete, run: /dev hand-off
```

## Files Created

```
.dev-framework/
├── workspaces/
│   └── user-authentication-system/
│       ├── state.json          # Workspace metadata and phase tracking
│       ├── context.md          # Workspace context and roles
│       └── git-info.json       # Git branch info
└── artifacts/
    ├── user-authentication-system.po.md          # PO template
    ├── user-authentication-system.architect.md   # Architect template
    ├── user-authentication-system.dev.md         # Developer template
    ├── user-authentication-system.review.md      # Reviewer template
    ├── user-authentication-system.test.md        # Tester template
    └── user-authentication-system.observe.md     # Observability template
```

## Workflow After Command

```
/dev new-feature "feature-name"
            ↓
    [Workspace created]
            ↓
    [Git branch created]
            ↓
    [PO Agent invoked]
            ↓
    [User: gather requirements]
            ↓
    /dev hand-off (when PO complete)
            ↓
    [Architect phase begins]
```

## Related Commands

- `/dev status` - Show current workspace state
- `/dev hand-off` - Complete PO phase and advance to Architect
- `/dev list-workspaces` - List all active workspaces
- `/dev switch-workspace` - Switch to different workspace

## Notes

- Feature name can include spaces (use quotes)
- Git branch name is auto-generated (lowercase, hyphens)
- Workspace is set as current after creation
- All artifacts are in Markdown format for easy git tracking
- Auto-commit captures workspace initialization

## Change Type: New Feature

This command is for starting completely new features. For:
- **Major Upgrade**: Use `/dev upgrade-feature` (creates separate workspace)
- **Bug Fix**: Use `/dev bugfix` (reuses existing workspace)
- **Minor Change**: Make changes directly, no new workspace needed
