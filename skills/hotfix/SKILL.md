---
name: hotfix
description: Start an urgent hotfix workflow for critical production issues. Abbreviated chain — Developer → Reviewer → PO Approval. Use for production outages, security vulnerabilities, or critical regressions.
arguments: issue-description
examples:
  - /dev-framework:hotfix "login service down in production"
  - /dev-framework:hotfix "payment API returning 500"
---

Start a hotfix workflow for: **$ARGUMENTS**

Hotfix is an abbreviated workflow. Tester and Executor phases are skipped for speed.
Phase chain: **Developer → Reviewer → PO Approval → Complete**

## Step 1: Create workspace slug

Convert "$ARGUMENTS" to a slug: lowercase, hyphens for spaces, remove special characters.
Prefix with `hotfix-`. Example: "login service down" → `hotfix-login-service-down`

## Step 2: Create workspace directories

```bash
mkdir -p .dev-framework/workspaces/$SLUG
mkdir -p .dev-framework/artifacts
```

## Step 3: Write state.json

```json
{
  "name": "$SLUG",
  "type": "hotfix",
  "workflowType": "hotfix",
  "created": "<current ISO timestamp>",
  "currentPhase": "developer",
  "status": "active",
  "branch": "hotfix/$SLUG",
  "roles": {
    "developer": { "status": "in-progress", "completed": null },
    "reviewer": { "status": "pending", "completed": null },
    "po-approval": { "status": "pending", "completed": null }
  },
  "artifacts": {
    "developer": "artifacts/$SLUG.developer.md",
    "reviewer": null,
    "po-approval": null
  },
  "timelines": {}
}
```

## Step 4: Create developer artifact

Create `.dev-framework/artifacts/$SLUG.developer.md` with sections:
- Issue Description
- Root Cause
- Fix Applied
- Files Changed
- Risk Assessment

## Step 5: Set as current workspace and create branch

```bash
echo "$SLUG" > .dev-framework/current-workspace
git checkout -b hotfix/$SLUG 2>/dev/null || git checkout hotfix/$SLUG
git add .dev-framework/
git commit -m "hotfix(framework): workspace $SLUG"
```

## Step 6: Confirm and begin

Output:
```
✓ Hotfix workspace: $SLUG
✓ Branch: hotfix/$SLUG
✓ Phases: Developer → Reviewer → PO Approval (Tester/Executor skipped)

Investigating issue...
```

Immediately act as **Developer**: diagnose "$ARGUMENTS", implement the fix, and populate `.dev-framework/artifacts/$SLUG.developer.md`.

When done, say **continue** to advance to Reviewer.
