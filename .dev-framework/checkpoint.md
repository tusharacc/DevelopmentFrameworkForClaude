# Dev Framework Checkpoint
**Date**: 2026-04-22
**Workspace**: (none)
**Phase**: (none)
**Branch**: bugfix/bugfix-bug-009-010
**Workflow**: (none)

## Done this session
- fix(bugs): close BUG-009 and BUG-010, file GitHub issues #2 #3
- archive(bugfix-bug-009-010): workflow complete
- phase(bugfix-bug-009-010): full workflow complete — reviewer → tester → executor → po-approval
- fix(BUG-009, BUG-010): self-locating hooks, exact prefix allowlist
- archive(bugfix-bug-008): workflow complete
- phase(bugfix-bug-008): tester → executor → po-approval → complete
- phase(bugfix-bug-008): developer complete → reviewer complete → tester begins
- fix(bugfix-bug-008): create workspace and document BUG-008 hook path fixes
- fix(BUG-008): hooks use absolute paths and match absolute file paths in allowlist

## Where things stand
Fixed 3 hook bugs (BUG-008, BUG-009, BUG-010) that caused `PreToolUse:Bash hook error`
in non-framework projects. Hooks now self-locate via `$BASH_SOURCE` and `git rev-parse`,
use no hardcoded paths, and apply exact prefix allowlisting. Both workspaces archived.
GitHub issues filed: #2 (BUG-008), #3 (BUG-009/010).

## Pending decisions
- [ ] Fix BUG-002: no max loop count for reviewer → developer cycles
- [ ] Fix BUG-003: PO artifact missing failed test list from executor
- [ ] Fix BUG-004: Step 0 stop instruction is passive
- [ ] Fix BUG-005: start-of-day no fallback for ambiguous response
- [ ] Fix BUG-006: explore skill no mid-conversation guidance
- [ ] Fix BUG-007: explore skill no wrap-up nudge
- [ ] Merge bugfix branches back to main
- [ ] Archive explore-skill workspace (still unarchived)

## Next action
Merge bugfix branches to main and push, or start tackling the remaining open low-severity
bugs (BUG-002 through BUG-007). Run /dev-framework:start-of-day to resume.
