# Developer Artifact — BUG-008

## Bug Summary
Two related hook defects caused the dev-framework phase gate to malfunction across all Claude Code sessions:

1. **`hooks/hooks.json` used relative paths** — `bash hooks/check-bash-phase.sh` only resolves when CWD is the DevelopmentFrameworkForClaude project root. Since the plugin is enabled globally, hooks run in every project. In any other project (e.g. MyInvestmentManager) bash exits with `No such file or directory`, producing the visible error: `PreToolUse:Bash hook error — Failed with non-blocking status code`.

2. **`hooks/check-phase.sh` allowlist used `^` anchors** — The allowlist patterns (`^\.dev-framework/`, `^hooks/`, etc.) anchor to the start of the string. Claude Code's Write/Edit tools always pass absolute paths (e.g. `/Users/foo/.../DevelopmentFrameworkForClaude/.dev-framework/state.json`). The `^` anchor never matches an absolute path, so the allowlist was bypassed — legitimate framework file writes were blocked whenever the current workspace phase was not `developer`.

## Root Cause Analysis

### Defect 1 — Relative hook paths in hooks.json
`hooks/hooks.json` contained:
```json
"command": "bash hooks/check-bash-phase.sh"
"command": "bash hooks/check-phase.sh"
```
Bash resolves these relative to `$PWD`. When running in a different project, `$PWD/hooks/` doesn't exist.

### Defect 2 — `^` anchor mismatch for absolute paths in check-phase.sh
`hooks/check-phase.sh` line 50:
```bash
if echo "$FILE_PATH" | grep -q "^\.dev-framework/\|^\.dev-framework\\\\"; then
```
And line 55:
```bash
if echo "$FILE_PATH" | grep -qE "^CLAUDE\.md$|^hooks/|^skills/|^agents/|^\.claude"; then
```
The `^` anchor requires the path to start with `.dev-framework/` or `hooks/`. Absolute paths start with `/Users/...`, so the pattern never matches.

## Fix Implementation

### Fix 1 — hooks/hooks.json: absolute paths
Changed both hook commands to absolute paths so they resolve correctly in any project:
```json
"command": "bash /Users/tusharsaurabh/Documents/Projects/AI/DevelopmentFrameworkForClaude/hooks/check-phase.sh"
"command": "bash /Users/tusharsaurabh/Documents/Projects/AI/DevelopmentFrameworkForClaude/hooks/check-bash-phase.sh"
```

### Fix 2 — hooks/check-phase.sh: remove `^` anchors
Line 50 changed from:
```bash
if echo "$FILE_PATH" | grep -q "^\.dev-framework/\|^\.dev-framework\\\\"; then
```
To:
```bash
if echo "$FILE_PATH" | grep -qE '\.dev-framework/'; then
```

Line 55 changed from:
```bash
if echo "$FILE_PATH" | grep -qE "^CLAUDE\.md$|^hooks/|^skills/|^agents/|^\.claude"; then
```
To:
```bash
if echo "$FILE_PATH" | grep -qE "CLAUDE\.md|hooks/|skills/|agents/|\.claude"; then
```

## Files Changed
- `hooks/hooks.json` — absolute paths for both hook commands
- `hooks/check-phase.sh` — removed `^` anchors from allowlist patterns (lines 50, 55)

## Testing Notes
- Verify hooks run without error when Claude Code is open in a different project (e.g. MyInvestmentManager)
- Verify writes to `.dev-framework/` are allowed when current workspace is in `complete` phase
- Verify writes to `hooks/`, `skills/`, `CLAUDE.md` are allowed regardless of phase
- Verify non-framework file writes are still blocked outside `developer` phase
