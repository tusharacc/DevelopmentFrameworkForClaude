---
name: upgrade-feature
description: Start a major feature upgrade (new branch, new workspace, full workflow)
arguments: feature-name
examples:
  - /dev upgrade-feature "Authentication v2"
  - /dev upgrade-feature auth-major-revamp
---

# /dev upgrade-feature

Start a major feature upgrade with a new workspace and branch (different from `/dev new-feature`).

## Usage

```
/dev upgrade-feature <feature-name>
```

## What Happens

1. **Create New Workspace** (separate from original)
   - Creates `/.dev-framework/workspaces/feature-name-upgrade/`
   - Creates state.json marked as type: "upgrade"
   - Initializes context.md

2. **Create New Git Branch**
   - Branch: `feature/feature-name-v2` or `upgrade/feature-name`
   - Isolated from current feature work
   - Allows parallel development

3. **Initialize Full Workflow**
   - Starts PO phase (requirements for upgrade)
   - All 6 phases available (unlike bugfix)
   - Follows same workflow as new feature

4. **Keep Original**
   - Original feature workspace remains active (if was active)
   - Can switch between original and upgrade
   - Both can progress in parallel

## When to Use

**Use `/dev upgrade-feature` for:**
- Major version bumps (v1 → v2)
- Significant architecture rewrites
- Breaking API changes
- Complete redesigns
- Features requiring multi-team effort

**Use `/dev new-feature` for:**
- New capabilities
- First implementation
- Incremental additions

**Use `/dev bugfix` for:**
- Bug fixes
- Patches
- Quick fixes

## Example

```bash
# Original feature was working on v1
/dev status
# Output: user-auth v1, Phase: complete

# Need to do major upgrade
/dev upgrade-feature "Authentication v2"

# Output:
# ✓ New upgrade workspace created: authentication-v2-upgrade
# ✓ New git branch: feature/authentication-v2
# ✓ Type: upgrade
# ✓ Workspace is now current
#
# PO Agent starting to gather requirements for upgrade...

# Later, switch back to v1
/dev switch-workspace user-auth
# Original workspace still there

# Then switch to v2
/dev switch-workspace authentication-v2-upgrade
# Upgrade workspace in separate branch
```

## Key Differences

| Aspect | New Feature | Upgrade | Bug Fix |
|--------|-------------|---------|---------|
| **Workspace** | New | New | Reuse |
| **Branch** | New feature/* | New upgrade/* | Existing bugfix/* |
| **Workflow** | All 6 phases | All 6 phases | 4 phases (skip PO/Arch) |
| **Original** | N/A | Kept running | Kept running |
| **Purpose** | New capability | Major redesign | Quick fix |

## Workspace Naming

Upgrade workspaces follow pattern:
- `{original-feature}-upgrade` or `{original-feature}-v2`
- Clearly indicates it's an upgrade
- Distinct from original workspace

## Git Branch Strategy

```
Feature Branch:
  • Original feature: feature/user-authentication
  • Upgrade: feature/user-authentication-v2
  
Both can exist in parallel:
  • Original: feature/user-authentication
  • Upgrade: upgrade/user-authentication

Work can progress on both simultaneously
```

## Parallel Development Example

```
Day 1:
  Maintain v1 in production
  Start designing v2 upgrade

Day 2:
  Bug fix in v1 (bugfix workspace)
  Design continues on v2

Day 3:
  v1 deployed to production
  v2 design completes

Day 4:
  v1 in maintenance mode
  v2 development in full swing

Day 10:
  v2 feature complete
  Archive v1 workspace (after release)
```

## Workflow Path

```
/dev upgrade-feature "Feature v2"
        ↓
[Full Workflow: PO → Architect → Developer → Reviewer → Tester]
        ↓
Original feature still on v1
Upgrade feature on v2
        ↓
Both can exist in parallel
Both can be worked on independently
```

## After Creation

```bash
# Upgrade workspace is current
/dev status
# Shows: Feature v2 upgrade, Phase: po

# Can switch between versions
/dev switch-workspace original-feature   # Original v1
/dev switch-workspace feature-v2-upgrade # New v2

# Manage both independently
/dev list-workspaces
# Shows both original and upgrade in active
```

## Migration Planning

When upgrading:
1. **PO Phase**: Define migration strategy
   - How do users move from v1 to v2?
   - Backwards compatibility?
   - Data migration path?

2. **Architect Phase**: Design upgrade architecture
   - How do v1 and v2 coexist?
   - Gradual rollout strategy?
   - Fallback plan?

3. **Developer Phase**: Implement v2
   - New implementation alongside v1
   - Feature flags for gradual rollout?
   - Data migration code?

4. **Testing Phase**: Test upgrade path
   - Backwards compatibility?
   - Data integrity?
   - Rollback scenarios?

## Archive Strategy

After upgrade completes:

```bash
# Archive original v1 (after fully migrated)
/dev archive-feature "user-auth-v1"
# Snapshot: user-auth-v1-snapshot-2026-04-15

# Archive upgrade (when v2 stable)
/dev archive-feature "user-auth-v2-upgrade"
# Snapshot: user-auth-v2-upgrade-snapshot-2026-04-20

# New v2 becomes your working feature
/dev new-feature "User auth v2"
```

## Error Cases

### Workspace Already Exists
```
ERROR: Workspace already exists: feature-name-upgrade
Action: Use different name or delete existing workspace
```

### Invalid Feature Name
```
ERROR: Invalid feature name: "feature@!#"
Action: Use alphanumeric, hyphens, spaces only
```

## Tips

1. **Clear Naming**: "authentication-v2-upgrade" vs "auth-upgrade"
2. **Document Why**: In PO phase, explain upgrade rationale
3. **Plan Migration**: Think about v1 → v2 migration early
4. **Test Thoroughly**: Upgrades are risky, test more
5. **Parallel Safety**: Both versions can run in git simultaneously

## Related Commands

- `/dev new-feature` - For new capabilities (not upgrades)
- `/dev bugfix` - For small fixes (not major changes)
- `/dev switch-workspace` - Switch between v1 and v2
- `/dev list-workspaces` - See both v1 and v2
- `/dev archive-feature` - Archive when v1 no longer needed

## Notes

- Upgrade is full workflow (unlike bugfix which shortcuts)
- Intended for significant rewrites
- Allows original to keep running
- Best for backwards incompatible changes
- Requires careful migration planning

This command enables major feature redesigns without disrupting current work!

Ready to upgrade! 🚀
