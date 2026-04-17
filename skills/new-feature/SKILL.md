---
name: new-feature
description: Start a new feature workflow - creates workspace, artifacts, git branch, and begins PO requirements phase
arguments: feature-name
examples:
  - /dev new-feature "User authentication"
  - /dev new-feature auth-v2
---

You are starting a new feature development workflow for: **$ARGUMENTS**

Follow these steps exactly:

## Step 1: Prepare workspace name

Convert the feature name "$ARGUMENTS" to a slug:
- Lowercase
- Replace spaces with hyphens
- Remove special characters

Example: "User Authentication System" → `user-authentication-system`

## Step 2: Create workspace directories

Run these commands:
```bash
mkdir -p .dev-framework/workspaces/$SLUG
mkdir -p .dev-framework/artifacts
mkdir -p .dev-framework/bugs
mkdir -p .dev-framework/archived
```

## Step 3: Write state.json

Create `.dev-framework/workspaces/$SLUG/state.json`:
```json
{
  "name": "$SLUG",
  "type": "feature",
  "workflowType": "full",
  "created": "<current ISO timestamp>",
  "currentPhase": "po",
  "status": "active",
  "branch": "feature/$SLUG",
  "roles": {
    "po": { "status": "in-progress", "completed": null },
    "architect": { "status": "pending", "completed": null },
    "developer": { "status": "pending", "completed": null },
    "reviewer": { "status": "pending", "completed": null },
    "tester": { "status": "pending", "completed": null },
    "executor": { "status": "pending", "completed": null },
    "po-approval": { "status": "pending", "completed": null }
  },
  "artifacts": {
    "po": null,
    "architect": null,
    "developer": null,
    "reviewer": null,
    "tester": null,
    "executor": null,
    "po-approval": null
  },
  "timelines": {}
}
```

## Step 4: Write context.md

Create `.dev-framework/workspaces/$SLUG/context.md` with the workspace name, type, creation date, current phase (po), and status (active).

## Step 5: Create PO artifact template

Create `.dev-framework/artifacts/$SLUG.po.md` with a requirements template including sections for: Problem Statement, User Stories, Functional Requirements, Non-Functional Requirements, Acceptance Criteria, Edge Cases, Dependencies.

Update state.json to set `artifacts.po` to `artifacts/$SLUG.po.md`.

## Step 6: Set as current workspace

Write the slug to `.dev-framework/current-workspace`:
```bash
echo "$SLUG" > .dev-framework/current-workspace
```

## Step 7: Create git branch and commit

```bash
git checkout -b feature/$SLUG 2>/dev/null || git checkout feature/$SLUG
git add .dev-framework/
git commit -m "feat(framework): new workspace $SLUG"
```

If git is not available or fails, skip silently.

## Step 8: Confirm and begin PO phase

Output a brief summary:
```
✓ Workspace created: $SLUG
✓ Branch: feature/$SLUG
✓ Phase: PO Requirements

Starting requirements gathering...
```

Then immediately act as the **Product Owner agent**: begin asking the user focused discovery questions to gather requirements for "$ARGUMENTS". Keep questions concise — combine related topics. Your goal is to produce a complete `.dev-framework/artifacts/$SLUG.po.md` artifact.

When requirements are complete, tell the user to run `/dev hand-off` to advance to the Architect phase.
