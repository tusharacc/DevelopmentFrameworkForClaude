# Tester Artifact — explore-skill

## Test Plan

Validate five areas: invocation, conversation behaviour, completion detection, output brief, and handoff prompt. All tests are written only — Executor runs them against `skills/explore/SKILL.md`.

---

## Test Cases

### Group A — Invocation

**TC-01: Invoke with topic argument**
- Action: invoke `/dev-framework:explore "add webhook support"`
- Expected: Step 2 runs immediately — session opened with "Let's explore **add webhook support**..." No questions asked yet in the opening message

**TC-02: Invoke with no argument**
- Action: invoke `/dev-framework:explore` (empty arguments)
- Expected: Claude asks "What would you like to explore today?" and waits; does NOT proceed to Step 2 until developer responds

**TC-03: No workspace created on invocation**
- Action: invoke explore with any topic
- Expected: no `.dev-framework/workspaces/` directory created, no state.json, no branch, no git commit

**TC-04: Works while another workspace is active**
- Setup: `.dev-framework/current-workspace` contains an active workspace slug
- Action: invoke explore
- Expected: explore runs normally — does not block or warn about the active workspace

---

### Group B — Conversation Behaviour

**TC-05: Opening message asks no questions**
- Action: invoke explore with a topic
- Expected: Step 2 message acknowledges the topic and mentions "say done or wrap it up" — contains zero question marks in the opening turn

**TC-06: First round asks 2–3 questions maximum**
- Action: after opening, Claude begins first round
- Expected: first response after opening contains 2 or 3 questions — never more than 3

**TC-07: Claude responds to developer's answer before asking new questions**
- Setup: developer gives a substantive answer in first round
- Expected: Claude's next turn starts with a reaction/acknowledgement to what was said, then transitions to new questions — does not ignore the answer

**TC-08: Coverage areas are not shown to developer**
- Action: run a full exploration session
- Expected: the checklist labels (A — Problem & users, B — Existing state, etc.) never appear in any of Claude's messages to the developer

**TC-09: Peer tone — no formal numbering**
- Action: observe Claude's questions across multiple turns
- Expected: questions are in natural conversational prose; NOT formatted as "Question 1:", "Question 2:" or numbered lists

**TC-10: New questions shift to uncovered areas**
- Setup: developer answers questions about problem and users (area A) fully
- Expected: subsequent turns move to areas B–F rather than re-asking about area A

---

### Group C — Completion Detection

**TC-11: "done" triggers write phase**
- Setup: active exploration session
- Action: developer sends "done"
- Expected: Claude responds "Got it — let me write up the brief." and proceeds to write the file; does NOT ask another question

**TC-12: "wrap it up" triggers write phase**
- Same as TC-11 but with "wrap it up"
- Expected: same behaviour

**TC-13: "hand to po" triggers write phase**
- Same as TC-11 but with "hand to po"
- Expected: same behaviour

**TC-14: "let's go" triggers write phase**
- Same as TC-11 but with "let's go"
- Expected: same behaviour

**TC-15: "stop" alone does NOT trigger write phase**
- Setup: developer sends "stop sending notifications when the queue is empty"
- Expected: Claude treats this as a regular answer and continues the conversation — does NOT write the brief

**TC-16: Completion signal detected case-insensitively**
- Action: developer sends "DONE" or "Wrap It Up"
- Expected: triggers write phase regardless of capitalisation

**TC-17: Completion signal mid-sentence is detected**
- Action: developer sends "I think that covers it, looks good"
- Expected: "looks good" detected → write phase triggered

---

### Group D — Output Brief

**TC-18: Brief written to correct path**
- Setup: topic = "add webhook support"
- Expected: file written to `.dev-framework/explore-add-webhook-support.md` (not `artifacts/`, not workspace dir)

**TC-19: Slug derived correctly from topic**
- Input topics and expected slugs:
  - "add webhook support" → `add-webhook-support`
  - "User Auth System!!!" → `user-auth-system`
  - "very long topic name that exceeds forty characters in total" → slug truncated to max 40 chars

**TC-20: Brief contains all 7 required sections**
- Expected headings present: `## Idea`, `## Problem Being Solved`, `## Context`, `## Proposed Approaches`, `## Constraints & Risks`, `## Open Questions`, `## Suggested Workflow Type`

**TC-21: Brief is under 60 lines**
- Action: run a full session and signal done
- Expected: `wc -l .dev-framework/explore-*.md` returns ≤ 60

**TC-22: Uncovered sections use sentinel not blank**
- Setup: developer only discusses problem and approach — skips constraints and edge cases
- Expected: `## Constraints & Risks` section contains `*(not explored)*` rather than being empty or omitted

**TC-23: Second approach line omitted when only one approach discussed**
- Setup: exploration only surfaces one approach
- Expected: `## Proposed Approaches` contains exactly one bullet; no second bullet with placeholder text

**TC-24: Second approach included when two approaches discussed**
- Setup: developer explicitly discusses two different approaches
- Expected: `## Proposed Approaches` contains two bullets, each with description and trade-offs

**TC-25: Suggested workflow type is one of the five valid values**
- Expected: `## Suggested Workflow Type` contains exactly one of: `new-feature`, `bugfix`, `hotfix`, `minor-enhancement`, `upgrade`

**TC-26: Brief content is synthesised, not transcribed**
- Setup: developer gives verbose multi-paragraph answers
- Expected: brief sections are concise summaries, not copy-paste of developer messages

**TC-27: No annotation text leaks into output**
- Expected: output file contains no occurrences of `← only if discussed`, `$approach_1`, `$tradeoffs` or other template placeholders

---

### Group E — Handoff Prompt

**TC-28: Handoff prompt printed after brief is written**
- Expected: after file write, Claude outputs the block starting with `✓ Exploration complete: .dev-framework/explore-$SLUG.md`

**TC-29: Handoff prompt contains correct file path**
- Expected: path in prompt matches the actual file written

**TC-30: Handoff prompt contains suggested next command**
- Expected: prompt includes `/dev-framework:$workflowType "$TOPIC"` with the correct workflow type matching the brief

**TC-31: No skill auto-invoked after handoff prompt**
- Expected: skill stops after outputting the prompt — no new-feature, bugfix, or any other skill is invoked automatically
