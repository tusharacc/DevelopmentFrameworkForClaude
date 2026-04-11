# Developer Artifact — BUG-001

## Bug Summary
Review and Test phases not triggered correctly after Developer phase completes. The `tester` role description conflated writing test cases with executing them, causing ambiguous "execute" behaviour. Additionally, the phase chain lacked an `executor` step and a `po-approval` step entirely.

## Root Cause Analysis

### Issue 1 — Tester role description causes deploy-like behaviour
In `skills/hand-off/SKILL.md` Step 7, the tester agent was instructed to:
> "create and execute a test plan against acceptance criteria"

The word "execute" caused the agent to attempt running/deploying the code rather than simply writing test cases and handing off to a dedicated executor.

### Issue 2 — Missing phases in the chain
Phase sequence was:
```
developer → reviewer → tester → complete
```
Required sequence per workflow spec:
```
developer → reviewer → (fix high/medium, file low as bugs) → tester → executor → po-approval → complete
```

### Issue 3 — Reviewer phase had no severity-based branching
The reviewer had no instruction to:
- Separate comments by severity (high / medium / low)
- Loop back to developer if high/medium issues exist
- File low-priority comments as new bugs

## Fix Implementation

### Files Changed
1. `skills/hand-off/SKILL.md`
   - Updated phase sequence map to include `executor` and `po-approval`
   - Fixed `tester` agent instruction: writes test cases only, does NOT execute
   - Added `executor` agent instruction: runs test cases written by tester
   - Added `po-approval` agent instruction: reviews executor findings and approves/rejects
   - Added reviewer → branching logic: high/medium → back to developer; low → file as bug

## Decisions Made
- Reviewer loops back to `developer` phase if high or medium issues found
- Low-priority review comments are automatically filed as new BUG entries
- Executor is a distinct phase that only runs tests, does not write them
- PO approval is the final gate before `complete`
