# Developer Artifact — mandatory-plugin-enforcement

## Implementation Plan
Implemented all 6 components from the architect design across 7 files.

## Files Changed

| File | Action | Purpose |
|------|--------|---------|
| `CLAUDE.md` | Created | Session-level enforcement — loaded automatically every session |
| `hooks/hooks.json` | Created | Plugin hook config — blocks Write/Edit outside developer phase |
| `hooks/check-phase.sh` | Created | Hook script — reads state.json and exits 2 to block if phase ≠ developer |
| `skills/hotfix/SKILL.md` | Created | Hotfix workflow — Developer → Reviewer → PO Approval |
| `skills/minor-enhancement/SKILL.md` | Created | Minor enhancement workflow — Developer → Reviewer → PO Approval |
| `skills/continue/SKILL.md` | Created | Intercepts hand-off trigger vocabulary; model-invocable via description |
| `skills/hand-off/SKILL.md` | Updated | Phase sequence now reads `workflowType` from state.json; reviewer branching respects workflow type |

## Code Summary

### CLAUDE.md
- Session start protocol: check active workspace on every session start
- Intent classifier: keyword table maps plain-language requests to workflow types
- Phase gate table: per-phase permissions (what Claude may/may not do)
- Hand-off vocabulary: list of trigger phrases
- Workflow chains: all 5 types (full, bugfix, hotfix, minor, upgrade)
- Artifact verification rules
- Reviewer severity branching rules
- Graceful init (create `.dev-framework/` if absent)

### hooks/check-phase.sh
- Reads `.dev-framework/current-workspace` and `state.json` without jq (uses python3)
- Allows writes to `.dev-framework/`, `CLAUDE.md`, `hooks/`, `skills/`, `agents/` (framework files)
- Blocks all other file writes when `currentPhase ≠ developer`
- Exit 0 = allow, exit 2 = block with descriptive message

### skills/continue/SKILL.md
- Description is written to trigger automatic model invocation when hand-off vocabulary is detected
- Reads `workflowType` and uses the correct phase chain
- Includes artifact completeness verification before advancing

### skills/hand-off/SKILL.md
- Phase sequence now driven by `workflowType` field in state.json
- Reviewer branching uses workflow-aware next-phase lookup (tester for full/bugfix, po-approval for hotfix/minor)

## Decisions Made
- Hook script uses `python3 -c` instead of `jq` to avoid runtime dependency
- Hook allows framework file writes unconditionally (bootstrap concern)
- `workflowType` field added to state.json for all new workspace types; existing full/bugfix workspaces default to their types if field is absent
- `continue` skill description intentionally broad so Claude invokes it for all hand-off synonyms without explicit slash command
