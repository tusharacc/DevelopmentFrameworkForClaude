---
name: archive-feature
description: Archive completed feature workspace, create snapshot, mark as complete
arguments: feature-name
examples:
  - /dev archive-feature "User authentication"
  - /dev archive-feature auth-v2
---

# /dev archive-feature

Archive a completed feature workspace. Creates a snapshot for reference and marks the workspace as archived.

## Usage

```
/dev archive-feature <feature-name>
```

## What Happens

1. **Verify Workflow Complete**
   - Checks that currentPhase is "complete"
   - Verifies all phases have artifacts
   - Fails if workflow not finished

2. **Create Snapshot**
   - Copies entire workspace to `/.dev-framework/archived/`
   - Names snapshot: `{feature-name}-snapshot-{date}`
   - Includes all artifacts and state

3. **Mark Archived**
   - Updates state.json: status = "archived"
   - Records archival timestamp
   - Workspace moved to archived section

4. **Update Workspace List**
   - Removes from active workspaces
   - Available in `/dev list-workspaces --archived`

5. **Optional: Create Release Tag** (if git)
   - Creates git tag: `release/{feature-name}`
   - Tags the merge commit
   - Preserved for history

## Example

```bash
# After workflow completes
/dev status
# Output shows: Phase: complete

# Archive the feature
/dev archive-feature "User authentication"

# Output:
# ✓ Workflow completion verified
# ✓ Snapshot created: user-auth-snapshot-2026-04-10
# ✓ Workspace archived
# ✓ Git tag created: release/user-authentication
#
# Archived feature available at:
# .dev-framework/archived/user-auth-snapshot-2026-04-10/
#
# All artifacts preserved for reference
```

## Snapshot Contents

```
.dev-framework/archived/user-auth-snapshot-2026-04-10/
├── state.json              # Final workspace state
├── context.md              # Workspace documentation
├── git-info.json           # Git branch info
└── [all original artifacts copied for reference]
```

## After Archival

**Active Workspace**: 
- Moved out of active section
- Can still view with `/dev list-workspaces --archived`
- Cannot be modified (archived = readonly)

**New Development**:
```bash
# If building next feature, create new workspace
/dev new-feature "Feature v2"

# If bug fix on same feature
/dev bugfix "bug-id-in-archived-feature"
```

**Reference**:
- Old workspace available in `.dev-framework/archived/`
- All artifacts preserved
- Can view previous phase artifacts
- Can reference for similar features

## Git Integration

If in git repository:
- Creates annotated tag: `release/{feature-name}`
- Tag points to merge commit
- Tag includes archival date in message
- Preserved in git history

```bash
git tag -a release/user-authentication \
  -m "Feature archived: 2026-04-10"
```

## When to Archive

Archive when:
- ✓ All phases complete (currentPhase = "complete")
- ✓ Feature merged to main branch
- ✓ Testing passed
- ✓ Ready to move on to next feature
- ✓ Ready to preserve for history/reference

## Error Cases

### Workflow Not Complete
```
ERROR: Workflow not complete (Phase: tester)
Action: Complete remaining phases first
Next: /dev hand-off (to advance tester → complete)
Then: /dev archive-feature
```

### Workspace Already Archived
```
ERROR: Workspace already archived
Action: Use /dev list-workspaces --archived to view archived
```

### Workspace Not Found
```
ERROR: Workspace not found: invalid-name
Action: Check spelling with /dev list-workspaces
```

## Viewing Archived Workspaces

```bash
# See all archived workspaces
/dev list-workspaces --archived

# View archived workspace details
/dev status user-auth  # Still works if archived

# View archived artifacts
/dev view-artifact user-auth.po.md
```

## Updating Current Workspace

If you archive the current workspace:
```bash
/dev archive-feature "current-feature"

# Automatically switches to:
# - Next active workspace (if exists)
# - Or shows: No active workspace
```

## Related Commands

- `/dev status` - Check if ready to archive (phase should be "complete")
- `/dev list-workspaces --archived` - View archived workspaces
- `/dev hand-off` - Complete final phase before archiving
- `/dev new-feature` - Create next feature after archiving

## Archive Strategy

**Per Requirements**:
```
After New Feature/Upgrade:
  → Create new workspace, archive old workspace
  
After Bug Fix:
  → Archive bug fix workspace
  
Keep Archived For:
  → Reference for similar features
  → Historical documentation
  → Audit trail
  → Pattern examples
```

## Notes

- Snapshots are readonly (no modifications)
- Can be safely deleted later if space needed
- Git tags preserve in git history
- Recommended: Archive when feature released
- Snapshots don't need to be committed (they're copies of .dev-framework/)

## Tips

1. **Before Archiving**: Verify with `/dev status` phase is complete
2. **After Archiving**: Switch workspace or create new feature
3. **For Reference**: Keep snapshots for at least one release cycle
4. **For Storage**: Can safely delete old snapshots after archival period
5. **For History**: Git tags in git log show when features were released

## Example Timeline

```
/dev new-feature "Auth v1"
[workflow progresses...]
/dev hand-off → complete

/dev archive-feature "Auth v1"
✓ Snapshot: auth-v1-snapshot-2026-04-10
✓ Git tag: release/auth-v1

/dev new-feature "Auth v2"
[new workflow starts...]
[Auth v1 snapshot available for reference]
```

Remember: Archiving is how you clean up completed features while preserving them for reference.

Good luck archiving! 📦
