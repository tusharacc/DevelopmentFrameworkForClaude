# Developer Artifact — BUG-009 & BUG-010

## Bug Summary
Two related defects in the hook system introduced during the BUG-008 fix:

- **BUG-009**: `hooks/hooks.json` hardcoded absolute machine-specific paths (`/Users/tusharsaurabh/...`). If the repo is moved or used by another developer, hooks fail identically to the original BUG-008 error.
- **BUG-010**: `hooks/check-phase.sh` allowlist patterns (`hooks/`, `skills/`, `agents/`) are unanchored substrings. A file at `/src/cool-hooks/app.py` or `/my-skills/config.js` would incorrectly bypass the phase gate.

## Root Cause Analysis

### BUG-009 — Hardcoded absolute path in hooks.json
BUG-008's fix replaced relative paths with absolute ones, which solved the cross-project issue but introduced machine-specificity. Any path change (repo move, different user, different OS) breaks the hooks again.

### BUG-010 — Substring allowlist in check-phase.sh
`grep -qE "CLAUDE\.md|hooks/|skills/|agents/|\.claude"` matches ANY path containing those strings — not just paths inside the framework project. False positives could silently permit writes that should be blocked.

## Fix Implementation

### Fix 1 — hooks.json: git-based self-resolution
Replaced hardcoded absolute paths with a `bash -c` command that uses `git rev-parse --show-toplevel` to find the project root at runtime:
```json
"command": "bash -c 'r=$(git rev-parse --show-toplevel 2>/dev/null); h=\"$r/hooks/check-phase.sh\"; [ -f \"$h\" ] && bash \"$h\" || exit 0'"
```
- In the dev-framework project: git finds the root, hook file exists, runs it ✓
- In any other project (e.g. MyInvestmentManager): hook file not found, exits 0 gracefully ✓
- Repo moved or cloned elsewhere: git still finds the root correctly ✓
- No hardcoded paths anywhere ✓

### Fix 2 — check-phase.sh: $BASH_SOURCE self-location + exact prefix allowlist
Added self-location at script top using `$BASH_SOURCE[0]`:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```
Replaced substring allowlist with exact shell prefix matching:
```bash
for prefix in "$FRAMEWORK_ROOT/.dev-framework/" "$FRAMEWORK_ROOT/hooks/" ...; do
    case "$FILE_PATH" in "$prefix"*) exit 0 ;; esac
done
```
Only paths that are literally inside the framework project's directories pass through.

### Fix 3 — check-bash-phase.sh: same $BASH_SOURCE self-location
Applied the same `SCRIPT_DIR`/`FRAMEWORK_ROOT` pattern so STATE_FILE uses the absolute path. Command-content allowlist uses `grep -qF "$FRAMEWORK_ROOT/..."` for exact matching alongside the existing `\.dev-framework/` pattern for relative-path commands run within the project.

## Files Changed
- `hooks/hooks.json` — git-based runtime path resolution, no hardcoded paths
- `hooks/check-phase.sh` — `$BASH_SOURCE` self-location, exact prefix allowlist via `case` statement
- `hooks/check-bash-phase.sh` — `$BASH_SOURCE` self-location, absolute STATE_FILE path, exact command allowlist

## Testing Notes
- Verify hooks.json works when repo is referenced from any CWD inside the project
- Verify hooks exit 0 in a project with no `hooks/check-phase.sh` (e.g. MyInvestmentManager)
- Verify `/src/cool-hooks/app.py` is NOT allowlisted when phase is non-developer
- Verify `/Users/.../DevelopmentFrameworkForClaude/hooks/check-phase.sh` IS allowlisted
- Verify `.dev-framework/` writes still allowed (both relative and absolute paths in commands)
