# Complete — explore-skill

## Feature Summary

A standalone pre-workflow skill that helps developers harden vague ideas through structured back-and-forth conversation before committing to a formal workflow.

---

## Phase Trail

| Phase | Outcome |
|-------|---------|
| PO | Standalone skill; conversational loop; markdown brief output to `.dev-framework/`; handoff prompt but no auto-invocation |
| Architect | Single file `skills/explore/SKILL.md`; two-phase design (conversation loop → write on done signal); internal coverage checklist; broad completion vocabulary |
| Developer | `skills/explore/SKILL.md` created with 6 steps; 16 completion triggers; 7-section output template; peer tone instructions |
| Reviewer | R1: `stop` too broad → fixed to `stop exploring`. R2: annotation inside code block would leak → moved outside. BUG-006/007 filed. |
| Tester | 31 test cases across invocation, conversation, completion, brief output, handoff |
| Executor | 31/31 pass. O-01: placeholder substitution is behavioral, accepted. |
| PO Approval | Approved. |

---

## What Was Delivered

**`skills/explore/SKILL.md`** (new)
- Invoked as `/dev-framework:explore "rough idea"` or `/dev-framework:explore`
- 6-step flow: parse topic → open session → conversation loop → completion detection → write brief → handoff prompt
- Acts as senior developer peer — 2–3 questions/turn, responds to answers, tracks 6 coverage areas silently
- 16 completion trigger phrases (case-insensitive, substring match): "done", "wrap it up", "hand to po", "let's go", etc.
- Output: `.dev-framework/explore-$SLUG.md` — 7 sections, ≤60 lines, synthesised not transcribed
- Uncovered sections use `*(not explored)*` sentinel
- Second approach line omitted if only one approach was discussed
- Handoff prompt suggests next workflow command; explicitly stops without auto-invoking anything

---

## Open Follow-ups

| ID | Description |
|----|-------------|
| BUG-006 | No guidance for mid-conversation topic change |
| BUG-007 | No nudge to wrap up when all 6 coverage areas are complete |
