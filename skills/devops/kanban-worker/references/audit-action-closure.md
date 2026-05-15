# Audit-Action Closure Pattern

## The Problem

An agent runs an audit, identifies 6 gaps, writes a detailed remediation plan with assignees and due dates — then completes the task. No follow-up tasks are created. The report sits in a docs folder. Nobody picks up the gaps because no kanban tasks exist for them.

This is an **incomplete deliverable**. The audit identified work that needs doing; not spawning that work leaves it invisible to the dispatcher and the rest of the team.

## The Fix

Before calling `kanban_complete` on any analysis, audit, or report task, scan the output for identified gaps that need someone else's action. For each gap:

```python
task = kanban_create(
    title="[Role]: [Action: short, specific]",
    assignee="right-owner",  # e.g. cpo, finance, legal, cto
    body="## Context\n[Reference the audit/report that identified this gap]\n\n## Action Required\n[What needs to be done, in specific terms]\n\n## Source\n[Link or file path to the audit/report]\n",
)
```

Then on your own completion:

```python
kanban_complete(
    summary="Audit complete: found N gaps, created N fix tasks [summary]",
    created_cards=[t1_id, t2_id, ...],  # all the tasks you spawned
)
```

## Real-World Example

A governance audit found 6 missing decisions (72.7% → target >95%). The COO produced a detailed remediation plan but created zero kanban tasks. Result: the founder had to create 6 tasks manually. The COO's instruction was "write 5 deliverables" — it followed that literally and didn't close the loop.

The fix is adding an explicit step to the role's SOUL.md: "When your audit/report identifies gaps needing someone else's action, create kanban tasks as part of your deliverable."

## Anti-Pattern

- Writing "PMO should set up a blocker-watchdog cron" in a report without creating the kanban task for the PMO
- Listing "6 missing decisions with assignees" in a remediation table without creating the tasks
- Recommending "the CTO should fix X" in prose without a kanban card
