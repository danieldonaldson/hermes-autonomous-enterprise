# Board-Empty Detection & Same-Bottleneck Clustering

Real-world examples from an enterprise sync session.

## Board-Empty After Pipeline Completion

**Situation:** On 2026-05-16, the content seeding pipeline (12 tasks across Engineer + Tech Lead) completed between 09:32-10:29. All fix/re-review cycles cleared. The board went from 1 running + ~230 done to 0 running + 0 ready + 0 todo.

**Good sync format:**
```
🔥 **Major progress since last sync: Content seeding pipeline fully completed** (09:32-10:29).
All 12 tasks in the pipeline — from DataScraper trait through content scraper, legacy papers
scraper, integration tests, and fix/re-review cycles — are done. The board is now empty of
ready/todo tasks for the first time.
```

Then in each department section, explicitly call out the idle state:
```
## CTO / Tech Team
**❌ Blocked:** None.
**📋 Queued:** Nothing. All tech tasks done. Board has zero ready/todo tech tasks — the CTO needs to spec the next work phase.
```

And in "Needs Your Review":
```
### Board is empty — next work phase needs spec'ing
All tech tasks are done. The CTO needs direction on the next work phase.
```

## Same-Bottleneck Clustering

**Situation:** On 2026-05-16, three blocked tasks all shared the same root cause: "need human to forward WhatsApp recruitment message to 2 teachers."

**Bad** (separate items — looks like 3 distinct problems):
```
❌ Blocked:
1. T_abc123 — CM needs human to forward WhatsApp message
2. T_def456 — UR needs human to forward same WhatsApp message
3. T_ghi789 — CM needs human Facebook access (different bottleneck)
```

**Good** (clustered — shows the real picture):
```
❌ Blocked (3 tasks, 2 distinct bottlenecks):
1. T_abc123 + T_def456 — Same bottleneck: forward WhatsApp recruitment message
   to 2 teachers (~2 min). Unblocking this one action frees both tasks.
2. T_ghi789 — Separate bottleneck: Facebook group verification (~45 min,
   or use WhatsApp group link shortcut from known teachers).
```

**Clustering rules:**
- Tasks with identical block reasons → merge into one item with count
- Tasks with related but different blockers → merge into one item with sub-bullets
- Tasks with completely independent blockers → keep separate
- Always include the combined effort estimate (e.g. "one ~2 min action unblocks 2 tasks")
