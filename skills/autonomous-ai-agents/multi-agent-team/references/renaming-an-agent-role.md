# Renaming an Agent Role

Renaming a role is a multi-location surgery. The role's title appears in SOUL.md files, context files, cron jobs, skills, memory, KPI docs, kanban data, and directory names with symlinks. Missing any one location leaves a stale reference that either breaks a symlink, confuses an agent, or displays the old name in a report.

This checklist covers the full sweep. Do them in the order listed — source directories before symlinks, directories before in-file references.

## Checklist

### 1. Role definition files (SOUL.md + context.md)

For each role definition location:

- **Framework SOUL.md** — update `# <old> & <old2>` title and the intro line `You are the founder's **<old>**`
- **Framework config.yaml** — usually no change (internal identifier), but check if it has a display name
- **Overlay context.md** — update `# <old> — Role-Specific Context` title and `You are the <old> to the founder` intro
- **All SOUL.md cross-references** — any other role's SOUL.md that lists this role by name (e.g. McKinsey Consultant's "Who is reviewed" section that lists all roles by name). Search for `<old>` and `<old2>` globally in the framework and overlay.
- **Framework README.md** — team structure table
- **KPI framework doc** — any KPI owners assigned to the old name

### 2. Operational config

- **Cron job** — job name and prompt text. Use `hermes cron edit <id>` or edit `~/.hermes/cron/jobs.json` directly.
- **Cron job in other roles' prompts** — e.g. McKinsey Up-or-Out review prompt that lists all roles by name.

### 3. Skills & references

Search `~/.hermes/skills/` for the old role name. Update anywhere it's used as a **role reference** (not a generic pattern name, though those should be evaluated too). Key skills to check:

- `up-or-out-performance-reviews` — architecture diagram, role list, step headings, pitfalls
- `multi-agent-team` — archetype table, reporting variant examples, sentry pattern descriptions, cron examples, pitfalls
- `hermes-config-as-code` — profile context listing, real-world example directory trees
- Any other skill that references the role by name

### 4. Memory

- **Agent memory** (`memory target=memory`) — find and replace old role name references
- **User profile** (`memory target=user`) — e.g. cron schedule preference "Business Coach at :29 past"

### 5. Profile memories & skill copies

Each profile in `~/.hermes/profiles/<name>/` may have its own:
- `memories/MEMORY.md` — references to the old role name
- `skills/` — copies of skills with old references

Check and update these so dispatched workers load fresh state.

### 6. Directory renames

Only after all symlinks point to the old paths (they still resolve at this point):

```bash
mv framework/roles/<old-name> framework/roles/<new-name>
mv overlay/roles/<old-name> overlay/roles/<new-name>
mv ~/.hermes/profiles/<old-name> ~/.hermes/profiles/<new-name>
```

### 7. Fix broken symlinks

After directory renames, the profile's symlinks point to non-existent paths. Recreate them:

```bash
cd ~/.hermes/profiles/<new-name>
rm SOUL.md config.yaml context.md
ln -s /path/to/framework/roles/<new-name>/SOUL.md SOUL.md
ln -s /path/to/framework/roles/<new-name>/config.yaml config.yaml
ln -s /path/to/overlay/roles/<new-name>/context.md context.md
```

Note: `product-context.yaml` usually points to the overlay root, not a role dir, so it stays intact.

### 8. Kanban & ops data

- **`board_health.json`** — search for `"assignee": "<old-name>"` and `"<old-name>":`
- **`weekly_ops_report.md`** — profile stats table with `| <old-name> |`
- **Kanban task logs** (`~/.hermes/kanban/logs/`) — role name and profile path references
- **Checkpoint files** (`~/.hermes/checkpoints/store/projects/`) — stale `workdir` paths

### 9. Verify

```bash
ls -d /path/to/framework/roles/<new-name>
ls -d /path/to/overlay/roles/<new-name>
ls -d ~/.hermes/profiles/<new-name>
grep -rl "<old-name>" ~/.hermes/ 2>/dev/null | grep -v sessions/ | grep -v "\.db" | grep -v "\.db-" | grep -v "\.db-wal" | grep -v "\.db-shm" | grep -v "cron/output/" | grep -v "logs/"
```

The final grep should return only:
- Intentional historical notes in memory (e.g. "renamed from Business Coach")
- Nothing that would be loaded at runtime

## What NOT to update

- **Historical session files** — past conversations keep the old name, which is fine
- **Historical cron output** — past run records in `cron/output/` are read-only archives
- **Backup directories** — old snapshots
- **Log files** — `agent.log` and `errors.log` are append-only
- **Profile state databases** (`state.db`, `.db-wal`) — these contain internal IDs, not display names

## Symlink model

The standard multi-agent-company pattern uses symlinks to keep one copy of truth:

```
~/.hermes/profiles/<role>/
├── SOUL.md → framework/roles/<role>/SOUL.md    # shared definition
├── config.yaml → framework/roles/<role>/config.yaml  # shared config
├── context.md → overlay/roles/<role>/context.md  # product-specific context
└── product-context.yaml → overlay/product-context.yaml  # company-wide context
```

This means renaming the source directories breaks the symlinks. Always rename source dirs first, then recreate symlinks, then rename the profile dir.
