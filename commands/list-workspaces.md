---
name: list-workspaces
description: List all active and archived workspaces
arguments: "[--all|--active|--archived]"
examples:
  - /dev list-workspaces
  - /dev list-workspaces --all
  - /dev list-workspaces --archived
---

# /dev list-workspaces

Show all active workspaces or optionally archived ones.

## Usage

```
/dev list-workspaces [--all|--active|--archived]
```

### Options
- `--active` (default) - Show only active workspaces
- `--archived` - Show only archived workspaces
- `--all` - Show both active and archived

## Output Example

```
═══════════════════════════════════════════════════════════════
  ACTIVE WORKSPACES (3)
═══════════════════════════════════════════════════════════════

[*] user-authentication
    Type: feature | Phase: developer | Status: active
    Branch: feature/user-authentication
    Created: 2026-04-10 10:30 | Next: /dev hand-off
    Progress: ✓ PO (11:15) → ✓ Architect (2h) → Developer

[ ] bug-fix-login-safari
    Type: bugfix | Phase: developer | Status: active
    Branch: bugfix/bug-001
    Created: 2026-04-09 14:00 | Next: /dev hand-off
    Progress: ○ PO (skipped) → ○ Architect (skipped) → Developer

[ ] mobile-redesign
    Type: upgrade | Phase: reviewer | Status: active
    Branch: feature/mobile-redesign-v2
    Created: 2026-04-08 09:00 | Next: /dev hand-off
    Progress: ✓ PO (15m) → ✓ Architect (1h) → ✓ Developer (3h) → Reviewer

═══════════════════════════════════════════════════════════════
  ARCHIVED WORKSPACES (5)
═══════════════════════════════════════════════════════════════

[ ] dark-mode-implementation
    Type: feature | Phase: complete | Status: archived
    Archived: 2026-04-05 16:30 | Duration: 3 days
    Final Status: ✓ All phases complete
    Snapshot: .dev-framework/archived/dark-mode-implementation-snapshot-2026-04-05

[ ] performance-optimization
    Type: upgrade | Phase: complete | Status: archived
    Archived: 2026-04-02 12:00 | Duration: 2 days
    Final Status: ✓ All phases complete
    Snapshot: .dev-framework/archived/performance-optimization-snapshot-2026-04-02

═══════════════════════════════════════════════════════════════

Legend:
  [*] Current workspace
  [ ] Other workspace
  ✓   Phase complete
  →   Phase in progress
  ○   Phase pending
  ✗   Phase blocked
```

## Information Per Workspace

**Name**: Workspace identifier (feature name or bug ID)

**Type**: 
- `feature` - New feature
- `upgrade` - Major upgrade
- `bugfix` - Bug fix
- `minor` - Minor change

**Phase**:
- `po` - Requirements gathering
- `architect` - Design phase
- `developer` - Implementation
- `reviewer` - Code review
- `tester` - Testing & validation
- `complete` - Ready/archived

**Status**:
- `active` - In progress
- `blocked` - Waiting for something
- `archived` - Completed and archived

**Branch**: Associated git branch

**Progress**: Visual timeline showing:
- ✓ Completed phases with duration
- → Current phase in progress
- ○ Pending phases
- ✗ Blocked phases

**Next Action**: What to do next (e.g., `/dev hand-off`, `/dev switch-workspace`)

## Filtering Examples

### Show only active workspaces (default)
```bash
/dev list-workspaces
/dev list-workspaces --active
```

### Show only archived workspaces
```bash
/dev list-workspaces --archived
```

### Show all workspaces
```bash
/dev list-workspaces --all
```

## Workspace Statistics

At the bottom of output:
```
═══════════════════════════════════════════════════════════════
  STATISTICS
═══════════════════════════════════════════════════════════════

Active Workspaces: 3
  - In Progress: 2 (developer phase, reviewer phase)
  - Blocked: 1
  
Archived Workspaces: 5
  - Avg Duration: 2.4 days
  - Success Rate: 100% (5/5 complete)

Recent Activity:
  • mobile-redesign advanced to reviewer (2h ago)
  • bug-fix-login-safari created (18h ago)
  • dark-mode-implementation archived (5 days ago)
```

## Related Commands

- `/dev status` - Show detailed status of current workspace
- `/dev switch-workspace <name>` - Switch to different workspace
- `/dev new-feature <name>` - Create new feature workspace
- `/dev archive-feature <name>` - Archive completed feature
- `/dev view-artifact <artifact>` - View workspace artifact

## Notes

- Current workspace marked with `[*]`
- Archived workspaces kept for reference and auditing
- Workspaces stay in active list until explicitly archived
- Progress timeline is calculated from phase timelines in state.json
