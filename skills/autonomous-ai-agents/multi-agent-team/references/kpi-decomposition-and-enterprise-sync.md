# KPI Decomposition Chain & Enterprise Sync

These patterns extend the multi-agent-team skill's autonomous operation sections.

## KPI Decomposition Chain

C-level executives read the KPI framework and decompose goals into concrete
kanban tasks for their direct reports. Without this, only the founder creates
tasks and teams idle between assignments.

### The Chain

```
CEO reads KPI framework
  ├── Creates tasks for CPO (product KPIs → specs, design tasks)
  ├── Creates tasks for CTO (tech KPIs → architecture, team tasks)
  ├── Creates tasks for CMO (marketing KPIs → content, growth, sales)
  ├── Creates tasks for COO (ops KPIs → monitoring, board health)
  ├── Creates tasks for Legal (compliance KPIs)
  └── Creates tasks for Finance (financial KPIs → unit economics)
```

Each C-level then decomposes their KPIs into granular tasks for their reports.
Tech Lead gates granularity before work starts.

### The Decomposition Task Body

```
## Instructions
1. Read the KPI framework at <path to framework.yaml>
2. Identify your KPIs and your team's KPIs
3. Create concrete kanban tasks for each team member:
   - Each task must be granular (≤30 min, single outcome)
   - Include exact deliverables and references
4. Report what you created
```

### Pitfalls

- **Never create Engineer tasks directly.** Route through CTO (for
  decomposition) or Tech Lead (for ad-hoc). Direct creation bypasses
  scoping and causes too-large tasks.
- **C-levels can decompose in parallel** — same KPI framework, different
  domains. No strict ordering needed.
- **Re-decompose after completion** — when teams finish, C-level must
  create the next batch or teams idle.

## Enterprise Sync Presentation

The Chief of Staff produces a department-by-department sync presentation
every 4 hours. This replaces a synchronous standup.

### Founder Interaction (Approve / Rework / Question)

| Response | Agent action |
|----------|--------------|
| `Approve [task]` | `kanban_complete` with approval summary, or `kanban_unblock` if blocked |
| `Return [task] for rework: [reason]` | Add comment with rework instructions, block/reassign |
| `Question about [task]: [question]` | Add question as comment, flag assignee |

Full prompt templates are in the `sync-autonomous-enterprise` skill under
`templates/prompts/`.
