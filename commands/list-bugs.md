---
name: list-bugs
description: List all bugs, optionally filtered by status or severity
arguments: "[--open|--in-progress|--fixed|--closed|--all] [--critical|--high|--medium|--low]"
examples:
  - /dev list-bugs
  - /dev list-bugs --open
  - /dev list-bugs --high
  - /dev list-bugs --open --critical
---

# /dev list-bugs

Display all bugs in the system, optionally filtered by status or severity.

## Usage

```
/dev list-bugs [status] [severity]
```

## Examples

```bash
# List all open bugs (default)
/dev list-bugs
/dev list-bugs --open

# List bugs by status
/dev list-bugs --in-progress
/dev list-bugs --fixed
/dev list-bugs --closed
/dev list-bugs --all

# List bugs by severity
/dev list-bugs --critical
/dev list-bugs --high
/dev list-bugs --medium

# Combine filters
/dev list-bugs --open --critical  # Open critical bugs
/dev list-bugs --in-progress      # Bugs being fixed
/dev list-bugs --closed           # Resolved bugs
```

## Output Example

```
════════════════════════════════════════════════════
  OPEN BUGS (3)
════════════════════════════════════════════════════

BUG-001 | Login fails on Safari
  Severity: high | Status: open | Workspace: -

BUG-002 | Performance regression on mobile
  Severity: medium | Status: open | Workspace: -

BUG-003 | CSS broken in dark mode
  Severity: low | Status: open | Workspace: -

════════════════════════════════════════════════════
  IN PROGRESS (2)
════════════════════════════════════════════════════

BUG-001 | Login fails on Safari
  Severity: high | Status: in-progress | Workspace: bugfix-bug-001

BUG-004 | API timeout on large requests
  Severity: high | Status: in-progress | Workspace: bugfix-bug-004

════════════════════════════════════════════════════
  STATISTICS
════════════════════════════════════════════════════

Total Bugs: 10
  Open: 3
  In Progress: 2
  Fixed: 3
  Closed: 2

By Severity:
  Critical: 1
  High: 4
  Medium: 3
  Low: 2
```

## Filters

### By Status
- `--open`: Not yet being worked on
- `--in-progress`: Being fixed in workspace
- `--fixed`: Implemented, awaiting testing
- `--closed`: Complete and tested
- `--all`: All bugs regardless of status

### By Severity
- `--critical`: System-breaking bugs
- `--high`: Major feature broken
- `--medium`: Feature partially broken
- `--low`: Minor issues, cosmetic

## Related Commands

- `/dev create-bug` - Create new bug
- `/dev bugfix` - Start fixing a bug
- `/dev view-bug` - View bug details
- `/dev close-bug` - Mark bug as closed
