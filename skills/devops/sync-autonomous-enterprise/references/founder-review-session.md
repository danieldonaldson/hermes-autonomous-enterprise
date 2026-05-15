# Live Founder Review Session — Worked Example

This reference documents a real live founder review session conducted on
2026-05-15. Use it as a template when the founder proactively asks to review
completed work.

## Session Flow

### 1. Surface the Board

Start by scanning the kanban board and classifying every relevant task:

- **Recently completed** (last 24-48h) — group by owner/role
- **Blocked** — identify what's needed and whether it's founder-actionable
- **In progress / ready** — flag what will dispatch next

### 2. Present in Three Tiers

```
## Team Status — 15 May 2026

### 🔴 Needs Your Action
| Item | Task | What's Needed | Est. |
|------|------|---------------|------|
| User Research blocked on teacher contacts | t_66497738 | WhatsApp-forward recruitment msg to 2 teachers | 2 min |
| FB group verification blocked | t_9b7208bc | Verify 7 SA teacher groups manually | 45 min |

### 🟡 Worth Reviewing
CTO launch acceptance criteria sign-off — Sections 5.1 and 7 have decisions
that may need founder override.
→ Document at docs/product/launch-acceptance-criteria.md
→ Key finding: Ada recommended G10 (free:paid guardrail) as no-waiver hard gate

PostgreSQL backup (D4) implemented — backup-db.sh + systemd timer + 376-line
restore procedure at docs/ops/backup-restore.md

Finance: unit economics show R4 <5% CPT unachievable until ~1,200 txns/month
due to Paystack's R2.50 fixed fee. Break-even by M12 narrowly hit.

### ✅ Awareness (No Action Needed)
CTO/Tech Lead completed 7 engineering tasks (path traversal fix, guardrail,
search index, backup, re-reviews)
CMO KPI execution plans (6 files to docs/marketing/)
COO operational framework (5 deliverables to docs/operations/)
Legal compliance audit (87% coverage, conditional sign-off)
Customer Support launch materials (FAQ, response templates, welcome sequences)
Finance budget — actual build costs are R0 (all services on free tiers)
```

### 3. Let the Founder Drive

When the founder asks about a specific item (e.g. "open it", "what about X",
"tell me more about Y"), respond directly:

> **Founder:** "g10 is fine — we want to let the market decide"
> → **Action:** Open the launch criteria doc, update G10 from "no waiver" to
>   "founder overrides — no guardrail at all". Update all 3 references (Tier 1
>   summary table, Section 7 gating record, CTO conditions list).
> → **Save to memory** so future sessions know this decision.

> **Founder:** "no — for G10 we want no blocker on how much free content"
> → **Action:** Correct the previous update — remove even the 60% warn monitor.
>   Update all 3 spots again. The first interpretation was wrong; record the
>   corrected version immediately.

> **Founder:** "cool, what about the rest of the team's work"
> → **Action:** Expand beyond engineering to show CMO, COO, Legal, Finance,
>   Design, CPO. Use the same 🔴/🟡/✅ framework across all roles.

> **Founder:** "lets review 3."
> → **Action:** Open the specific deliverable (Customer Success support
>   materials). Display the files inline (FAQ, templates, welcome sequences).
>   Let the founder read the actual output.

### 4. Record Everything Immediately

Every decision the founder makes during the session must be:

1. **Written into the relevant document** (not a mental note, not a todo list)
2. **Saved to persistent memory** if it's a durable policy decision
3. **Committed to the overlay repo** at the end of the session

### 5. Commit and Close

After the session, commit any document changes:

```bash
cd ~/Work/hermes-yethu-overlay
git add -A
git commit -m "docs: founder review decisions — G10 overridden, N3 approved"
git push
```

Also commit any framework changes (SOUL.md fixes, skill updates):

```bash
cd ~/Work/hermes-autonomous-enterprise
git add -A
git commit -m "fix: enforce Tech Lead code-writing boundary in CTO/TL SOUL.md"
git push
```

## What Makes a Live Review Different from the CoS Sync

| Aspect | CoS Async Sync | Live Founder Review |
|--------|----------------|---------------------|
| Trigger | Cron (every 4h at :29) | Founder asks "let's review" |
| Format | Written presentation | Interactive Q&A |
| Pace | Founder reads, responds later | Founder drives, real-time |
| Depth | All departments, fixed structure | Founder chooses what to dig into |
| Decision recording | Agent processes async reply | Recorded on the spot |
| Founder effort | Read + type 3 words | Can ask follow-ups freely |

## Categorization Rules

**🔴 Needs Your Action** — Only items that:
- Are blocked and ONLY the founder can unblock (no agent workaround)
- Need a strategic decision the founder must make (pricing, legal, scope)
- Are estimated at actionable chunks (2 min is good; 45 min is a red flag
  — note it but don't expect immediate action)

**🟡 Worth Reviewing** — Items where:
- The founder should confirm a decision (CTO sign-off, legal verdict)
- A trade-off was made that could go either way (waive vs enforce)
- A financial model or output document needs a human scan

**✅ Awareness** — Everything else:
- Routine completed work with no open questions
- Green-status items from cron monitors
- Work the founder delegated and the agent handled autonomously
