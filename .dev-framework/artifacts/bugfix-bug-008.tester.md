# Tester Artifact — BUG-008

## Test Plan
Validate that both defects from BUG-008 are resolved:
1. Hooks no longer fail with "No such file or directory" in other projects
2. Writes to `.dev-framework/` and framework files are correctly allowed through the phase gate regardless of phase

All tests are defined here — execution is performed by the Executor.

---

## Test Cases

### Group A — hooks.json absolute paths

**TC-A1: Hook runs without error in a different project**
- Setup: Open Claude Code in `/Users/tusharsaurabh/Documents/Projects/MyInvestmentManager` (no `hooks/` dir)
- Action: Run any Bash command (e.g. `ls`)
- Expected: No `PreToolUse:Bash hook error` in the output; command executes normally
- Pass criteria: Zero hook errors

**TC-A2: Hook runs without error in DevelopmentFrameworkForClaude**
- Setup: Open Claude Code in this project
- Action: Run any Bash command
- Expected: Hook executes silently; no "No such file or directory" error
- Pass criteria: Zero hook errors

**TC-A3: hooks.json commands are absolute paths**
- Action: Read `hooks/hooks.json`
- Expected: Both `command` values start with `/Users/tusharsaurabh/Documents/Projects/AI/DevelopmentFrameworkForClaude/hooks/`
- Pass criteria: No relative path (`bash hooks/`) present

---

### Group B — check-phase.sh allowlist (absolute path matching)

**TC-B1: Write to .dev-framework/ allowed when workspace is in non-developer phase**
- Setup: Active workspace in `complete` phase
- Action: Attempt to write/edit any file under `.dev-framework/`
- Expected: Write succeeds; no `BLOCKED` message from hook
- Pass criteria: File is written successfully

**TC-B2: Write to hooks/ allowed when workspace is in non-developer phase**
- Setup: Active workspace in `reviewer` phase
- Action: Attempt to edit `hooks/check-phase.sh`
- Expected: Write succeeds; no `BLOCKED` message
- Pass criteria: File is written successfully

**TC-B3: Write to skills/ allowed when workspace is in non-developer phase**
- Setup: Active workspace in `po-approval` phase
- Action: Attempt to edit any file under `skills/`
- Expected: Write succeeds; no `BLOCKED` message
- Pass criteria: File is written successfully

**TC-B4: Write to CLAUDE.md allowed in any phase**
- Setup: Active workspace in any non-developer phase
- Action: Attempt to edit `CLAUDE.md`
- Expected: Write succeeds
- Pass criteria: File is written successfully

**TC-B5: Write to source file still blocked outside developer phase**
- Setup: Active workspace in `reviewer` phase
- Action: Attempt to write to a non-framework source file (e.g. `/tmp/test.py`)
- Expected: Hook outputs `BLOCKED` message and exits 2
- Pass criteria: Write is rejected with phase gate message

**TC-B6: Absolute path to .dev-framework/ is matched correctly**
- Action: Inspect `hooks/check-phase.sh` line 50
- Expected: Pattern is `grep -qE '\.dev-framework/'` (no `^` anchor)
- Pass criteria: `^` anchor absent from line 50

**TC-B7: Absolute path to hooks/ is matched correctly**
- Action: Inspect `hooks/check-phase.sh` line 55
- Expected: Pattern is `grep -qE "CLAUDE\.md|hooks/|skills/|agents/|\.claude"` (no `^`)
- Pass criteria: `^` anchors absent from line 55

---

### Group C — check-bash-phase.sh (unchanged — regression check)

**TC-C1: Bash commands without write patterns are still allowed**
- Setup: Active workspace in non-developer phase
- Action: Run `git status` or `ls`
- Expected: Command runs normally; no block
- Pass criteria: Zero blocks

**TC-C2: Bash commands writing to .dev-framework/ are still allowed**
- Setup: Active workspace in non-developer phase
- Action: Run a command that writes to `.dev-framework/` (e.g. via python3)
- Expected: Command allowed through
- Pass criteria: Zero blocks

**TC-C3: Bash write to source file still blocked outside developer phase**
- Setup: Active workspace in non-developer phase
- Action: Run `echo "x" > /tmp/source.py` (or similar shell redirect to non-framework path)
- Expected: Hook blocks with `BLOCKED` message
- Pass criteria: Command rejected
