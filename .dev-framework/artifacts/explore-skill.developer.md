# Developer Artifact — explore-skill

## Implementation Plan

Single file: `skills/explore/SKILL.md`. No other files modified.

## Files Changed

| File | Change |
|------|--------|
| `skills/explore/SKILL.md` | Created |

## Code Summary

**Skill structure:**
- 6 steps: parse topic → open session → conversation loop → completion detection → write brief → handoff prompt
- Frontmatter description is broad enough for Claude to auto-invoke when user has a vague/unhardened idea

**Conversation loop (Step 3):**
- Internal 6-area coverage checklist (A–F) tracked silently — never shown to developer
- 2–3 questions per turn, peer tone, responds to answers before pivoting
- Natural language prompts guide each round

**Completion detection (Step 4):**
- 16 trigger phrases covering natural variations: "done", "wrap it up", "hand to PO", "let's go", etc.
- Case-insensitive match after every developer turn

**Output brief (Step 5):**
- Written to `.dev-framework/explore-$SLUG.md` (not `artifacts/`) — pre-workflow location
- 7 sections with *(not explored)* fallback for uncovered areas
- Hard 60-line limit — synthesise, do not transcribe
- Slug derived from topic: lowercase + hyphens, max 40 chars

**Handoff (Step 6):**
- Prints suggested command and PO tip
- Explicitly: "Stop here. Do not invoke any other skill."

## Decisions Made

- Completion detection happens after EVERY developer turn (not just when Claude re-prompts) — catches mid-sentence signals
- "Let's go" and "lets go" included as completion signals — common informal phrasing
- No git operations — brief is ephemeral until developer formalises
- `*(not explored)*` sentinel preferred over blank sections so PO knows what to ask about
