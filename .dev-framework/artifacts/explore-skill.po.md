# PO Artifact — explore-skill

## Problem Statement

The dev framework assumes requirements are already hardened when a workflow begins. In practice, developers often have a rough idea or vague requirement that needs to be thought through before it is ready for a PO artifact. Without a structured exploration step, developers either skip the thinking process and start with weak requirements, or have unstructured back-and-forth with Claude that produces no reusable output.

The `explore` skill fills this gap: a freeform but structured conversation between Claude and the developer that progressively hardens a vague idea into a crisp brief — ready to hand to the PO agent as input.

---

## User Stories

- As a developer with a half-formed idea, I want to discuss it with Claude so I can think it through before committing to a workflow type or writing requirements.
- As a developer, I want the exploration to feel like a conversation — not a form — so I can surface constraints and edge cases I didn't know to ask about.
- As a developer, I want a clean markdown output at the end of exploration so I can hand it directly to PO without re-explaining everything.
- As a developer, I want the explore skill to be standalone — it does not start a workspace or branch — so I can use it at any time.

---

## Functional Requirements

### FR-1: Standalone invocation
- `explore` is invoked directly: `/dev-framework:explore "rough idea or topic"`
- It does NOT create a workspace, artifact directory, git branch, or state.json
- It does NOT auto-invoke any other skill
- It has no phase gates — it operates outside the workflow entirely

### FR-2: Conversational exploration loop
- Claude acts as a **senior developer / technical advisor** role during the session
- Claude asks focused questions to progressively harden the idea, covering:
  - What problem is being solved and for whom
  - What already exists (in the codebase or ecosystem)
  - Technical feasibility and likely approaches
  - Constraints (performance, security, compatibility, scope)
  - What success looks like
  - Edge cases and risks
- Claude does NOT ask all questions at once — it asks 2–3 at a time, waits for answers, then digs deeper
- The conversation continues until the developer says they are satisfied (e.g. "done", "looks good", "that's enough")

### FR-3: Exploration output — markdown brief
- When the developer signals completion, Claude writes `.dev-framework/explore-$SLUG.md`
- The file contains:
  - **Idea / Topic** — one-line summary
  - **Problem being solved** — extracted from conversation
  - **Context** — relevant existing behaviour, codebase patterns, or ecosystem facts surfaced during exploration
  - **Proposed approach(es)** — one or more options discussed, with trade-offs noted
  - **Constraints & risks** — anything that limits or complicates the solution
  - **Open questions** — unresolved items that PO or Architect will need to decide
  - **Suggested workflow type** — Claude's recommendation (new-feature / bugfix / hotfix / minor-enhancement / upgrade) based on the exploration
- File is written to `.dev-framework/` (not `.dev-framework/artifacts/` — it is pre-workflow)

### FR-4: Handoff prompt to PO
- After writing the file, Claude outputs:
  ```
  ✓ Exploration complete: .dev-framework/explore-$SLUG.md
  
  Suggested next step: start a $workflowType workflow and give this file to PO as context.
    → /dev-framework:new-feature "$idea"   (or bugfix / hotfix / minor-enhancement)
  
  PO tip: share the explore file path so the PO agent reads it before asking requirements questions.
  ```
- Claude does NOT automatically start the workflow — the developer decides when and whether to proceed

### FR-5: Naming
- Slug is derived from the `$ARGUMENTS` string: lowercase, hyphens, no special chars
- Output file: `.dev-framework/explore-$SLUG.md`

---

## Non-Functional Requirements

- The conversation must feel natural — not like filling a form. Claude should respond to what the developer says, not rigidly follow a fixed question list.
- The output markdown must be concise enough to be read by PO in under 2 minutes (target: under 60 lines).
- The skill works with no active workspace — it is truly standalone.
- No git operations — explore is ephemeral until the developer decides to formalise it.

---

## Acceptance Criteria

- [ ] `/dev-framework:explore "vague idea"` starts a conversational session without creating any workspace or branch
- [ ] Claude asks questions in small batches (2–3 at a time), not all at once
- [ ] Conversation ends when developer signals done
- [ ] `.dev-framework/explore-$SLUG.md` is written with all 7 required sections
- [ ] File is under 60 lines
- [ ] Claude recommends a workflow type at the end
- [ ] Explore does not auto-invoke any other skill

---

## Edge Cases

- Developer invokes explore with no arguments → Claude asks "What would you like to explore?"
- Developer ends the conversation very early (1–2 exchanges) → Claude still produces the output file with whatever was gathered, and notes which sections are incomplete
- Developer invokes explore while a workspace is active → allowed; explore is standalone and does not interfere
- Developer says "hand to PO" during exploration → Claude finishes writing the brief and outputs the handoff prompt; still does not auto-invoke PO

---

## Dependencies

- No dependencies on existing skills or framework state
- Output file is an input hint for PO, not a required artifact — PO agent reads it optionally
- Creates: `skills/explore/SKILL.md`
