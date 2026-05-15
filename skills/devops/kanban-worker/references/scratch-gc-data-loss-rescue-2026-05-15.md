# Scratch GC Data Loss — Rescue Incident (2026-05-15)

## What Happened

A routine audit of scratch workspaces found that ~80 documents produced by agents across 15+ roles existed ONLY in scratch workspace directories. The workspaces had not yet been garbage-collected (tasks were marked `done` but not `archived`), so the files were recoverable. Once GC runs, all scratch workspaces are deleted.

## Root Cause

Agents claimed "written to ~/Work/hermes-yethu-overlay/docs/<category>/" in their `kanban_complete` summaries but:
1. Actually wrote the files only to `$HERMES_KANBAN_WORKSPACE` (the scratch temp dir)
2. Never copied them to the persistent overlay filesystem
3. Never verified the files existed at the target path

This is the **hallucinated file write** pitfall — the model believes it wrote the file because it formed the intention, but the tool call writing to the overlay path never executed or succeeded silently.

## Scope of Loss (rescued in time)

| Role | Docs rescued | Notes |
|------|-------------|-------|
| Sales-BD | 5 | Pipeline, templates, CRM, comms plan, partnerships |
| Content Marketing | 9 | Blog drafts, calendar, link building, social posts, referral brief, SEO, traffic report |
| Growth | 6 | Activation baseline, acquisition strategy, drop-off report, conversion funnel, K-factor |
| Community | 5 | Engagement baseline, targets, plan, group research, seeding plan |
| Customer Success | 6 | Churn signals, churn metric, onboarding quickwins, flow map, queue audit, CS plan |
| Design | 5 | Search UX, design system, listing flow, landing page, review |
| Research | 6 | Interview guide (2 versions), session template, synthesis, recruitment pipeline |
| Finance | 2 | Monitoring framework, launch budget |
| COO/Operations | 2 | Ops management framework, launch runbook |
| CPO | 4 | Search spec, infra plan, data plan, quality moderation |
| Legal | 4 | Compliance framework, breach register, risk register, sign-off |
| Strategic | 5 | McKinsey memo, competitive landscape (4 competitors) |

## COO's 5 operational documents (pmp-runbook, data-ops-runbook, governance-audit, protocol-compliance-runbook, coo-weekly-report) were not in any workspace — the agent claimed "written to overlay" but never actually wrote them. These were re-created via a fresh kanban task.

## How to Prevent

1. **Every doc-producing task must end with a verification step:**
   ```bash
   ls -la ~/Work/hermes-yethu-overlay/docs/founder-review/<filename>.md
   ```
   If `ls` returns "No such file or directory", the write failed — retry the copy.

2. **Use the founder-review workflow** — all non-code artifacts go to `docs/founder-review/` first. This is a short, obvious path. If it feels unintuitive, that's a sign to double-check the write.

3. **For monitoring agents scanning the board:** Cross-reference completed tasks against files on disk. A task that claims documents but has no matching files in the overlay should be flagged yellow and re-dispatched.

4. **Do NOT trust "written to..." in a task summary as evidence the file exists.** The COO task t_aa07d0d1 had `summary: "All 5 operational deliverables written to ~/Work/hermes-yethu-overlay/docs/operations/"` but zero files were on disk. Always `ls` to confirm.
