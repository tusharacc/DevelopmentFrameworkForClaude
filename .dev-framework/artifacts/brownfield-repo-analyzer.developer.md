# Developer Artifact — brownfield-repo-analyzer

## Summary

Implemented the `/dev-framework:init-brownfield` skill as a single self-contained `SKILL.md` file at `skills/init-brownfield/SKILL.md`. The skill instructs Claude to run targeted bash commands for repository signal detection, resolve ambiguities interactively, show a discovery summary with user confirmation, and then create or update `CLAUDE.md` with confirmed findings. No framework state (`.dev-framework/`) is created or modified by this command.

## Files Changed

| File | Action | Description |
|---|---|---|
| `skills/init-brownfield/SKILL.md` | Created | Complete 272-line skill prompt implementing all six phases |

## Implementation Notes

The skill follows the single-file convention of every other skill in this framework (new-feature, bugfix, explore, etc.). All detection logic is expressed as bash commands that Claude runs inline — no supporting scripts, no companion utilities.

**Six phases implemented:**
1. **Pre-flight** — git check, cwd note, subdirectory warning
2. **Signal detection** — 8 targeted `find`/`ls`/`read` operations covering stack, structure, commands, linters, CI, and existing docs
3. **Ambiguity resolution** — blocks on multiple test runners or monorepo roots; auto-resolves conflicting README vs config file commands (prefers config, notes discrepancy)
4. **Discovery summary** — structured output grouped by Stack / Commands / Structure / Conventions / Documentation / CI; user must confirm or correct before anything is written
5. **CLAUDE.md write/update** — Case A (create from scratch) for missing/empty files; Case B (semantic diff with + / ~ / = change list, explicit approval required) for existing files; idempotency: if no `+` or `~` changes exist, reports "up to date" and skips write
6. **Post-write confirmation** — absolute path, line count, suggested next command

**Key safety properties enforced by the prompt:**
- Never writes CLAUDE.md without user confirmation (both cases)
- Case B preserves all sections not covered by analysis verbatim
- Monorepo root list capped at 5 entries to avoid overwhelming the user
- `node_modules`, `.git`, `vendor`, `__pycache__`, `.next`, `dist`, `build` excluded from all `find` scans

## Testing Notes

Manual verification checklist for the executor:
- Run `/dev-framework:init-brownfield` in a repo with no CLAUDE.md → confirm Case A creates it
- Run `/dev-framework:init-brownfield` in a repo with an existing CLAUDE.md → confirm Case B shows diff and requires approval
- Run twice on an unchanged repo → confirm "no changes needed" on second run (idempotency)
- Add both `jest.config.js` and `vitest.config.ts` → confirm ambiguity prompt fires
- Add `package.json` at two different depth-1 paths → confirm monorepo prompt fires
- Run in a non-git directory → confirm warning is shown but analysis continues
