---
name: create-bug
description: Create a new bug report and add to bug index
arguments: ""
examples:
  - /dev create-bug
---

# /dev create-bug

Create a new bug report. Initiates interactive dialog to gather bug details.

## Usage

```
/dev create-bug
```

## Interactive Dialog

```
Creating new bug report...

Title: Login fails on Safari
Description: Users cannot login when using Safari browser. Error message does not appear.
Severity (critical|high|medium|low): high
Version/Build: 1.0.0

✓ Bug created: BUG-001
✓ Severity: high
✓ Status: open

To start fixing: /dev bugfix BUG-001
To view details: /dev view-bug BUG-001
```

## What Gets Created

1. **Bug Entry in bugs.json**
   - Unique ID (BUG-001, BUG-002, etc)
   - Title and description
   - Severity level
   - Creation timestamp
   - Status: open

2. **Bug Detail Artifact**
   - `.dev-framework/bugs/bug-{id}.md`
   - Full bug details
   - Reproduction steps template
   - Expected vs actual behavior
   - Environment info

## After Creating Bug

```bash
# View all open bugs
/dev list-bugs

# View bug details
/dev view-bug BUG-001

# Start fixing
/dev bugfix BUG-001
```

For bug management workflow, see `/dev bugfix`.
