---
name: create-bug
description: Create a new bug report and add it to the bug index
arguments: ""
examples:
  - /dev create-bug
---

Create a new bug report by gathering details from the user.

## Step 1: Ensure bugs directory exists

```bash
mkdir -p .dev-framework/bugs
```

## Step 2: Determine next bug ID

Read `.dev-framework/bugs/bugs.json` if it exists to find the highest existing ID number.
Next ID = highest + 1, formatted as `BUG-001`, `BUG-002`, etc.
If `bugs.json` doesn't exist, start at `BUG-001`.

## Step 3: Ask the user for bug details

Ask these questions (can be combined in one prompt):
1. **Title**: Brief description of the bug
2. **Description**: What happens and when
3. **Severity**: critical | high | medium | low
4. **Steps to reproduce**: How to trigger it
5. **Expected vs actual behavior**

## Step 4: Create bug detail file

Create `.dev-framework/bugs/bug-$ID.md`:
```markdown
# $ID: $TITLE

**Severity**: $SEVERITY
**Status**: open
**Created**: <timestamp>

## Description
$DESCRIPTION

## Steps to Reproduce
$STEPS

## Expected Behavior
$EXPECTED

## Actual Behavior
$ACTUAL

## Root Cause
[To be identified during fix]

## Fix
[To be implemented]
```

## Step 5: Update bugs.json

Create or update `.dev-framework/bugs/bugs.json` to add the new entry:
```json
{
  "bugs": [
    {
      "id": "$ID",
      "title": "$TITLE",
      "severity": "$SEVERITY",
      "status": "open",
      "created": "<timestamp>",
      "workspace": null
    }
  ]
}
```

## Step 6: Output confirmation

```
✓ Bug created: $ID
✓ Title: $TITLE
✓ Severity: $SEVERITY
✓ Status: open

To start fixing: /dev bugfix $ID
To view details: /dev view-bug $ID
```
