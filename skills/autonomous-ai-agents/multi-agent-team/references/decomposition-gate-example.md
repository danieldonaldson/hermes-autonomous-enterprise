# Decomposition Gate — Real-World SOUL.md Changes

This reference documents the concrete SOUL.md changes made in a session where the Engineer was getting stuck on long-running tasks because the Tech Lead/CTO wasn't decomposing tasks granularly enough.

## Root Cause Chain

1. CTO created implementation tasks assigned to Tech Lead (not Engineer)
2. Tech Lead had "no task creation" restriction — couldn't decompose
3. No decomposition mandate existed in any role
4. Engineer had no guard — tried to power through too-large tasks, hit iteration limits

## Changes Applied

### CTO SOUL.md Changes

**Your Role section:**
- Changed from "Delegate implementation to the Tech Lead, who assigns work to the Engineer" to "Decompose implementation into granular, bite-sized tasks (each ≤30 min of focused work) and assign them directly to the Engineer via the kanban board"
- Added: "the Tech Lead reviews the task granularity before any build starts"

**How You Work section:**
- Replaced step 3 ("Create implementation tasks on the kanban board assigned to the Tech Lead") with:
  - Step 3: Decompose each feature into granular, independent build steps (each ≤30 min)
  - Step 4: Get Tech Lead sign-off on the decomposition
  - Step 5: After sign-off, create tasks assigned directly to Engineer
- Added Task Granularity Rule: "A task is small enough when: modifies 1-3 files at most, single testable outcome, Engineer can start writing code in <1 minute"

### Tech Lead SOUL.md Changes

**Added §0 Decomposition Gate (PRIMARY DUTY):**
- Granularity checklist (5 items: ≤3 files, single outcome, start in 1 min, exact paths/commands, ≤30 min)
- Protocol for reviewing CTO's decomposition (block with changes-required if too large)
- Protocol for ad-hoc tasks without pre-decomposition (use kanban_create to break it down)
- Task body template showing a well-decomposed Engineer task

**What You Do NOT Do:**
- Removed "Manage the kanban board (no task creation)" — Tech Lead now has kanban_create for decomposition

**How You Work:**
- Added step 0: "Decomposition first — before the Engineer touches any code, verify or create the task decomposition"
- Added "Engineer Blocked on Too-Large Tasks" response protocol

### Engineer SOUL.md Changes

**How You Work:**
- Added step 2: "Read the task body. If the task is too large or ambiguous, do NOT start work. Block immediately."

**Added "Too-Large Task Guard (HARD RULE)":**
- 5 concrete conditions for "too large" (3+ files without specifics, no verification steps, can't start in 1 min, says "build" without specifics, >30 min)
- Exact code to block: `kanban_block(reason="help-needed: task too large — needs decomposition")`
- "Then stop. The Tech Lead will decompose it into granular sub-tasks."

## Verification

After these changes, the chain became:

```
CPO spec → CTO decomposes → Tech Lead reviews granularity (gate)
  → CTO assigns each granular task directly to Engineer
    → Engineer starts work OR blocks if still too large → Tech Lead decomposes further
      → Engineer completes → blocks review-required → Tech Lead reviews → unblock
```

The key mental model shift: decomposition is not the Engineer's job, and it's not optional for the CTO. The Tech Lead is the gate that prevents poorly-decomposed tasks from reaching the Engineer.
