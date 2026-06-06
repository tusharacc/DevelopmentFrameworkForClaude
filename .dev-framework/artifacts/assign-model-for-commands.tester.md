# Tester Artifact — assign-model-for-commands

## Test Plan

### TC-01 — Total model count
**Command:** `grep -r "^model:" skills/ agents/ | wc -l`
**Expected:** 29
**Status:** Pending

### TC-02 — Opus count
**Command:** `grep -r "^model: opus" skills/ agents/ | wc -l`
**Expected:** 1
**Status:** Pending

### TC-03 — Sonnet count
**Command:** `grep -r "^model: sonnet" skills/ agents/ | wc -l`
**Expected:** 6
**Status:** Pending

### TC-04 — Haiku count
**Command:** `grep -r "^model: haiku" skills/ agents/ | wc -l`
**Expected:** 22
**Status:** Pending

### TC-05 — architect-design is opus
**Command:** `grep "^model:" agents/architect-design.md`
**Expected:** `model: opus`
**Status:** Pending

### TC-06 — developer-executor is haiku
**Command:** `grep "^model:" agents/developer-executor.md`
**Expected:** `model: haiku`
**Status:** Pending

### TC-07 — tester-validation is haiku
**Command:** `grep "^model:" agents/tester-validation.md`
**Expected:** `model: haiku`
**Status:** Pending

### TC-08 — po-requirements unchanged (sonnet)
**Command:** `grep "^model:" agents/po-requirements.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-09 — reviewer-quality unchanged (sonnet)
**Command:** `grep "^model:" agents/reviewer-quality.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-10 — observer-observability unchanged (sonnet)
**Command:** `grep "^model:" agents/observer-observability.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-11 — explore is sonnet
**Command:** `grep "^model:" skills/explore/skill.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-12 — init-brownfield is sonnet
**Command:** `grep "^model:" skills/init-brownfield/skill.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-13 — observe is sonnet
**Command:** `grep "^model:" skills/observe/skill.md`
**Expected:** `model: sonnet`
**Status:** Pending

### TC-14 — start-of-day is haiku
**Command:** `grep "^model:" skills/start-of-day/skill.md`
**Expected:** `model: haiku`
**Status:** Pending

### TC-15 — end-of-day is haiku
**Command:** `grep "^model:" skills/end-of-day/skill.md`
**Expected:** `model: haiku`
**Status:** Pending

### TC-16 — No skill has model: defined more than once
**Command:** `for f in skills/*/skill.md; do count=$(grep -c "^model:" "$f" 2>/dev/null); [ "$count" -gt 1 ] && echo "DUPLICATE: $f"; done; echo "done"`
**Expected:** `done` (no DUPLICATE lines)
**Status:** Pending

### TC-17 — model: key is inside frontmatter (not in body)
**Command:** `for f in skills/*/skill.md agents/*.md; do awk '/^---/{n++} n==1 && /^model:/{found=1} n>=2 && /^model:/{print "OUTSIDE_FRONTMATTER: " FILENAME} END{if(!found && n>0) print "NO_MODEL: " FILENAME}' "$f"; done 2>/dev/null | grep -v "^$" || echo "ALL_OK"`
**Expected:** `ALL_OK`
**Status:** Pending

### TC-18 — No skill content lines modified
**Command:** `git diff main..HEAD -- skills/ | grep "^[-+]" | grep -v "^[-+][-+][-+]" | grep -v "^[-+]model:" | grep -v "^[-+]---" | head -20`
**Expected:** Empty output (only model: and --- lines changed in skills)
**Status:** Pending
