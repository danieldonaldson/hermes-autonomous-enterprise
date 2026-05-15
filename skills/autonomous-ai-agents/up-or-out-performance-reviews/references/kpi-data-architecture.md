# KPI Data Architecture — Yethu Implementation

This reference documents the concrete KPI data storage architecture deployed for the Yethu autonomous enterprise. It is an implementation of the generic pattern described in Step 9 of `SKILL.md`.

## Where KPIs Live

All KPI data lives in the **private overlay repo** alongside product config — NOT in the framework repo (which is open source) and NOT in the product code repo.

```
~/Work/hermes-yethu-overlay/
├── operations/
│   ├── kpi/
│   │   ├── framework.yaml           # master KPI definitions (the source of truth)
│   │   ├── actuals/
│   │   │   ├── README.md            # workflow documentation
│   │   │   ├── 2026-06.yaml         # monthly actuals snapshot
│   │   │   └── ...
│   └── dashboards/
│       ├── README.md                # directory structure docs
│       ├── weekly/
│       │   ├── 2026-W25.md          # RMO's Results Dashboard for COO
│       │   └── ...
│       └── monthly/
│           ├── 2026-06-up-or-out.md # McKinsey Up-or-Out review memo
│           └── ...
```

**Rationale:** The overlay is private (no data leaks), git-tracked (full history), and already shared between agents (all role profiles symlink to it via their workspace paths). No separate repo, no additional credential surface.

## File Format: framework.yaml

Structured YAML with one key per bucket. Each KPI record has:

```yaml
buckets:
  EFFICIENCY:
    name: Efficiency
    kpis:
      - id: E1
        metric: "Cycle Time (avg days per task, end-to-end)"
        owner: PMO
        cadence: weekly
        baseline: null            # TBD until Ops Analyst provides it
        target: "<3 days"
        source: "kanban cycle_time metric"
        direction: lower_is_better
        notes: "Policy standard — set 2026-05-13"
```

**Required fields per KPI:** `id`, `metric`, `owner`, `cadence`, `baseline`, `target`, `source`, `direction`.

## File Format: actuals/YYYY-MM.yaml

Separate snapshot file per month. This keeps history clean — no in-file merge conflicts, clear git blame per period.

```yaml
period: 2026-05
generated_by: RMO
generated_at: 2026-06-01
generated_from:
  - "Operations Analyst dashboard data"
  - "Agent self-reports (kanban gateways)"
actuals:
  E1:
    value: 3.8
    unit: days
    source: "Operations Analyst weekly report"
    note: "Within target (<3 days). Trend: improving from 4.2."
  G3:
    value: null
    unit: "%"
    source: null
    note: "Pre-launch — no user data yet"
```

## Workflow

### Weekly (RMO)
1. Pull current data from Operations Analyst and agent self-reports
2. Produce the Results Dashboard to `operations/dashboards/weekly/YYYY-Www.md`
3. Submit to COO

### Monthly (RMO)
1. At month end, collect actuals for every KPI that had data
2. Write `operations/kpi/actuals/YYYY-MM.yaml`
3. Commit + push to the overlay repo

### Monthly (McKinsey Consultant)
1. Before the Up-or-Out review, read the latest actuals snapshot
2. Cross-reference KPI definitions from `framework.yaml`
3. Use the actuals history to derive trend arrows (↑ / → / ↓)
4. The history also enables: "X periods below target" detection

### Monthly (Chief of Staff — mid-cycle)
1. Read the last 2-3 actuals snapshots
2. Detect roles that have been below target for 2 consecutive periods
3. Flag 🟡 escalation before the formal McKinsey review

## Role SOUL.md Updates

The following changes were made to wire the RMO and Operations Analyst into this architecture:

### RMO SOUL.md (framework/roles/rmo/SOUL.md)
- "Maintain the KPI repository" was expanded to:
  - `~/Work/hermes-yethu-overlay/operations/kpi/framework.yaml` — master definitions
  - `~/Work/hermes-yethu-overlay/operations/kpi/actuals/YYYY-MM.yaml` — monthly snapshots
  - `~/Work/hermes-yethu-overlay/operations/dashboards/weekly/` — dashboard output
  - "Commit and push actuals snapshots to the overlay repo each month"

### Operations Analyst SOUL.md (framework/roles/operations-analyst/SOUL.md)
- "Provide data to RMO for KPI baselines and actuals" was expanded to reference:
  - `~/Work/hermes-yethu-overlay/operations/kpi/framework.yaml` — the framework location
  - Feed weekly data into `operations/kpi/actuals/` at month-end

## Deprecated Files (Deleted)

The original KPI framework was drafted as a standalone markdown doc at `~/Work/yethu/docs/kpi-framework-v1.md`. That file and its corresponding CEO approval memo have been **deleted** — the YAML in the overlay is the exclusive source of truth. No duplicate files anywhere.

## Path Conventions

All paths in SOUL.md (in the framework repo) should reference **"the product overlay's `operations/kpi/`"** — never hardcode the repo name like `hermes-<product>-overlay`. The framework repo is public/open-source.

When referencing paths in reference files (like this one) or in agent-generated reports, use absolute paths (`~/Work/hermes-yethu-overlay/...`). Agents resolve `~` at runtime. The overlay repo path is consistent across machines since it's set up during onboarding.
