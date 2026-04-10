---
name: view-bug
description: View detailed bug information
arguments: bug-id
examples:
  - /dev view-bug BUG-001
  - /dev view-bug login-safari
---

# /dev view-bug

Display the full details of a bug including reproduction steps, expected vs actual behavior, and current status.

## Usage

```
/dev view-bug <bug-id>
```

## Example

```
/dev view-bug BUG-001

Output:
════════════════════════════════════════════════════
  BUG-001: Login fails on Safari
════════════════════════════════════════════════════

ID: BUG-001
Title: Login fails on Safari
Severity: high
Status: in-progress
Created: 2026-04-10T10:00:00Z
Workspace: bugfix-bug-001
Assigned: developer@example.com

DESCRIPTION:
Users cannot login when using Safari browser. Error message
does not appear, but login fails silently and redirects to
the login page.

REPRODUCTION STEPS:
1. Open Safari browser
2. Navigate to login page
3. Enter valid credentials
4. Click login button
5. Observe: Redirected to login page without error

EXPECTED BEHAVIOR:
Should successfully login and redirect to dashboard

ACTUAL BEHAVIOR:
Redirects to login page without error message

ROOT CAUSE:
[Once identified during bugfix]

FIX:
[Once implemented]

TESTING:
[ ] Verified in Safari
[ ] Verified in Chrome/Firefox
[ ] Verified on mobile Safari

════════════════════════════════════════════════════
```

## Information Shown

- **Bug ID**: Unique identifier
- **Title**: Brief summary
- **Severity**: Impact level (critical|high|medium|low)
- **Status**: Current state (open|in-progress|fixed|closed)
- **Created**: When bug was reported
- **Workspace**: Associated bugfix workspace (if being fixed)
- **Assigned**: Who's working on it
- **Description**: Full details of the bug
- **Reproduction Steps**: How to reproduce
- **Expected vs Actual**: What should happen vs what does
- **Root Cause**: Analysis (if completed)
- **Fix**: Solution implemented (if completed)
- **Testing**: Validation results (if completed)

## Related Commands

- `/dev list-bugs` - View all bugs
- `/dev bugfix` - Start fixing this bug
- `/dev create-bug` - Create new bug
- `/dev list-bugs --open` - View open bugs
