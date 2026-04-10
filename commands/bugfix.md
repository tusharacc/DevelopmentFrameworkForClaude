---
name: bugfix
description: Start a bug fix workflow (abbreviated, skips PO/Architect phases)
arguments: bug-id
examples:
  - /dev bugfix BUG-001
  - /dev bugfix login-safari-issue
---

# /dev bugfix

Start a bug fix workflow. Abbreviated process that skips PO and Architect phases, going straight to Developer.

## Usage

```
/dev bugfix <bug-id-or-name>
```

## What Happens

1. **Look Up Bug** (if exists)
   - Checks `/.dev-framework/bugs/bugs.json`
   - Loads bug details if found
   - Otherwise creates new bug entry

2. **Create Bug Fix Workspace**
   - Creates `/.dev-framework/workspaces/bugfix-{bug-id}/`
   - Creates state.json marked as type: "bugfix"
   - Sets to reuse existing branch (or create bugfix/bug-id)

3. **Skip PO & Architect Phases**
   - Sets currentPhase directly to "developer"
   - No requirements gathering needed
   - No design phase needed
   - Bug description serves as requirements

4. **Invoke Developer Agent**
   - Provides bug details
   - Developer implements fix
   - Workflow: Developer → Reviewer → Tester

5. **Update Bug Index**
   - Creates bugfix workspace entry
   - Links bug to workspace

## Workflow for Bug Fixes

```
Bug Found
  ↓
/dev bugfix BUG-001
  ↓
[PO & Architect skipped]
  ↓
Developer (Fix Implementation)
  ↓ /dev hand-off
Reviewer (Code Review)
  ↓ /dev hand-off
Tester (Validation)
  ↓ /dev hand-off
Complete
```

**Much faster than full workflow!**

## Example

```bash
# Bug found and logged
/dev bugfix BUG-001

# Output:
# ✓ Bug workspace created: bugfix-bug-001
# ✓ Type: bugfix
# ✓ Phases skipped: po, architect
# ✓ Starting phase: developer
# 
# Bug Details:
# ────────────────────────────────────
# ID: BUG-001
# Title: Login fails on Safari
# Severity: high
# Description: [from bug database]
# 
# Developer, implement the fix:
# 1. Reproduce the issue
# 2. Find root cause
# 3. Implement fix
# 4. Test thoroughly
# 5. Run /dev hand-off
#
# ────────────────────────────────────

# Developer implements fix
[Developer works...]

# Hand off to Reviewer
/dev hand-off

# Reviewer reviews fix
[Reviewer works...]

# Hand off to Tester
/dev hand-off

# Tester validates fix
[Tester works...]

# Bug fix complete!
/dev hand-off
```

## When to Use

**Use `/dev bugfix` for:**
- Bug fixes
- Patch releases
- Critical hotfixes
- Security patches
- Regression fixes

**Use `/dev new-feature` for:**
- New functionality
- New capabilities
- Enhancements

**Use `/dev upgrade-feature` for:**
- Major redesigns
- Version upgrades
- Architecture changes

## Bug Details

Bug information can come from:
1. **Existing bug** - Load from `bugs.json`
2. **New bug** - User provides details
3. **Bug description** - Serves as requirements

Typical bug details:
- Bug ID
- Title
- Severity (critical|high|medium|low)
- Description/reproduction steps
- Expected vs actual behavior
- Affected version
- Screenshots/logs (if available)

## Abbreviated Phases

### What's Skipped

**PO Phase Skipped Because**:
- Bug already describes problem
- Acceptance criteria obvious (bug must be fixed)
- No ambiguity about requirements

**Architect Phase Skipped Because**:
- Usually localized fix
- Doesn't need architectural redesign
- Scope is narrow (fix the bug)
- Developer can make design choices

### What's Included

**Developer Phase**:
- Understand bug
- Find root cause
- Implement fix
- Test fix
- Create dev artifact

**Reviewer Phase**:
- Code review
- Verify fix approach
- Check test coverage
- Approve for testing

**Tester Phase**:
- Validate fix works
- Test edge cases
- Regression testing
- Sign off

## Workspace Reuse

Bug fix workspaces can:
```
Option 1: Create new workspace
  Branch: bugfix/bug-001
  Workspace: bugfix-bug-001/
  Fresh start for this bug

Option 2: Reuse if related
  Same branch as previous fix
  Previous workspace continues
  (if same area of code)
```

Default: Create new workspace per bug.

## Bug Tracking Integration

Bug information stored in:
```
/.dev-framework/bugs/
├── bugs.json                # Bug index
└── bug-001.md              # Bug details
```

When bugfix workspace created:
- Links workspace to bug in index
- Associates workspace with bug
- Can switch between bug view and workspace view

## After Bug Fix

When bugfix completes:

```bash
# Archive bug fix workspace
/dev archive-feature bugfix-bug-001

# Mark bug as fixed
/dev close-bug BUG-001
# (Updates bugs.json)

# View closed bugs
/dev list-bugs --closed
```

## Error Cases

### Bug Not Found
```
ERROR: Bug not found: INVALID-BUG

Did you mean:
  /dev bugfix BUG-001
  /dev bugfix BUG-002

Or create new bug first:
  /dev create-bug
```

### Workspace Already Exists
```
ERROR: Workspace already exists: bugfix-bug-001

Options:
  • Switch to existing: /dev switch-workspace bugfix-bug-001
  • Use different bug ID: /dev bugfix BUG-002
  • Archive completed: /dev archive-feature bugfix-bug-001
```

## Performance Gains

Compared to full `/dev new-feature` workflow:

| Phase | New Feature | Bug Fix |
|-------|-------------|---------|
| PO | 30 min | Skipped |
| Architect | 1 hr | Skipped |
| Developer | 2 hrs | 1 hr |
| Reviewer | 30 min | 30 min |
| Tester | 1 hr | 30 min |
| **Total** | **5 hrs** | **2 hrs** |

**60% faster workflow for focused bug fixes!**

## Tips for Bug Fixes

1. **Reproduce First**: Developer should reproduce bug before fixing
2. **Root Cause**: Don't just patch symptoms, fix root cause
3. **Test Thoroughly**: Test fix doesn't break other features
4. **Document**: Comment code explaining why fix needed
5. **Regression**: Verify fix doesn't cause new bugs
6. **Clean Up**: Don't commit temporary debug code

## Related Commands

- `/dev create-bug` - Create new bug entry
- `/dev list-bugs` - View all bugs
- `/dev status` - Check bugfix progress
- `/dev switch-workspace` - Switch between bug fixes
- `/dev archive-feature` - Archive completed bugfix

## Bug Lifecycle

```
Bug discovered
  ↓
/dev create-bug
  ↓
Bug entry created (bugs.json)
  ↓
/dev bugfix BUG-001
  ↓
Fix implemented → reviewed → tested
  ↓
/dev hand-off (when complete)
  ↓
/dev close-bug BUG-001
  ↓
Marked as fixed in bugs.json
  ↓
/dev archive-feature bugfix-bug-001
  ↓
Workspace archived, bug closed
```

## Critical vs Non-Critical

### Critical Bugs (Emergency)
```bash
# Create urgent bugfix
/dev bugfix CRITICAL-001
[expedited review & testing]
```

### Non-Critical Bugs (Regular)
```bash
# Regular bugfix workflow
/dev bugfix BUG-099
[normal workflow process]
```

Framework handles both the same way; just priority differs.

## Notes

- Bug ID can be alphanumeric (BUG-001, auth-bug, safari-crash)
- Workspace name sanitized (hyphens, lowercase)
- Bug details preserved in workspace for reference
- Abbreviated workflow ~60% faster than full workflow
- Still includes review and testing (quality not compromised)

This command makes bug fixes fast and efficient!

Happy bug hunting! 🐛
