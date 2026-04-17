# Architect Design — mandatory-plugin-enforcement

---

## System Design

Enforcement operates at two independent layers so that neither layer alone is a single point of failure:

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1 — Conversational (CLAUDE.md)                   │
│  Loaded every session. Rules Claude follows when        │
│  deciding how to respond to any user message.           │
│  Handles: session start, intent detection, phase        │
│  gates, hand-off trigger words, workflow routing.       │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  Layer 2 — Tool hooks (hooks/hooks.json)                 │
│  Fires before Write/Edit/Bash tool calls. Reads          │
│  current-workspace and state.json. Blocks tool           │
│  execution if phase gate is violated.                    │
│  Handles: hard enforcement when Claude would otherwise  │
│  comply with a user override request.                   │
└─────────────────────────────────────────────────────────┘
```

Both layers read the same source of truth: `.dev-framework/current-workspace` and `.dev-framework/workspaces/$SLUG/state.json`.

---

## Components

### C1: `CLAUDE.md` (new — project root)
The primary enforcement document. Claude Code loads this automatically at the start of every session. Contains:
- **Session start protocol**: check for active workspace; resume or ask change type
- **Intent classifier**: keyword/phrase patterns → workflow type mapping
- **Phase gate rules**: what Claude may/may not do in each phase
- **Hand-off trigger vocabulary**: words that fire hand-off automatically
- **Workflow type definitions**: phase chains per change type

### C2: `hooks/hooks.json` (new)
Plugin-level hooks that enforce phase gates at the tool layer:
- `PreToolUse` on `Write` and `Edit`: blocks if `currentPhase ≠ developer`
- `PreToolUse` on `Bash`: blocks shell commands that modify files if `currentPhase ≠ developer`
- Hook script reads `.dev-framework/current-workspace` and `state.json` to make the decision

### C3: `skills/hotfix/SKILL.md` (new)
Abbreviated workflow for critical production issues:
`Developer → Reviewer → PO Approval → Complete`
Tester and Executor skipped. Workspace type = `hotfix`.

### C4: `skills/minor-enhancement/SKILL.md` (new)
Abbreviated workflow for small improvements:
`Developer → Reviewer → PO Approval → Complete`
PO, Architect, Tester, Executor skipped. Workspace type = `minor`.

### C5: `skills/continue/SKILL.md` (new)
Intercepts natural-language hand-off triggers ("continue", "next", "done", etc.) and executes the hand-off skill. This is the skill Claude invokes when it detects a hand-off intent without a slash command.

### C6: `skills/hand-off/SKILL.md` (update)
Add phase sequence branches for `hotfix` and `minor` workspace types so the correct next phase is calculated.

---

## Data Models

### state.json — new `workflowType` field
```json
{
  "name": "workspace-slug",
  "type": "feature | upgrade | bugfix | hotfix | minor",
  "workflowType": "full | bugfix | hotfix | minor",
  ...
}
```
`workflowType` is used by the hook script and the hand-off skill to look up the correct phase sequence without re-deriving it from `type`.

### Phase sequence map (used by hand-off and hooks)
```json
{
  "full":    ["po", "architect", "developer", "reviewer", "tester", "executor", "po-approval"],
  "bugfix":  ["developer", "reviewer", "tester", "executor", "po-approval"],
  "hotfix":  ["developer", "reviewer", "po-approval"],
  "minor":   ["developer", "reviewer", "po-approval"]
}
```

---

## API Contracts

### Hook script: `hooks/check-phase.sh`
Called by `hooks/hooks.json` before every Write/Edit tool use.

**Input** (via stdin, JSON):
```json
{ "tool_name": "Write", "tool_input": { "file_path": "..." } }
```

**Behaviour**:
1. Read `.dev-framework/current-workspace`
2. If file does not exist or is empty → exit 0 (no workspace, allow — CLAUDE.md handles it conversationally)
3. Read `state.json` for that workspace
4. If `currentPhase ≠ "developer"` → exit 2 with message: `"[dev-framework] Blocked: file edits are only allowed in the developer phase. Current phase: $currentPhase. Run /dev hand-off to reach the developer phase."`
5. Otherwise → exit 0 (allow)

Exit code 2 = block with message shown to user.

---

## Tech Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Primary enforcement mechanism | `CLAUDE.md` | Loaded automatically every session by Claude Code; no user action required |
| Secondary enforcement | Plugin hooks (`hooks/hooks.json`) | Hard blocks at tool layer; cannot be bypassed by Claude agreeing with a user override |
| Hook script language | `bash` | No runtime dependencies; available everywhere; reads JSON with `grep`/`python3 -c` |
| Phase sequence storage | `workflowType` field in `state.json` | Single source of truth; hook and hand-off skill read the same value |
| `continue` handling | Dedicated skill `skills/continue/SKILL.md` | Allows Claude to intercept natural language; the skill description makes it model-invokable automatically |
| New workspace skills | Separate files per type (`hotfix`, `minor-enhancement`) | Follows existing pattern; easy to extend |

---

## Open Questions

_None — all decisions resolved above._
