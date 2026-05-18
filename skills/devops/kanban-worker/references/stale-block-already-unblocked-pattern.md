# `[ALREADY UNBLOCKED]` Stale Block Pattern

A specific stale-block sub-pattern discovered during COO operational review on 2026-05-15.

## How it happens

1. **Engineer** completes a task, blocks with `review-required:` 
2. **Review Router** routes it to Tech Lead (reassign + unblock)
3. **Tech Lead's worker spawns** — but the task was already unblocked in step 2 by the router
4. **Tech Lead** reviews the code, finds 2 should-fix items, creates a fix task
5. **Tech Lead** calls `kanban_block(reason="[ALREADY UNBLOCKED]")` — re-blocking the task it was dispatched to unblock
6. **Board stalls** — the Review Router can't touch it (wrong prefix), Tech Lead won't revisit (done reviewing), and all child tasks stay in `todo`

## Concrete example: T_abc123

```
Engineer: Create ImportPipeline struct (shared logic)
  Blocked on: tech-lead
  Block reason: [ALREADY UNBLOCKED]

Timeline:
  13:29 — Engineer blocks with review-required ✓
  13:31 — Review Router reassigns to tech-lead + unblocks ✓
  13:31 — Tech Lead worker spawns ✓
  13:36 — Tech Lead reviews: "2 should-fix items" ✓
  13:36 — Tech Lead creates fix task T_def456 ✓
  13:36 — Tech Lead calls kanban_block(reason="[ALREADY UNBLOCKED]") ✗ STALE
  13:41 — Review Router: no route action (wrong prefix) ✗
  14:01 — Review Router: same ✗
  ...repeat 4+ more times...
  17:00 — COO identifies: "unblock this, the fix task handles the should-fix items"

Impact: 8 child/grandchild tasks stuck in todo behind this stale block.
  - DataScraper trait, content scraper, legacy scraper, CLI tool,
    ImportPipeline unit tests, integration tests, fix task, re-review
```

## Why the Review Router can't fix it

The Review Router's routing rules explicitly skip:
- Tasks already assigned to tech-lead → SKIP (already at the right person)
- Block reasons that don't start with `review-required:` or `help-needed:` → SKIP

`[ALREADY UNBLOCKED]` fails both checks. The Review Router can only flag it in comments.

## Detection during board health scan

This is a **stale block** — the block reason references the task's own event history (it was already unblocked) rather than an external dependency. The COO/operational review should detect it in Step 6 (todo parent-blocking check):

1. Find `todo` tasks with blocked parents
2. Check the parent's block reason for meta-references (`[ALREADY UNBLOCKED]`, `[ALREADY REVIEWED]`, system-generated reasons)
3. Check if a fix task exists that handles the should-fix items independently
4. If yes → unblock the parent. The fix task handles the remaining work.

## Fix

```bash
hermes kanban unblock T_abc123
```

After unblocking, all 4 child tasks promote from `todo` to `ready` on the next triage cycle (within 60s). The fix task (T_def456 → T_ghi789) runs independently.

## Prevention

Update the Tech Lead's SOUL.md or the "Direct assignment vs. separate review task" section in kanban-worker to add:

- When dispatched directly to a parent task that is already unblocked (status is `todo` or `ready`, not `blocked`), do NOT call `kanban_block()` — you are there to review, not re-block. Complete your review with a comment and call `kanban_complete()` to finalize.
- If you find issues, create a fix task and complete your review. The original task's unblocked status is correct — the fix task will handle the issues.
