# Phase Transitions: When KPI Execution Completes

## The Pattern

When ALL KPI decomposition tasks across all non-engineering functions are done and engineering is still running, the company enters a **"functional inbox empty"** state. Non-engineering teams sit idle while engineering finishes its current wave. Without proactive detection, this idle time compounds.

This is distinct from a **phase gate** (which needs founder approval before proceeding). It's a **phase transition** — teams are idle, give them productive next-wave work autonomously.

## Signal: "Functional Inbox Empty"

Detect: a function (or group of functions) has **zero** `ready` or `running` tasks, while at least one other function is still active. The signal is strongest when 3+ functions are idle simultaneously.

**Example from practice:** In a real session, seven non-engineering functions (CMO team with 6 reports, CPO, Finance, Legal, COO team, Designer) all had zero pending tasks. Engineering was running 4 test-writing tasks. The CEO detected this and created 9 next-phase tasks in a single batch.

## Procedure

1. **Determine the next natural phase.** What comes after the current work wave? Build → launch prep. Discovery → spec writing. Research → synthesis.

2. **Create one task per function.** Each task must:
   - Reference prior completed work by task ID
   - Include prior deliverables paths
   - Specify a concrete deliverable path for the new output
   - Be granular enough to execute in one session

3. **Batch-create independent tasks.** Functions are independent at this stage — create all tasks in parallel (they don't block on each other).

4. **Set one task as implicit gate.** The CPO's launch acceptance criteria or COO's launch runbook defines "done" for this phase. Make it priority 1.

5. **Do not escalate** unless the next phase is genuinely unknown at the strategic level. The KPI framework usually suggests the next milestone.

## Who Owns This

The **CEO daily cron job** or **COO hourly scan** owns the "functional inbox empty" detection. Do NOT put it in individual profile SOUL.md files — an individual agent should not be scanning the board to find itself work.

For teams of 15+ profiles, the CEO should create top-level C-level tasks, and let each C-level decompose into granular tasks for their direct reports. Only create tasks directly for specialist profiles (Legal, Finance, Designer) if their C-level doesn't exist.

## What NOT to Do

- **Do not create monolithic tasks.** "Prepare for launch" is too large. "Write launch FAQ" is correct. If you can't decompose further, create a decomposition task for the C-level first.
- **Do not create tasks requiring strategic decisions.** If the next phase needs pricing sign-off, distribution channel choice, or funding approval, escalate that decision. Create tasks for work that CAN proceed in parallel without the decision.
- **Do not escalate obvious transitions.** Build → launch prep does not need founder approval. The founder's attention is for exceptions.
