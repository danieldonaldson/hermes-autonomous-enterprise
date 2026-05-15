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

## Subsequent Pitfall — Tech Lead Still Wrote Code (May 2026)

Even after the decomposition gate was added, a new failure mode appeared: the **CTO's SOUL.md said "create implementation tasks assigned to Tech Lead"** — so the CTO created code tasks (path traversal fix, free listing guardrail) and assigned them directly to Tech Lead. Tech Lead then **implemented the code themselves** instead of decomposing and assigning to Engineer.

### Root Cause

- CTO SOUL.md used the phrase "implementation tasks" for Tech Lead — ambiguous wording that implied Tech Lead should execute
- Tech Lead SOUL.md had "no task creation" blanket ban — contradicted the re-review cycle that requires Tech Lead to create fix tasks
- No role explicitly stated "Tech Lead does NOT write code" — the original code-writing prohibition was too vague

### Fix Applied

**CTO SOUL.md (How You Work):**
```
✓ BEFORE: "Create implementation tasks on the kanban board assigned to the Tech Lead"
✓ AFTER:  "Create spec/architecture tasks on the kanban board assigned to the Tech Lead for decomposition"
          + "⚠️ CRITICAL: Do NOT assign code implementation tasks directly to Tech Lead"
```

**Tech Lead SOUL.md (What You Do NOT Do):**
```
✓ BEFORE: "Write production code"
✓ AFTER:  "Write production code — your job is decomposing, gating, and reviewing, not implementing"
          (replaced "no task creation" with explicit "What You DO Create on the Board" list)
```

### The Fix Chain (Final)

```
CPO spec
  → CTO creates spec/architecture task (NOT implementation) → Tech Lead
    → Tech Lead decomposes into granular (≤30min, ≤3 files) tasks → Engineer
      → Engineer implements → blocks review-required → Tech Lead reviews → unblock
```

### Key Rules Enforced

1. **CTO** creates spec/architecture tasks for Tech Lead, never implementation tasks
2. **Tech Lead** decomposes spec tasks into Engineer tasks, reviews code — does NOT write code
3. **Engineer** implements code, never receives un-decomposed tasks
4. **Tech Lead's task creation** is limited to: fix tasks (when review finds issues), re-review tasks, and decomposed sub-tasks. No standalone new work items.

### Checklist for New Team Setups

When setting up a CTO + Tech Lead + Engineer hierarchy, verify these SOUL.md rules:

- [ ] CTO SOUL.md says "spec/architecture tasks" not "implementation tasks" for Tech Lead
- [ ] CTO SOUL.md explicitly warns against creating code tasks for Tech Lead
- [ ] Tech Lead SOUL.md has explicit "does not write code" in bold language
- [ ] Tech Lead SOUL.md allows fix/re-review/decomposed task creation
- [ ] Engineer SOUL.md has too-large-task guard
- [ ] The task chain (spec → decompose → implement → review) is documented in at least one role's SOUL.md
