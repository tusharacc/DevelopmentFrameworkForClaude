# Architect Artifact — explore-skill

## System Design

Single new file: `skills/explore/SKILL.md`. No changes to any existing skill. No framework state touched.

```
New:  skills/explore/SKILL.md
```

The skill has two distinct phases:
1. **Conversation loop** — Claude asks, developer answers, repeat
2. **Write phase** — triggered by completion signal, writes brief, outputs handoff prompt

---

## Conversation Flow Design

```
invoke explore "rough idea"
        │
        ▼
[Intro] Acknowledge topic, share what the session will cover (1-2 sentences)
        │
        ▼
[Round 1] Ask 2–3 opening questions about problem, users, and what exists today
        │
   developer answers
        │
        ▼
[Round N] Respond to answers, dig deeper OR shift to uncovered area
          (feasibility, approaches, constraints, success criteria, risks)
        │
   developer answers
        │
        ▼
[Completion signal detected?] ──NO──► continue loop
        │YES
        ▼
[Write] Synthesise conversation → .dev-framework/explore-$SLUG.md
        │
        ▼
[Output] Handoff prompt with suggested workflow type and next command
```

---

## Components

| Component | Description |
|-----------|-------------|
| `skills/explore/SKILL.md` | Single file. Frontmatter + full skill instructions |

---

## Skill Structure Design

### Frontmatter
```yaml
name: explore
description: Explore and harden a vague idea or requirement through back-and-forth discussion before starting a formal workflow. Produces a markdown brief ready for the PO agent.
arguments: topic-or-idea
examples:
  - /dev-framework:explore "add webhook support to the API"
  - /dev-framework:explore "not sure how to handle user sessions"
  - /dev-framework:explore
```

### Step 1 — Parse topic
- If `$ARGUMENTS` is non-empty: use it as the starting topic
- If empty: ask "What would you like to explore today?"

### Step 2 — Announce session
One-line acknowledgement of the topic + what the session will do:
> "Let's explore **$TOPIC**. I'll ask questions to help harden the idea — answer what you know, and say 'done' or 'wrap it up' whenever you're ready for the brief."

### Step 3 — Conversation loop

**Coverage checklist** (Claude tracks internally, not shown to user):
- [ ] Problem being solved and for whom
- [ ] What already exists (codebase / ecosystem / prior art)
- [ ] Technical approaches and feasibility
- [ ] Constraints (performance, security, scope, compatibility)
- [ ] Definition of success
- [ ] Edge cases and risks

**Per-round behaviour:**
- Read the developer's last answer
- Mark off any checklist items the answer touched
- Choose the 2–3 most important uncovered items
- Ask about them in natural conversational language — not as a numbered list
- Respond to what was said before pivoting to new questions (don't ignore answers)

**Tone:** senior developer peer, not interviewer. Use "I'm thinking..." / "That makes me wonder..." / "One thing we should check..." rather than formal "Question 3:"

### Step 4 — Completion detection

Treat any of the following as a done signal (case-insensitive):
`done`, `that's enough`, `looks good`, `ready`, `wrap it up`, `wrap up`, `summarise`, `summarize`, `write it up`, `hand to po`, `hand off`, `finish`, `finished`, `stop`

When detected: acknowledge and proceed to Step 5.
> "Got it — let me write up the brief."

### Step 5 — Write brief

Derive `$SLUG` from `$TOPIC`: lowercase, hyphens, remove special characters. Max 40 chars.

Write `.dev-framework/explore-$SLUG.md`:

```markdown
# Exploration Brief — $TOPIC
*Explored: $DATE*

## Idea
$one_line_summary

## Problem Being Solved
$problem_and_users — who has this problem, in what context

## Context
$existing_behaviour_prior_art_codebase_patterns (what exists today that is relevant)

## Proposed Approaches
$approach_1 — $tradeoffs
$approach_2 — $tradeoffs (if discussed)

## Constraints & Risks
$bullet_list

## Open Questions
$unresolved_items_for_po_or_architect (prefixed "- [ ]")

## Suggested Workflow Type
**$type** — $one_sentence_reason
```

Rules:
- Under 60 lines total
- If a section was not covered in conversation, write `*(not explored)*` rather than leaving it blank
- Synthesise — do not transcript the conversation verbatim

### Step 6 — Handoff prompt

```
✓ Exploration complete: .dev-framework/explore-$SLUG.md

Suggested next step:
  /dev-framework:$workflowType "$TOPIC"

When starting, share the brief with PO:
  "Read .dev-framework/explore-$SLUG.md before asking requirements questions."
```

---

## Tech Decisions

**TD-1: No file I/O until completion**
The conversation loop is purely in-context. No intermediate writes. Only when the developer signals done does the skill write the output file. Reason: incomplete exploration files would pollute `.dev-framework/`.

**TD-2: Coverage checklist is internal**
Claude tracks what has been covered to avoid asking the same thing twice, but does not show the checklist to the developer. Showing it would make the conversation feel like a form.

**TD-3: Completion signal list is broad**
"Done", "wrap up", "hand to PO", "finish" etc. all trigger write phase. Better to over-detect than require a specific magic word.

**TD-4: Output in `.dev-framework/` root, not `artifacts/`**
The brief is pre-workflow and not tied to any workspace. `artifacts/` is reserved for workspace phase artifacts. Using the root of `.dev-framework/` keeps it clearly separate.

**TD-5: No git ops**
The explore brief is ephemeral — the developer may decide not to proceed. Git commits happen when a formal workflow starts. If the developer wants to save it, they can commit manually.

---

## Open Questions

None — scope is minimal and fully covered by PO artifact.
