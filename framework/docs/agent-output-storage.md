# Agent Output Storage Convention

Every kanban worker that produces a **durable output** (document, report, design artifact, research finding, content draft, etc.) must store it in the product overlay's `docs/` tree — **not** in the ephemeral scratch workspace.

Scratch workspaces (`$HERMES_KANBAN_WORKSPACE`) are garbage-collected when the task is archived. Any output left there is lost. The overlay repo is git-tracked, discoverable, and survives task archival.

## How it works

### 1. Task bodies must specify `output_path`

Every kanban task that produces a document/artifact should include an `output_path` field in its body. Example:

```
## Task: Draft community seed messages
Owner: Community Manager | KPI: G8
output_path: docs/operations/seed-messages.md

Draft 5 sample seed messages for user outreach: value prop, launch hook, CTA.
CMO reviews before sending.
```

The orchestrator (CMO, CPO, Tech Lead, etc.) is responsible for including `output_path` when creating document-producing tasks.

### 2. Workers write output to the overlay's docs/ tree

When a worker sees `output_path` in the task body, they must:

1. Write the final output file to the path, resolved relative to the overlay root (declared in `product-context.yaml` under `codebase_paths.overlay_root`)
2. If the path is absolute (like `$OVERLAY_ROOT/docs/...`), use it directly
3. If relative (like `docs/product/launch-blog-post.md`), resolve against the overlay root

### 3. Workers commit the output

After writing the file, the worker must commit it to the overlay repo:

```bash
cd $OVERLAY_ROOT
git add -A
git commit -m "docs: add <task-title>
Produced by <role> — <short summary>"
```

Do NOT push automatically — the founder may want to review/amend before pushing. The commit message should be descriptive enough for the founder to understand what was produced without opening the file.

### 4. Summaries reference the output path

Include the output path in your `kanban_complete` summary so it's discoverable from the board:

```python
kanban_complete(
    summary="Drafted 5 seed messages for user outreach — committed to overlay",
    metadata={
        "output_path": "docs/operations/seed-messages.md",
        "word_count": 450,
        "status": "pending_review",
    },
)
```

### 5. Review-required handoffs reference output paths too

When blocking with `review-required:`, include the output path in the comment:

```python
kanban_comment(
    body="review-required handoff:\n"
         "Artifact: docs/operations/seed-messages.md\n"
         "See comment for review notes.",
)

kanban_block(reason="review-required: seed messages drafted — needs CMO review")
```

## Expected directory structure within docs/

```
docs/
├── product/          # Product specs, user stories, feature docs
├── design/           # UX mockups, design decisions, user flows
├── engineering/      # Technical docs, ADRs, architecture notes
├── operations/       # Process docs, SOPs, metrics, dashboards
├── research/         # User interviews, market research, personas
├── finance/          # Pricing models, unit economics, projections
├── legal/            # Compliance docs, policies
├── marketing/        # SEO strategy, content calendars, blog drafts
└── sales/            # Outreach templates, account research
```

The orchestrator creating the task should choose the right subdirectory. When in doubt, use `docs/product/`.

## Exceptions

- **Code changes** (Rust source, SQL migrations, frontend code) go to the codebase (`codebase_paths.project_root` in `product-context.yaml`), not to the overlay docs/
- **Scratch-only work** (one-off calculations, temporary experiments) can stay in the scratch workspace — just don't block or complete without noting it
- **Existing docs** in the product repo (`~/Work/<your-product>/docs/`) stay where they are — this convention applies to new outputs going forward
