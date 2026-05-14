# Enterprise Sync — Example Output

A real-world sync presentation produced by the Chief of Staff. Shows the expected
format, review items, and founder interaction pattern.

```text
╔══════════════════════════════════════════════╗
║  ENTERPRISE SYNC — 12:29                    ║
╚══════════════════════════════════════════════╝

## CTO / Tech Team

✅ Completed since last sync:
  - verify_signature unit tests — all 5 cases pass. Tech Lead approved.
  - convert_to_intent unit tests — 7/7 cases pass

🔄 In progress:
  - handler endpoint tests — 60%, verify_webhook done

❌ Blocked:
  - statemachine mock repos — gave_up 2x (timeout 900s).
    Tech Lead flagged for decomposition.

📋 Queued:
  - statemachine idle/welcome routing tests
  - statemachine browse flow tests

→ Review needed:
  1. verify_signature tests — approved by Tech Lead, needs founder sign-off
  2. statemachine mock repo timeout — needs scoping decision

## CMO / Marketing Team

✅ Completed:
  - KPI decomposition — created 6 granular sub-tasks

🔄 In progress:
  - Community outreach plan (40%)
  - SEO keyword research (25%)

❌ Blocked: none

→ Review needed: none

─── NEEDS YOUR REVIEW ───

1. verify_signature unit tests — all 5 passing, Tech Lead approved
   → What founder does: "Approve" or "Return for rework: need X" or "Question: Y?"

2. statemachine mock repos — gave up 2x on 900s timeout
   → "Return for rework: split into 2 tasks" or "Approve bump to 1800s"

─── ESCALATIONS ───
None since last sync.

─── KPI PULSE ───
Pre-launch. All teams in KPI decomposition phase. On track.
```

## Founder Interaction

Founder responds:

> "Approve verify_signature. Return statemachine mock for rework — split into 2
> tasks. On pricing, flag for next sync."

Processing:
1. **Approve** → `kanban_complete(task, summary="Approved by founder")`
2. **Return for rework** → `kanban_block(task, reason="decomposition-pending")`,
   add comment with founder's instruction, reassign to Tech Lead
3. **Question noted** → surfaces in next sync's "Needs Your Review"

Next sync at 16:29 shows results.
