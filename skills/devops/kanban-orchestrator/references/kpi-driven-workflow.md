# KPI-Driven Workflow: Executive → Team Decomposition

## When to use this pattern

The board is idle. C-level roles (CEO, CTO, CMO, CPO, COO, CFO) have no active tasks. The build phase is done or paused. The org needs work that flows from KPIs, not from features.

## Trigger

Either:
- CEO detects board has been idle (no running tasks) >2 hours and fans out KPI decomposition tasks
- A human directly creates decomposition tasks for each C-level

## Flow

```
CEO → creates 1 task per C-level: "Decompose <bucket> KPIs into work"
  │
  ├─ CTO → reads KPI framework → creates tasks for Tech Lead, Engineer, Head of Data, Head of Quality, Security Reviewer
  ├─ CMO → reads KPI framework → creates tasks for Community Manager, Content Marketing, Growth Lead, Sales-BD, User Research, Customer Success
  ├─ CPO → reads KPI framework → creates tasks for Designer
  ├─ COO → reads KPI framework → creates tasks for PMO, RMO, Operations Analyst, Audit-Governance
  ├─ Finance → reads KPI framework → creates tasks for self (no direct reports)
  └─ Legal → reads KPI framework → creates tasks for self (no direct reports)
```

## Executive task body template

```
## Instructions
1. Read the KPI framework at <path-to-framework>
2. Identify your KPIs and each team member's KPIs
3. Create concrete kanban tasks for each team member.
   Each task must be granular (≤30 min, single outcome):
   - <team-member>: <specific, actionable task aligned to their KPIs>
4. Report what you created, including the task IDs
```

## Granularity rules (same as implementation tasks)

- Each task modifies ≤3 files (or produces ≤3 artifacts)
- Single, testable outcome
- ≤30 min of focused work
- An engineer/team member can start in <1 min without asking questions

## Pitfalls

- **Over-abstraction:** "Improve growth" is not a task. "Growth Lead: Run A/B test on CTA button copy — 2 variants, 48h" is a task.
- **Skipping the KPI framework read:** Don't decompose based on memory — the framework may have been updated. Always read the source of truth.
- **One task per KPI is too coarse.** A single KPI (e.g. DAU/MAU >20%) may need 3-5 tasks across different team members (Growth runs experiments, Community runs campaigns, Content publishes SEO articles).
- **Creating tasks for roles that don't exist.** Always assign to real profile names. `kanban_list(assignee="<name>")` can verify.
- **No created_cards list on completion.** The executive must pass `created_cards=[...]` on `kanban_complete` so the audit trail links the decomposition to the spawned tasks.
