# Tester Artifact — BUG-009 & BUG-010

## Test Plan
Validate both fixes:
1. BUG-009: hooks resolve correctly regardless of repo location (no hardcoded paths)
2. BUG-010: allowlist only permits files inside the framework project, not false-positive matches

---

## Test Cases

### Group A — BUG-009: git-based hook resolution

**TC-A1: Hook resolves correctly inside dev-framework project**
- Setup: CWD = DevelopmentFrameworkForClaude project root
- Action: Simulate the hooks.json command — run `bash -c 'r=$(git rev-parse --show-toplevel 2>/dev/null); h="$r/hooks/check-phase.sh"; echo "found=$( [ -f "$h" ] && echo yes || echo no )"'`
- Expected: `found=yes`

**TC-A2: Hook exits 0 gracefully in a project without hooks/check-phase.sh**
- Setup: CWD = any other git repo (e.g. MyInvestmentManager)
- Action: Run the hooks.json command
- Expected: exits 0 with no error output

**TC-A3: No hardcoded /Users/... path anywhere in hooks.json**
- Action: Read `hooks/hooks.json` and check for `/Users/`
- Expected: No occurrences of `/Users/` in the file

**TC-A4: BASH_SOURCE self-location in check-phase.sh resolves FRAMEWORK_ROOT correctly**
- Action: Run `bash -c 'source hooks/check-phase.sh 2>/dev/null; echo $FRAMEWORK_ROOT'` or inspect SCRIPT_DIR logic
- Expected: FRAMEWORK_ROOT = absolute path to DevelopmentFrameworkForClaude

### Group B — BUG-010: exact prefix allowlist

**TC-B1: File inside FRAMEWORK_ROOT/.dev-framework/ is allowed**
- Setup: Active workspace in non-developer phase
- Action: Simulate hook with FILE_PATH = `$FRAMEWORK_ROOT/.dev-framework/checkpoint.md`
- Expected: exits 0

**TC-B2: File inside FRAMEWORK_ROOT/hooks/ is allowed**
- Action: Simulate hook with FILE_PATH = `$FRAMEWORK_ROOT/hooks/check-phase.sh`
- Expected: exits 0

**TC-B3: File at /src/cool-hooks/app.py is NOT allowed (false positive fix)**
- Action: Simulate hook with FILE_PATH = `/src/cool-hooks/app.py`
- Expected: exits 2 (BLOCKED)

**TC-B4: File at /my-skills/config.js is NOT allowed (false positive fix)**
- Action: Simulate hook with FILE_PATH = `/my-skills/config.js`
- Expected: exits 2 (BLOCKED)

**TC-B5: CLAUDE.md at framework root is allowed**
- Action: Simulate hook with FILE_PATH = `$FRAMEWORK_ROOT/CLAUDE.md`
- Expected: exits 0

**TC-B6: A non-framework source file is still blocked outside developer phase**
- Action: Simulate hook with FILE_PATH = `/Users/tusharsaurabh/Documents/Projects/MyInvestmentManager/src/app.py`
- Expected: exits 2 (BLOCKED)

### Group C — Regression

**TC-C1: check-bash-phase.sh still blocks shell redirects to non-framework paths**
- Action: Simulate with COMMAND = `echo x > /tmp/test.py`
- Expected: exits 2 (BLOCKED)

**TC-C2: check-bash-phase.sh still allows writes to .dev-framework/ (relative path in command)**
- Action: Simulate with COMMAND containing `.dev-framework/`
- Expected: exits 0

**TC-C3: No hook errors in this project for normal Bash commands**
- Action: Run `git status` via Bash tool
- Expected: Zero hook errors
