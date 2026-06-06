# Developer Artifact — assign-model-for-commands

## Summary
Added `model:` frontmatter key to all 23 skills and updated 3 agent model values. No logic or content changes — purely additive frontmatter edits.

## Files Changed

### Agents (3 value changes)
- `agents/architect-design.md` — `sonnet` → `opus`
- `agents/developer-executor.md` — `sonnet` → `haiku`
- `agents/tester-validation.md` — `sonnet` → `haiku`

### Skills (23 insertions — `model:` after `name:`)
**Haiku (20):** start-of-day, end-of-day, status, list-bugs, list-workspaces, view-bug, switch-workspace, new-feature, hand-off, handoff-orchestrator, continue, bugfix, hotfix, minor-enhancement, upgrade-feature, archive-feature, framework-manager, artifact-generator, bug-manager, create-bug

**Sonnet (3):** explore, init-brownfield, observe

## Implementation Notes
All insertions target the `name: <slug>` line, which is unique in every file. No frontmatter structure changes were needed — all files had valid `---` delimiters.

## Test Commands
```bash
# Total count must be 29
grep -r "^model:" skills/ agents/ | wc -l

# Tier distribution
grep -r "^model: opus"   skills/ agents/ | wc -l  # → 1
grep -r "^model: sonnet" skills/ agents/ | wc -l  # → 6
grep -r "^model: haiku"  skills/ agents/ | wc -l  # → 22
```

Verified output: 29 total, 1 opus, 6 sonnet, 22 haiku. All pass.
