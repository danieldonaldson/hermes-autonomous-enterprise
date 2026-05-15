---
name: kanban-worker
description: Pitfalls, examples, and edge cases for Hermes Kanban workers. The lifecycle itself is auto-injected into every worker's system prompt as KANBAN_GUIDANCE (from agent/prompt_builder.py); this skill is what you load when you want deeper detail on specific scenarios.
version: 2.4.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kanban, multi-agent, collaboration, workflow, pitfalls]
    related_skills: [kanban-orchestrator]
---

# Kanban Worker — Pitfalls and Examples

> You're seeing this skill because the Hermes Kanban dispatcher spawned you as a worker with `--skills kanban-worker` — it's loaded automatically for every dispatched worker. The **lifecycle** (6 steps: orient → work → heartbeat → block/complete) also lives in the `KANBAN_GUIDANCE` block that's auto-injected into your system prompt. This skill is the deeper detail: good handoff shapes, retry diagnostics, edge cases.

## Workspace handling

Your workspace kind determines how you should behave inside `$HERMES_KANBAN_WORKSPACE`:

| Kind | What it is | How to work |
|---|---|---|
| `scratch` | Fresh tmp dir, yours alone | Read/write freely; it gets GC'd when the task is archived. |
| `dir:<path>` | Shared persistent directory | Other runs will read what you write. Treat it like long-lived state. Path is guaranteed absolute (the kernel rejects relative paths). |
| `worktree` | Git worktree at the resolved path | If `.git` doesn't exist, run `git worktree add <path> <branch>` from the main repo first, then cd and work normally. Commit work here. |

### Persistent document storage

When your task produces **durable artifacts** — docs, reports, designs, configuration, or any file that should outlive the task — write them to a persistent location outside the scratch workspace. A scratch workspace gets garbage-collected when the task is archived; any artifact left only in the scratch dir is lost.

**FOUNDER-REVIEW WORKFLOW:** Unless the task body explicitly says otherwise (e.g. `output_path:` pointing to a final location), write ALL non-code artifacts to the founder-review directory. This gives the founder a chance to review before they become canonical company docs.

- **All non-code deliverables** (FAQ, templates, guides, plans, specs, reports, designs) → `docs/founder-review/<topic>.md`
- **Code changes** (migrations, source files, configs) → commit to the codebase directly (skip founder-review, the CTO/Tech Lead review handles these)
- **Engineering specs, ADRs, architecture notes** → `docs/adrs/` or `docs/engineering/` (assumes CTO/CPO approval chain, not founder-review)

**How to write.**

1. Create or overwrite the file at the designated output path. Use the scratch workspace for intermediate files, then copy the final artifact to the overlay path.
2. cd to the overlay repo and commit:
   ```bash
   cd ~/Work/hermes-yethu-overlay
   git add docs/product/seed-messages.md
   git commit -m "docs: seed messages for teacher community outreach"
   ```
3. If a remote is configured (check `git remote -v`), push. If local-only (no remote), skip the push — the commit is still on disk.
4. Mention the committed artifact path in your `kanban_complete` summary so downstream agents can find it.

**Pitfalls.**

- **Scratch-only output = data loss.** If you write output files only to `$HERMES_KANBAN_WORKSPACE`, they vanish when the task is archived. Always copy durable artifacts to the overlay path.
- **No `output_path` in task body.** If the task body doesn't specify one, pick the best-fitting docs subdirectory and mention it in your handoff summary so the orchestrator adds it to future task bodies.
- **Overlay repo not found.** If `~/Work/hermes-yethu-overlay/` doesn't exist, check the task body for an alternative overlay path. If none exists, write to scratch and block with `help-needed: output path not found — need to configure overlay repo for persistent storage`.
- **Git conflicts.** If the overlay has uncommitted changes from other agents, just `git add` your file — don't touch unrelated files. If a merge conflict occurs, block with `help-needed: git conflict in overlay — needs human resolution`.
- **Don't modify other agents' files.** Only write to your designated output path. The overlay docs tree is shared across all agents — treat it like a collaborative wiki, not your private workspace.
- **Writing outside `$HERMES_KANBAN_WORKSPACE` is allowed for output artifacts.** The scratch restriction applies to intermediate files, not to the final delivery.

## Tenant isolation

If `$HERMES_TENANT` is set, the task belongs to a tenant namespace. When reading or writing persistent memory, prefix memory entries with the tenant so context doesn't leak across tenants:

- Good: `business-a: Acme is our biggest customer`
- Bad (leaks): `Acme is our biggest customer`

## Good summary + metadata shapes

The `kanban_complete(summary=..., metadata=...)` handoff is how downstream workers read what you did. Patterns that work:

**Coding task:**
```python
kanban_complete(
    summary="shipped rate limiter — token bucket, keys on user_id with IP fallback, 14 tests pass",
    metadata={
        "changed_files": ["rate_limiter.py", "tests/test_rate_limiter.py"],
        "tests_run": 14,
        "tests_passed": 14,
        "decisions": ["user_id primary, IP fallback for unauthenticated requests"],
    },
)
```

**Coding task that needs human review (review-required):**

For most code-changing tasks, the work isn't truly *done* until a human reviewer has eyes on it. Block instead of complete, with `reason` prefixed `review-required: ` so the dashboard surfaces the row as needing review. Drop the structured metadata (changed files, test counts, diff/PR url) into a comment first, since `kanban_block` only carries the human-readable reason — comments are the durable annotation channel. Reviewer either approves and runs `hermes kanban unblock <id>` (which re-spawns you with the comment thread for any follow-ups) or asks for changes via another comment.

```python
import json

kanban_comment(
    body="review-required handoff:\n" + json.dumps({
        "changed_files": ["rate_limiter.py", "tests/test_rate_limiter.py"],
        "tests_run": 14,
        "tests_passed": 14,
        "diff_path": "/path/to/worktree",  # or PR url if pushed
        "decisions": ["user_id primary, IP fallback for unauthenticated requests"],
    }, indent=2),
)
kanban_block(
    reason="review-required: rate limiter shipped, 14/14 tests pass — needs eyes on the user_id/IP fallback choice before merging",
)
```

Use `kanban_complete` only when the task is genuinely terminal — e.g. a one-line typo fix, a docs change with no functional consequences, or a research task where the artifact IS the writeup itself.

## Receiving a review-required handoff (the reviewer's perspective)

When you're dispatched for a review task and find the upstream worker blocked their task with `review-required`, here's the protocol:

### 1. Read the handoff

The handoff lives in the comment thread of the blocked task (not your task). Open it with `kanban_show(task_id=upstream_task_id)` and look for a comment with `review-required handoff:` — it should contain structured JSON:

```json
{
  "changed_files": ["rate_limiter.py", "tests/test_rate_limiter.py"],
  "tests_run": 14,
  "tests_passed": 14,
  "verification": {"cargo_build": "passed", "health_endpoint": "200"},
  "decisions": ["user_id primary, IP fallback for unauthenticated requests"],
  "notes": ["dotenvy can't parse multiline PEM values — use base64 for production"]
}
```

Read the full body of the blocked task too — it usually contains the original spec/requirements you're checking against.

### 2. Inspect the work

Use the appropriate tools based on your profile's toolset:

- **If terminal IS available** (default profiles): run build/test commands, `cat` files, inspect directory structure
- **If terminal is NOT available** (e.g. profiles with `terminal` in `disabled_toolsets`): use `read_file` and `search_files` core tools to inspect a representative sample of changed files

What to check depends on the type of work:
- **Architecture/Skeleton**: structure matches spec? Stale code left behind? Dependencies clean?
- **Feature implementation**: follows ADRs? Error handling? Security? Edge cases?
- **Configuration**: Secrets leaked? Hardcoded values? Environment variables documented?

### 3. Decide — two outcomes

**OUTCOME A: APPROVE**

Call `kanban_unblock(task_id=upstream_task_id)` to unblock the upstream worker, then `kanban_complete()` on your own review task with a summary:

```python
kanban_unblock(task_id="t_c9c90462")  # unblock the engineer's task

kanban_complete(
    summary="Step 1 approved — skeleton correct, structure clean, ADRs respected. Proceed to Step 2.",
    metadata={
        "reviewed_files": 12,
        "findings": 0,
        "approved": True,
        "next_step": "Step 2: domain entities",
    },
)
```

**OUTCOME B: REQUEST CHANGES**

Leave a comment on the upstream task with specific, actionable fix requests, then block your own review task:

```python
kanban_comment(
    task_id="t_c9c90462",  # comment on the engineer's task
    body="Changes needed before approval:\n\n"
         "- **blocker**: Settings file has hardcoded DATABASE_URL — move to .env only\n"
         "- **should-fix**: Migration lacks IF NOT EXISTS — rerunning will fail\n"
         "- **nit**: Use ?Sized for the generic bound in error.rs",
)

kanban_block(reason="changes-required: 1 blocker (hardcoded DATABASE_URL), 1 should-fix (migration idempotency), 1 nit — see comment thread")
```

### 4. Create fix tasks for the engineer

When requesting changes (Outcome B), do NOT re-run the original blocked task. Instead, create a new fix task assigned to the original implementer's profile:

```python
fix = kanban_create(
    title="Fix: address Step 1 review feedback",
    assignee="engineer",  # the original implementer
    body="Tech Lead flagged 3 issues on t_c9c90462:\\n"
         "1. [blocker] Hardcoded DATABASE_URL in settings.rs\\n"
         "2. [should-fix] Migration 001_initial.sql lacks IF NOT EXISTS\\n"
         "3. [nit] ?Sized generic bound in error.rs\\n\\n"
         "See the comment thread on t_c9c90462 for details.",
)
```

The new fix task goes to `ready` immediately (no parent dependency).

**CRITICAL: Do NOT complete your own review task at this point.** After creating the fix task, block your review with `changes-required` instead:

```python
kanban_block(reason="changes-required: created fix task for engineer — awaiting fixes before re-review")
```

If you complete your review task instead of blocking it, **you won't be around to unblock the original blocked task** when the fix is done. The engineer's fix task completes but nobody circles back to unblock the parent. The correct flow:

```
Original task blocked (review-required)
  -> Review task: review -> create fix -> BLOCK (changes-required)
    -> Fix task: engineer fixes -> complete
      -> Someone unblocks your review task -> you get re-spawned -> re-review -> unblock original
```

### 5. Re-review after fixes

When your review task is re-spawned (after it was unblocked following the fix task completion):

1. Read the fix task's summary and any new comments on the original task
2. Verify the fixes were applied correctly (inspect files)
3. Decide:
   - **Approved** -> unblock the original task, then complete your review task with a summary
   - **Still needs work** -> block again with updated requirements (create another fix task if needed)

### 6. Pitfalls for reviewers

- **Do NOT link your review task as a child of the blocked task.** The blocked task's status is `blocked`, not `done` — parent dependency engine treats `blocked` as incomplete, so your review task would never promote to `ready`. Create the review task independently. The body of your review task should reference the upstream task ID by prose, not by parent link.

- **Do NOT complete the blocked task yourself.** Call `kanban_unblock()` to approve it. The task body usually instructs the original worker to block, not complete — the unblock is the approval signal that transitions it to running → finish → done.

- **Direct assignment vs. separate review task: different ending protocol.** If the dispatcher routed you directly onto the blocked parent task (you are the task's assignee), the correct closing action is `kanban_unblock()` — NOT `kanban_block()` or `kanban_complete()`. Calling `kanban_block()` re-blocks the task you were sent to unblock, leaving the board stalled. Calling `kanban_complete()` finishes the task as if the work is done, which is wrong for a review. The key distinction:
  - **Directly assigned to parent**: call `kanban_unblock()` on approval — this transitions the parent to `todo`, letting it resume
  - **Separate review task** (Approach A, multi-agent-team skill): call `kanban_unblock(task_id=upstream)` to unblock the parent, then `kanban_complete()` on your own review task

- **If you find no issues, still leave a brief writing.** A comment like "Approved — looks clean, nice work" gives the engineer confidence and creates an audit trail for why the task was unblocked.

- **Severity labels matter.** Use consistent labels so the engineer can prioritize:
  - **blocker** — must fix before deploy (security hole, broken build, data corruption)
  - **should-fix** — not blocking but will cause problems (missing edge case, tech debt)
  - **nit** — style preference, personal taste, minor improvement

**Research task:**
```python
kanban_complete(
    summary="3 competing libraries reviewed; vLLM wins on throughput, SGLang on latency, Tensorrt-LLM on memory efficiency",
    metadata={
        "sources_read": 12,
        "recommendation": "vLLM",
        "benchmarks": {"vllm": 1.0, "sglang": 0.87, "trtllm": 0.72},
    },
)
```

**Review task:**
```python
kanban_complete(
    summary="reviewed PR #123; 2 blocking issues found (SQL injection in /search, missing CSRF on /settings)",
    metadata={
        "pr_number": 123,
        "findings": [
            {"severity": "critical", "file": "api/search.py", "line": 42, "issue": "raw SQL concat"},
            {"severity": "high", "file": "api/settings.py", "issue": "missing CSRF middleware"},
        ],
        "approved": False,
    },
)
```

Shape `metadata` so downstream parsers (reviewers, aggregators, schedulers) can use it without re-reading your prose.

## Claiming cards you actually created

If your run produced new kanban tasks (via `kanban_create`), pass the ids in `created_cards` on `kanban_complete`. The kernel verifies each id exists and was created by your profile; any phantom id blocks the completion with an error listing what went wrong, and the rejected attempt is permanently recorded on the task's event log. **Only list ids you captured from a successful `kanban_create` return value — never invent ids from prose, never paste ids from earlier runs, never claim cards another worker created.**

```python
# GOOD — capture return values, then claim them.
c1 = kanban_create(title="remediate SQL injection", assignee="security-worker")
c2 = kanban_create(title="fix CSRF middleware", assignee="web-worker")

kanban_complete(
    summary="Review done; spawned remediations for both findings.",
    metadata={"pr_number": 123, "approved": False},
    created_cards=[c1["task_id"], c2["task_id"]],
)
```

```python
# BAD — claiming ids you don't have captured return values for.
kanban_complete(
    summary="Created remediation cards t_a1b2c3d4, t_deadbeef",  # hallucinated
    created_cards=["t_a1b2c3d4", "t_deadbeef"],                   # → gate rejects
)
```

If a `kanban_create` call fails (exception, tool_error), the card was NOT created — do not include a phantom id for it. Retry the create, or omit the id and mention the failure in your summary. The prose-scan pass also catches `t_<hex>` references in your free-form summary that don't resolve; these don't block the completion but show up as advisory warnings on the task in the dashboard.

## Block reasons that get answered fast

Bad: `"stuck"` — the human has no context.

Good: one sentence naming the specific decision you need. Leave longer context as a comment instead.

```python
kanban_comment(
    task_id=os.environ["HERMES_KANBAN_TASK"],
    body="Full context: I have user IPs from Cloudflare headers but some users are behind NATs with thousands of peers. Keying on IP alone causes false positives.",
)
kanban_block(reason="Rate limit key choice: IP (simple, NAT-unsafe) or user_id (requires auth, skips anonymous endpoints)?")
```

The block message is what appears in the dashboard / gateway notifier. The comment is the deeper context a human reads when they open the task.

## Heartbeats worth sending

Good heartbeats name progress: `"epoch 12/50, loss 0.31"`, `"scanned 1.2M/2.4M rows"`, `"uploaded 47/120 videos"`.

Bad heartbeats: `"still working"`, empty notes, sub-second intervals. Every few minutes max; skip entirely for tasks under ~2 minutes.

## Worker-side iteration budget management

Every kanban worker has a finite iteration budget per run (`max_turns` or `HERMES_KANBAN_MAX_ITERATIONS`, typically 150). Running out of iterations silently wastes the entire run — no output, no handoff, no recovery. The dispatcher sees a clean exit with no `kanban_complete` or `kanban_block` call.

### The hard ceiling rule

At **~80% of your iteration limit**, regardless of whether you're making progress or stuck, you MUST stop and block the task:

```python
# At ~110 iterations (if max_turns=150):
import os
max_iters = int(os.environ.get("HERMES_KANBAN_MAX_ITERATIONS", "150"))
usage = int(os.environ.get("HERMES_KANBAN_ITERATIONS_USED", "0"))

if usage >= max_iters * 0.8:
    kanban_comment(
        body="## Iteration budget near limit\\n\\n"
             "**Done:** ...\\n"
             "**Remaining:** ...\\n"
             "**Last 3 errors/decisions:** ...",
    )
    kanban_block(
        reason="help-needed: iteration budget near limit (~110/150). "
               "See comment for what's done and what remains."
    )
```

Block with reason `help-needed:` — the Review Router pattern catches these (same as `review-required:`).

### Why this matters

- Running out of iterations without blocking = **silent protocol violation** — the dispatcher logs "worker exited cleanly without calling kanban_complete or kanban_block", and the task goes back to ready for a retry that will hit the same wall
- Blocking early preserves the work already done (comments, changes, decisions) instead of evaporating it
- The Tech Lead (or reviewer) can see the checkpoint and either break the remainder into smaller sub-tasks or provide guidance

### What NOT to do

- **Do NOT let the budget hit 100%** — the last ~30 iterations are your safety margin for blocking cleanly, summarizing, and creating follow-up tasks
- **Do NOT silently continue** — "I'm making progress, I'll go until the end" is the exact mindset that causes silent protocol violations. Progress on an oversized task is still progress toward failure if you can't finish within budget.
- **Do NOT complete a partially-finished task** — completing implies the work is done. Block it so the reviewer sees the real state.

### Retry scenarios

If you open the task and `kanban_show` returns `runs: [...]` with one or more closed runs, you're a retry. The prior runs' `outcome` / `summary` / `error` tell you what didn't work. Don't repeat that path. Typical retry diagnostics:

- `outcome: "timed_out"` — the previous attempt hit `max_runtime_seconds`. You may need to chunk the work or shorten it.
- `outcome: "crashed"` with `error: "pid <X> not alive"` — the spawned process exited immediately before doing any work. In an isolated task this could be OOM or segfault, but **across many tasks at the same timestamp after a bulk unblock**, it signals credential pool exhaustion: the pool has zero available entries, so every new worker dies on startup. Do NOT reclaim/unblock again — check the credential pool and provider first (see "pid not alive" after cascade below).
- `outcome: "crashed"` — OOM or segfault. Reduce memory footprint.
- `outcome: "spawn_failed"` + `error: "..."` — usually a profile config issue (missing credential, bad PATH). Ask the human via `kanban_block` instead of retrying blindly.
- `outcome: "reclaimed"` + `summary: "task archived..."` — operator archived the task out from under the previous run; you probably shouldn't be running at all, check status carefully.
- `outcome: "blocked"` — a previous attempt blocked; the unblock comment should be in the thread by now.

## Do NOT

- Call `delegate_task` as a substitute for `kanban_create`. `delegate_task` is for short reasoning subtasks inside YOUR run; `kanban_create` is for cross-agent handoffs that outlive one API loop.
- Modify files outside `$HERMES_KANBAN_WORKSPACE` unless the task body says to.
- Create follow-up tasks assigned to yourself — assign to the right specialist.
- Complete a task you didn't actually finish. Block it instead.

## Pitfalls

**Two causes of protocol violation, same symptom.** When you see `"worker exited cleanly (rc=0) without calling kanban_complete or kanban_block"`, there are TWO distinct root causes to check. The fix differs, so diagnose before acting.

**Cause A — kanban in disabled_toolsets.** If the profile has `kanban` in `disabled_toolsets` in its `config.yaml`, none of the `kanban_*` tools are available. The worker runs, gets the task body, but exits cleanly without calling `kanban_complete()` or `kanban_block()`. Fix: remove `kanban` from `disabled_toolsets` in the profile's config.yaml. This is a setup-time concern, not something the worker can self-diagnose at runtime.

**Cause B — provider/credential exhaustion (silent protocol violation).** The worker starts but hits upstream API rate limits (HTTP 429), credential pool exhaustion (no valid keys), or a provider that's completely unresponsive.

**Two sub-variants, same symptom:**

- **B1 — Zero-success (classic):** The worker gets ZERO successful LLM responses, never enters the tool-calling loop, and exits cleanly with rc=0. No work was done.
- **B2 — Late-stage rate limit (partial work done):** The worker makes partial or full progress, writes output files, but then hits a rate limit on a later API call (e.g. final summarization or cleanup turn) and exits with rc=0 before calling `kanban_complete`. **Actual work may be complete** — only the protocol handshake was missed.

Both produce the identical `protocol_violation` event and `gave_up` outcome. B2 is the harder variant because the board shows a failed task but the artifact exists.

This is the most common cause of **bulk cascade failures** (10+ tasks all blocked identically at the same timestamp), because all workers spawned in the same dispatch cycle hit the same exhausted credential pool or rate-limited endpoint.

**Diagnosis: distinguish Cause A from Cause B.**

For one or two isolated protocol violations, check the task's workspace path to identify the profile, then:

```bash
# Check the profile config for disabled_toolsets:
cat ~/.hermes/profiles/<profile>/config.yaml | grep -A 5 disabled_toolsets
# If kanban is listed → Cause A

# Check the agent log for upstream errors:
tail -20 ~/.hermes/profiles/<profile>/logs/agent.log
# If you see HTTP 429, credential pool exhaustion ("no available entries"),
# or provider drop errors → Cause B
```

For **bulk cascades** (10+ tasks, often across different profiles), use the multi-profile sweep instead of inspecting each profile individually:

```bash
# Count unique error types across ALL profiles at once
grep -h 'ERROR\|gave_up\|protocol_violation' ~/.hermes/profiles/*/logs/agent.log \
  | sort | uniq -c | sort -rn | head -10

# Also check for credential pool exhaustion globally
grep -h 'credential pool' ~/.hermes/profiles/*/logs/agent.log | sort -u

# Check all profile's provider config vs actual runtime behavior
for p in ~/.hermes/profiles/*/config.yaml; do
    profile=$(basename $(dirname $p))
    config_provider=$(grep -E '^provider:' $p 2>/dev/null | awk '{print $2}')
    config_model=$(grep -E '^model:' $p 2>/dev/null | awk '{print $2}')
    runtime=$(grep -m1 'provider=' ~/.hermes/profiles/$profile/logs/agent.log 2>/dev/null \
      | grep -oP 'provider=\S+' | head -1)
    echo "$profile: config=$config_provider/$config_model runtime=$runtime"
done
```

A single error type dominating (e.g. 50+ HTTP 429 entries, or widespread "no available entries") confirms Cause B with a shared exhausted resource.

For a **bulk cascade** (multiple tasks, often 20-40+, from different profiles all failing at the same timestamp with identical protocol_violation), the root cause is almost certainly **Cause B with a shared credential pool**. Profile-specific fixes won't help — the shared credential pool (or the global provider config) needs attention.

**Critical: Check `kanban.dispatch_in_gateway` in global config.** When this is `true` (the config at `~/.hermes/config.yaml` has `kanban.dispatch_in_gateway: true`), the **gateway dispatches workers and controls their provider routing** — the profile's `provider:` / `model:` / `base_url:` settings may be overridden at the gateway layer. In this mode:
- The profile's `.env` API keys may be ignored in favor of the gateway's credential pool
- The model catalog (~/.hermes/config.yaml `model_catalog` section) maps model names to providers, which may differ from the profile config
- The gateway may route a model (e.g. `deepseek-v4-flash`) through a completely different provider (e.g. MiniMax) without the profile config reflecting it
**Diagnosis when `dispatch_in_gateway: true`:**

When `.env` has DEEPSEEK_API_KEY and ALL profiles show `config=deepseek runtime=minimax`, you have dispatch_in_gateway override. The key diagnostic sequence:

```bash
# 1. Confirm dispatch mode
grep 'dispatch_in_gateway' ~/.hermes/config.yaml

# 2. Check model catalog provider mapping — empty providers = gateway default routing
grep -A 10 'model_catalog' ~/.hermes/config.yaml | head -10
# If `providers: {}` (empty), the gateway uses its internal default mapping —
# NOT a configured override. The model name `deepseek-v4-flash` gets routed
# to whichever provider the gateway code defaults to.

# 3. Check for smart_model_routing and credential_pool_strategies
grep -E 'smart_model_routing|credential_pool_strategies|fallback_providers' ~/.hermes/config.yaml
# If all empty/disabled, the override is happening at the gateway kernel level,
# not through any configurable routing layer.

# 4. The profile config vs runtime mismatch tells you the gateway is overriding
grep -E '^provider:|^model:|^base_url:' ~/.hermes/profiles/<profile>/config.yaml
grep 'provider=' ~/.hermes/profiles/<profile>/logs/agent.log | tail -1
# If config=deepseek but runtime=minimax → gateway routing is the problem
```

**Dual crash pattern in a single cascade wave.** A cascade may produce BOTH "pid not alive" and "protocol violation" outcomes simultaneously across different tasks in the same dispatch cycle. This happens when some workers cannot even acquire a credential (pool exhausted → immediate crash with "pid not alive") while others get a credential but hit the rate limit on their first API call (protocol violation). Both signal the same root cause — the provider/credential pool is exhausted — but the different outcomes can mislead diagnosis into thinking there are two separate problems. If a single wave shows both patterns, treat it as a single Cause B cascade, not two independent issues.

### Output verification: work-done vs. work-not-done

Before fixing the provider and reclaiming, check whether any of the tasks in a Cause B cascade actually **completed their work** before the protocol handshake failed. A worker in the B2 sub-variant (late-stage rate limit) may have written output files successfully but never called `kanban_complete`.

1. **Extract the expected output path from the task body.** Read the first 20-30 lines with `kanban_show`. Task bodies often specify output paths (e.g. "Save to: `docs/design/X.md`", "Output: X.yaml"). Parse one or two key output paths per task.

2. **Verify with `search_files` or `find`.** Check if those paths exist on disk. For scratch-workspace tasks that write to a permanent directory (e.g. `~/Work/yethu/docs/`), the file will exist even though the workspace temp dir is gone.

3. **Sample a representative subset first.** For a bulk cascade (30+ tasks across different profiles), check 3-5 to gauge the pattern:
   - **All 3-5 have output** → likely most tasks completed work. Bulk-`kanban_complete` the ones with verified output; reclaim the rest.
   - **None have output** → pure B1 (zero-success). Skip output verification and go straight to provider fix + reclaim for all.
   - **Mixed** → check each task individually, or do the quick check on tasks with the longest runtime (longer runs were more likely to have done real work).

4. **How to check a running duration from the event log:**

   ```
   # Find runs that ran for more than a minute — likely candidates for B2
   hermes kanban show t_example | grep -E 'spawned|protocol_violation|crashed'
   ```

   A task whose worker ran for 3-8 minutes before exiting is a strong B2 candidate. A task that exited within seconds is likely B1.

5. **Bulk-complete verified tasks:**

   ```bash
   hermes kanban complete t_id1 --summary "Work was completed before protocol violation. File confirmed at docs/design/X.md."
   hermes kanban complete t_id2 --summary "Same pattern — file exists, marking done."
   ```

   Leave a note on the board so later agents don't waste time re-dispatching completed work.

**Fix for Cause B:**

The #1 root cause when `config` shows a different provider than `runtime` (e.g. `config=deepseek runtime=minimax`) is that the `.env` file has **no API key for the configured provider**. Before switching providers or changing config:

```bash
# Diagnosis
grep '^provider:' ~/.hermes/profiles/<profile>/config.yaml
grep 'DEEPSEEK_API_KEY' ~/.hermes/profiles/<profile>/.env
# If the key is missing → that's the root cause
```

**Fix A — Add the missing API key (preferred):**
```bash
echo "DEEPSEEK_API_KEY=sk-xxx..." >> ~/.hermes/profiles/<profile>/.env
```
No config changes needed. The routing layer will use the correct provider once the key exists.

**Fix B — Switch to a provider that actually has a key in `.env`:**
```bash
hermes config set --profile <name> provider deepseek
hermes config set --profile <name> model deepseek-v4-flash
# OR
hermes config set --profile <name> provider openai
hermes config set --profile <name> model gpt-4o
```

If the `.env` already has the correct key but the runtime still routes elsewhere, check:
1. `~/.hermes/config.yaml` for `credential_pool_strategies` that override routing
2. Model catalog URL that maps models to providers
3. `~/.hermes/gateway.yaml` for dispatch-time provider overrides

**Scenario 3 — dispatch_in_gateway override (keys present, gateway routes elsewhere).**
This is the harder scenario: DEEPSEEK_API_KEY (or whatever the configured provider's key) IS present in `.env`, but the gateway still routes through a different provider. Common when `kanban.dispatch_in_gateway: true` in `~/.hermes/config.yaml`.

The clincher diagnostic is the profile sweep — when EVERY profile shows `config=deepseek runtime=minimax` AND the `.env` check confirms the key is present, you can skip individual profile inspection and go straight to the gateway layer:

```bash
# 1. Confirm the mismatch is universal (not profile-specific)
for p in ~/.hermes/profiles/*/config.yaml; do
    profile=$(basename $(dirname $p))
    config_provider=$(grep -E '^provider:' $p 2>/dev/null | awk '{print $2}')
    config_model=$(grep -E '^model:' $p 2>/dev/null | awk '{print $2}')
    runtime=$(grep -m1 'provider=' ~/.hermes/profiles/$profile/logs/agent.log 2>/dev/null \
      | grep -oP 'provider=\S+' | head -1)
    echo "$profile: config=$config_provider/$config_model runtime=$runtime"
done
# If ALL profiles show config=deepseek runtime=minimax → gateway override

# 2. Confirm dispatch_in_gateway is on
grep 'dispatch_in_gateway' ~/.hermes/config.yaml

# 3. Check supporting settings that DON'T explain the override
grep -E 'fallback_providers|smart_model_routing|credential_pool_strategies' ~/.hermes/config.yaml
# If these are all empty/disabled, the gateway is internally routing the model name
# through its default provider mapping rather than falling back

# 4. One profile will route through deepseek directly → confirms it's gateway-specific
# (e.g. mckinsey-consultant often config=/ runtime=provider=deepseek because it's not in the gateway dispatch pool)
```

**Three fix options, in preference order:**

**Fix A — Disable dispatch_in_gateway (simplest, forces profiles to use their own config):**
```bash
hermes config set kanban.dispatch_in_gateway false
```
This lets each profile use its own `provider:` and API key directly. No routing layer between the profile and the provider. Best when the profile configs are already correct (which they are — they say `deepseek` and have the key).

**Fix B — Update the model catalog to route the model through the correct provider:**
The model catalog at `~/.hermes/config.yaml` → `model_catalog.url` controls provider routing. If the catalog maps `deepseek-v4-flash` to minimax, either:
- Override it locally by adding `providers: {deepseek-v4-flash: {provider: deepseek}}` in the model_catalog section
- Or fix the upstream catalog (if self-hosted)

```bash
# Check current model catalog
curl -s "$(grep 'model_catalog.url' ~/.hermes/config.yaml | awk '{print $2}')" | python3 -c "import json,sys; d=json.load(sys.stdin); # inspect structure"
```

**Fix C — Route through OpenRouter instead (if available):**
```bash
hermes config set --profile <name> provider openrouter
hermes config set --profile <name> model openrouter/deepseek/deepseek-v4-flash
```
Only if OPENROUTER_API_KEY is present in `.env` and OpenRouter supports the model.

**Diagnostic shortcut for future sessions:** When `.env` has DEEPSEEK_API_KEY and ALL profiles show `config=deepseek runtime=minimax`, you have dispatch_in_gateway override — skip the "add the missing key" fix and go straight to the gateway routing.

For the full worked example including the exact MiniMax 429 error, credential pool exhaustion cascade, and the `mckinsey-consultant` exception signal, see `references/dispatch-in-gateway-override-pattern.md`.

After fixing, reclaim the tasks for a clean retry:
```bash
hermes kanban reclaim <task_id>   # one at a time, or use a script
```

**Task state can change between dispatch and your startup.** Between when the dispatcher claimed and when your process actually booted, the task may have been blocked, reassigned, or archived. Always `kanban_show` first. If it reports `blocked` or `archived`, stop — you shouldn't be running.

**gave_up tasks are invisible to review routers.** A task that timed out or crashed and was marked `gave_up` by the dispatcher ends up with `status: blocked` but the block reason is set by the system (e.g. `"elapsed 901s > limit 900s"`), NOT by a worker with a `review-required:` or `help-needed:` prefix. The Review Router (which scans for those prefixes) will skip these tasks entirely. This means gave_up tasks have **no automated path to escalation** unless a separate monitoring agent (CoS, PMO) explicitly inspects the event log for `gave_up` outcomes. If you're a monitoring agent scanning the board, do NOT rely on `kanban_list --status blocked` + grep for block reason — you must `kanban_show` each blocked task and check its `events` array for `gave_up` entries.

**`--max-runtime` vs `gateway_timeout` mismatch — the config gap.** The profile's `gateway_timeout` (e.g. 3600s / 60 min) controls how long the LLM API call can run within a single worker turn. The kanban task's `--max-runtime` (set at task-creation time, defaults to 900s / 15 min) controls how long the entire worker process can live before the dispatcher kills it. **Setting profile `gateway_timeout` alone does NOT extend the kanban task's runtime.** The dispatcher kills at `limit_seconds` regardless of the profile's timeout. This is the most common cause of repeated timed_out / gave_up runs that look like a stuck worker but are actually a config mismatch.

Symptoms: `kanban_show` shows multiple `timed_out` events with `limit_seconds: 900` (or whatever the default is) and `elapsed_seconds` just above the limit. The profile's `gateway_timeout` may already be set higher, but the kanban task's baked-in `--max-runtime` overrides it.

Fix: create new tasks with `--max-runtime 3600` (or whatever duration matches the profile's `gateway_timeout`). There is no way to change `--max-runtime` after task creation (`hermes kanban edit` only works on completed tasks for backfilling). You must archive the old task and create a fresh one with the correct flag:

```
hermes kanban create "My task" \
  --assignee engineer \
  --parent t_parent_id \
  --max-runtime 3600 \
  --max-retries 3
```

`--max-retries` accepts seconds (3600), durations (60m, 2h), or any reasonable time string. `--max-retries` overrides the dispatcher's `kanban.failure_limit` (default 2) and allows more retries before gave_up.

This is why a retry death spiral (unblock → timeout → gave_up) can happen even after bumping the profile's `gateway_timeout`. Always check both settings. If you're diagnosing a death spiral and see identical `limit_seconds` across all runs, the per-task `--max-runtime` is the culprit, not the profile config.

**Unblock without root cause fix — the retry death spiral.** When a gave_up task is unblocked (manually or by a router) without fixing the root cause that killed it (timeout too short, provider drop, missing credential), the worker respawns and fails with the identical error. This creates a retry death spiral: unblock → spawn → timeout → gave_up → unblock → spawn → timeout → gave_up ... ad infinitum. Telltale signs on `kanban_show`:
- Multiple `gave_up` events interleaved with `unblocked` events
- All runs have the same `error` and approximate `elapsed_seconds`
- No `blocked` events from the worker itself (no human-set block reason)
- **The `Diagnostics (N):` section shows `consecutive_failures > max-retries`** — a task with `max-retries: 2` but `consecutive_failures=5` means the operator manually unblocked it 3 extra times without fixing the root cause.

**Three-wave or N-wave death spirals.** A retry death spiral can cycle through 3+ complete waves, not just the classic 2-wave pattern (protocol_violation → pid_not_alive). The full cycle is:
```
Wave 1: protocol_violation (worker starts, hits 429/provider error, exits without kanban_complete)
   → unblock (no fix)
Wave 2: pid_not_alive (credential pool exhausted from Wave 1)
   → unblock (no fix)
Wave 3: protocol_violation again (pool cooldown expired, but same provider error repeats)
   → unblock (no fix)
...ad infinitum
```
Each complete wave = one unblock + one spawn + one failure. The `Diagnostics` summary field showing `consecutive_failures=N` + `most_recent_outcome=crashed` is the fastest way to detect this — you don't need to parse individual event timestamps. A task that cycled 3+ times is a **definitive signal** that the root cause has NOT been addressed despite repeated intervention. The operator is blindly unblocking.

If you're a monitoring agent and spot this pattern (especially `consecutive_failures > max-retries`), **do NOT unblock the task again**. Instead:
1. Identify the root cause from the error message (typically `limit_seconds` too low, provider stream drop, or missing config)
2. Fix the root cause (profile timeout, provider switch, credential setup)
3. Then reclaim/unblock the task for a clean retry

**Workspace may have stale artifacts.** Especially `dir:` and `worktree` workspaces can have files from previous runs. Read the comment thread — it usually explains why you're running again and what state the workspace is in.

**"pid not alive" after cascade = credential pool exhaustion.** When you see `pid <X> not alive` across **many tasks at the same timestamp** — especially after a bulk unblock of tasks that previously crashed with "protocol violation" — the root cause is almost certainly an exhausted credential pool, not broken workers.

The mechanism: the first dispatch wave consumed all available credentials (or all of them hit the same rate limit and were exhausted). When the tasks are unblocked and re-dispatched without fixing the provider, new worker processes spawn but cannot acquire a credential from the empty pool. They exit immediately, and the dispatcher logs:

```
[run N] crashed {'pid': XXXXX, 'claimer': '...'}
gave_up {'failures': N, 'error': 'pid XXXXX not alive', ...}
```

This is a **definitive diagnostic signal** that unblocking was premature. The credential pool needs attention before any task can make progress.

Diagnosis — confirm it's cascade-driven (not isolated):

```bash
# Count tasks with "pid not alive" at the same timestamp
for tid in $(hermes kanban list --status blocked 2>&1 | grep '⊘' | awk '{print $2}'); do
    hermes kanban show "$tid" 2>&1 | grep -c 'not alive'
done | sort | uniq -c

# Check credential pool exhaustion across all profiles
grep -h 'credential pool.*no available' ~/.hermes/profiles/*/logs/agent.log \
  | sort | uniq -c
```

If most tasks have 1-2 "not alive" events clustered at the same minute, and credential pool exhaustion logs exist at that same minute → confirmed.

Fix: **Do NOT unblock or reclaim.** The root cause is the credential pool or provider routing — fix that first (see "Fix for Cause B" above), then reclaim tasks once the provider is verified working.

The #1 root cause in practice: **profiles have `provider: deepseek` in config.yaml but no `DEEPSEEK_API_KEY` in `.env`**. The routing layer silently falls back to whatever provider key IS present (e.g. MiniMax). Check this FIRST:

```bash
# 1. Check if the configured provider's key exists
grep -l '^provider: deepseek' ~/.hermes/profiles/*/config.yaml 2>/dev/null | while read cfg; do
    profile=$(basename $(dirname $cfg))
    has_key=$(grep -c 'DEEPSEEK_API_KEY' ~/.hermes/profiles/$profile/.env 2>/dev/null || echo 0)
    echo "$profile: has_deepseek_key=$has_key"
done

# 2. If keys are missing, add them
echo "DEEPSEEK_API_KEY=sk-xxx..." >> ~/.hermes/profiles/engineer/.env

# 3. Verify one task works before bulk-reclaiming
hermes kanban dispatch

# 4. Only then reclaim the rest
hermes kanban reclaim t_id1 t_id2 ...
```

**Don't rely on the CLI when the guidance is available.** The `kanban_*` tools work across all terminal backends (Docker, Modal, SSH). `hermes kanban <verb>` from your terminal tool will fail in containerized backends because the CLI isn't installed there. When in doubt, use the tool.

## Stuck Workers (Alive but Not Progressing)

A worker can be **alive (PID exists) but making zero progress** — the most common cause is the upstream LLM provider dropping the connection mid-stream. The gateway's dispatcher keeps extending the claim because `pid_alive` returns True, so the task never times out or gets reclaimed on its own.

### Symptoms

- `kanban_show` shows `status: running` with an active `claim`, but the worker has been running far longer than the task warrants
- `ps aux` shows the worker PID in state `Ssl` (sleeping, multi-threaded) or possibly `<defunct>` (zombie)
- The profile's `agent.log` has a **stream drop** warning:
  ```
  WARNING run_agent: Stream drop on attempt N/3 — retrying.
  error=RemoteProtocolError(peer closed connection without sending complete message body (incomplete chunked read))
  ```
  Followed by:
  ```
  WARNING run_agent: Failed to rebuild shared OpenAI client (stream_retry_pool_cleanup)
  ```
- Agent.log goes silent after the stream drop — no new API calls logged for minutes

### Diagnosis procedure (from the outside)

1. **Check the process** — `ps aux | grep <pid>` or `ps -p <pid> -o pid,stat,etime,%cpu --no-headers`. If the process has been running for 15+ minutes with no recent log entries, it's stuck.
2. **Check the agent log** — `tail -20 ~/.hermes/profiles/<profile>/logs/agent.log`. Look for `Stream drop` warnings and the last `API call` timestamp.
3. **Check for zombie processes** — `<defunct>` in `ps` output means the kernel hasn't reaped it yet. Kill it with `kill <pid>`.
4. **Check the task events** — `hermes kanban show <task_id>`. Look for `claim_extended {'reason': 'pid_alive', ...}` events that keep renewing the lock. If present, the dispatcher is fooled by the still-alive PID.

### Recovery procedure

```bash
# 1. Kill the stuck process
kill <pid>

# 2. Reclaim the task (returns it to ready/pending)
hermes kanban reclaim <task_id>

# 3. (Optional) Fix the root cause if it was provider-related:
#    - Edit the profile's config.yaml to switch to a more reliable provider
#    - Set both `provider:` and `model:` explicitly
#    - Example: switch from MiniMax to DeepSeek:
#      provider: deepseek
#      model: deepseek-v4-flash

# 4. Force dispatch to pick it up immediately
hermes kanban dispatch
```

The dispatcher should spawn a new worker on the next cycle (~60s) or immediately with `hermes kanban dispatch`.

### Provider quirks that cause stuck workers

**MiniMax:** Known for dropping connections mid-stream after ~388 seconds (6.5 minutes) of streaming with 115KB+ of data. The retry pool also fails with "The api_key client option must be set" — the API key isn't available to the retry mechanism. Switching the profile to a more reliable provider (DeepSeek, Anthropic, OpenAI) is the definitive fix.

**General pattern:** Any provider that requires long-running streaming responses is susceptible. Keep the profile's `agent.log` in mind when a kanban worker seems to be taking much longer than expected. If the same profile gets stuck the same way twice, switch providers rather than retrying on the same one.

## Escalation protocol for gave_up tasks (monitoring agents)

When you are a monitoring agent (CoS, PMO Board Monitor, or similar) scanning the board and find a gave_up task, you must distinguish between first-time and repeated failure. The wrong response (silent report, or unblock without diagnosis) lets the task rot silently.

### Triage levels

| Gave up count | Severity | Action |
|---|---|---|
| 1 | Monitor | Report in your output. Do NOT unblock — the dispatcher's retry mechanism handles first failures. Note the failure reason for trend spotting. |
| 2 | Yellow | Inspect the runs: are all failures identical? If yes → do NOT unblock, flag the root cause pattern. Create an escalation task if the failure seems chronic. |
| 3+ | Red | **Escalate to founder.** Create a kanban task assigned to the founder/human operator with the failure history, suspected root cause, and recommended fix (e.g. "increase gateway_timeout on engineer profile to 3600s" or "switch provider from MiniMax to DeepSeek"). Do NOT keep unblocking — that creates the retry death spiral (see Pitfalls). |

### What to include in an escalation task

```python
esc = kanban_create(
    title="ESCALATION: Task <id> gave up N times — needs root cause fix",
    assignee="<founder-human>",  # e.g. "ceo" or the human operator
    body=(
        "## Escalation: Repeated task failure\n\n"
        f"**Task:** {task_id} ({title})\n"
        f"**Assignee:** {assignee}\n"
        f"**Failed attempts:** {len(runs)}\n"
        f"**Last error:** {last_error}\n\n"
        "### Run history\n"
        f"{run_summary_table}\n\n"
        "### Recommended fix\n"
        f"{suspected_cause_and_fix}\n\n"
        "### Current status\n"
        "Task is blocked. DO NOT unblock without fixing root cause first."
    ),
)
```

### How to detect gave_up tasks in a scan

`kanban_list()` does NOT show gave_up directly. Use this pattern:

```python
board = kanban_list(all=True)  # or filter by status if available
blocked_tasks = [t for t in board.get("tasks", []) if t["status"] == "blocked"]

for t in blocked_tasks:
    detail = kanban_show(task_id=t["id"])
    gave_up_count = sum(
        1 for e in detail.get("events", [])
        if e["kind"] == "gave_up"
    )
    if gave_up_count > 0:
        # This is a stuck gave_up task — follow triage above
        pass
```

Do NOT rely on the `latest_summary` field — it may be `null` for timed-out runs. The `events` array is the source of truth. For the full JSON schema reference (task nesting, event kinds, runs structure, parsing quirks), see `references/kanban-show-json-schema.md` in this skill.

### What monitors should NOT do

- **Do NOT unblock a gave_up task without diagnosing why.** If you don't know the root cause, leave it blocked and escalate.
- **Do NOT treat "reported in my output" as sufficient.** A monitor that silently reports "found 2 gave_up tasks" in its cron output but does nothing else is effectively invisible. If the failure count is ≥2, create an escalation task.
- **Do NOT complete the escalation task yourself** — you're escalating to the human; they decide.
- **Do NOT use the review router as a substitute for gave_up monitoring.** The router only catches `review-required:` and `help-needed:` blocks. gave_up tasks are its blind spot by design.
- **Do NOT create duplicate escalation tasks.** Before creating an escalation task, scan the board with `kanban_list()` and search for any existing task whose title or body references the failing task ID. If one exists, note the existing ID in your output and skip creation. Duplicate escalation tasks spam the board and desensitize the escalation point.

## Board Health Scan — Full Procedure

When you are a monitoring agent performing a scheduled board health scan (PMO, CoS, or similar cron job), follow this systematic procedure to produce a complete governance report. Do NOT skip steps — each catches a different class of problem.

### Step 1: Board overview

Get the full task listing and summarize counts by status:

```python
from hermes_tools import terminal

result = terminal("hermes kanban list 2>&1")
lines = result["output"].strip().split("\n")

# Parse the 4-column fixed-width format: <symbol> <t_id>  <status>   <assignee>  <title>
stats = {"done": 0, "blocked": 0, "running": 0, "ready": 0}
for line in lines:
    parts = line.strip().split()
    if len(parts) < 4:
        continue
    symbol = parts[0]
    if symbol == "✓": stats["done"] += 1
    elif symbol == "⊘": stats["blocked"] += 1
    elif symbol == "●": stats["running"] += 1
    elif symbol == "▶": stats["ready"] += 1

print(f"Total: {sum(stats.values())} | Done: {stats['done']} | Blocked: {stats['blocked']} | Running: {stats['running']} | Ready: {stats['ready']}")
```

If the ratio of blocked to total is alarmingly high (e.g. >50%), the board may have a systematic failure in progress — proceed to Step 3 quickly rather than inspecting each task individually.

**Critical: `kanban_list()` as a Python tool may not be available** (e.g. when the PMO profile has `kanban` in `disabled_toolsets` or uses a terminal-only backend). The `hermes kanban list` CLI command is the reliable fallback. Parse its stdout using the symbol-based pattern above.

### Step 2: Identify gave_up / crashed tasks

Not all blocked tasks are equal. Gave_up and crashed tasks are dead — the dispatcher's retry mechanism has exhausted its attempts. Extract them from the blocked list:

**Fast scan with the Diagnostics field:** The quickest way to detect gave_up/crashed tasks is to check for the `Diagnostics (N):` section in `kanban_show` output. This field appears at the top of the task detail and immediately tells you:

```
  Diagnostics (1):
    !! [error] Agent crash x5: worker exited cleanly (rc=0) without calling kanban_complete or kanban_block — protocol violation
       data: consecutive_failures=5 | most_recent_outcome=crashed | last_error=worker exited cleanly...
```

If `Diagnostics` is present, the task has had consecutive failures. The count (e.g. `consecutive_failures=5`) tells you severity without parsing individual events. A single `grep -c 'Diagnostics'` across `kanban_show` for each blocked task is the fastest gave_up detector.

**Full scan with run/event parsing (when you need exact counts):**

```python
# Get blocked tasks from the CLI
result = terminal("hermes kanban list --status blocked 2>&1")
blocked_lines = [l.strip() for l in result["output"].split("\n") if l.strip()]

gave_up_tasks = []
for line in blocked_lines:
    parts = line.split()
    if len(parts) < 4:
        continue
    task_id = parts[1]
    assignee = parts[3]
    title = " ".join(parts[4:])
    
    # Inspect each blocked task's event log
    show = terminal(f"hermes kanban show {task_id} 2>&1 | head -20")
    output = show.get("output", "")
    
    # Check for gave_up, crashed, or protocol_violation
    if "gave_up" in output or "crashed" in output or "protocol_violation" in output or "Diagnostics" in output:
        # Count gave_up events
        count_lines = terminal(f"hermes kanban show {task_id} 2>&1 | grep -c 'gave_up'")
        try:
            gave_up_count = int(count_lines.get("output", "0").strip())
        except:
            gave_up_count = 1
        
        # Count distinct run outcomes
        run_lines = terminal(f"hermes kanban show {task_id} 2>&1 | grep -E '#[0-9]+ (crashed|timed_out|gave_up)' | head -5")
        run_summary = run_lines.get("output", "")
        
        gave_up_tasks.append({
            "id": task_id,
            "assignee": assignee,
            "title": title[:80],
            "gave_up_count": gave_up_count,
            "runs": run_summary,
        })

print(f"Found {len(gave_up_tasks)} tasks with gave_up/crashed events")
```

Apply the triage levels from the Escalation Protocol section above:
- **Count = 1** → monitor, note in report
- **Count = 2** → yellow, create escalation if failures are identical
- **Count ≥ 3** → red, escalate to founder immediately

### Step 3: Cross-reference agent logs to diagnose root cause

When multiple tasks across different profiles fail identically (a **bulk cascade**), you have Cause B (provider/credential exhaustion) until proven otherwise. Do NOT inspect individual tasks — go straight to the logs:

```python
# Pick one profile that had failures
sample_profile = "engineer"  # or whatever had the most failures
log_check = terminal(f"grep -E 'ERROR|WARNING.*API call' ~/.hermes/profiles/{sample_profile}/logs/agent.log | tail -10")
print(log_check["output"])
```

Look for these patterns:

**Pattern 1 — HTTP 429 rate limiting (most common in bulk cascades):**
```
ERROR ... API call failed after 3 retries. HTTP 429: {'type': 'error', 'error': {'type': 'rate_limit_error', ...}}
```
This means the provider is rate-limiting. No workers can make progress until the rate limit resets or the provider is changed. For a bulk cascade, this is almost always the cause.

**Pattern 2 — credential pool exhaustion:**
```
credential pool: no available entries (all exhausted or empty)
```
All API keys in the pool have been consumed or rate-limited. New workers start but never get a valid credential.

**Pattern 3 — stream drops (isolated/ongoing runs only):**
```
WARNING run_agent: Stream drop on attempt N/3 — retrying.
error=RemoteProtocolError(peer closed connection without sending complete message body)
```
This indicates a stuck worker may exist — check the Stuck Workers section above.

**Pattern 4 — clean log with API successes but task still blocked:**
If the log shows successful API calls with `kanban_*` tool completions, the task may have an internal bug unrelated to provider health. This is rare in cascades but possible for isolated failures.

**Confirm it's a cascade (not Cause A):**

```bash
# Quick check across profiles — do they all hit the same error?
grep -h 'ERROR\|gave_up\|protocol_violation' ~/.hermes/profiles/*/logs/agent.log | sort | uniq -c | sort -rn | head -10
```

A single error type dominating (e.g. 50+ HTTP 429 entries, or widespread "no available entries") confirms Cause B with a shared exhausted resource.

**Critical: Check `.env` for API key presence across profiles (do this before checking global config!)**

When the runtime shows a different provider than the config (e.g. `config=deepseek runtime=minimax`), the MOST LIKELY root cause is that the configured provider's API key is **absent** from `.env` files. The credential pool has no valid key for the configured provider, so the router falls back to whichever provider DOES have a key available.

```bash
# Check which API keys each profile actually has
for f in ~/.hermes/profiles/*/.env; do
    p=$(basename $(dirname $f))
    keys=$(grep -oP '^[A-Z_]+_API_KEY' $f 2>/dev/null | tr '\n' ' ')
    echo "$p: $keys"
done
```

**Real-world example from a 71-task cascade:**
```bash
# Profiles had provider: deepseek in config.yaml
$ grep '^provider:' ~/.hermes/profiles/engineer/config.yaml
provider: deepseek

# But .env had NO DEEPSEEK_API_KEY — only MINIMAX_API_KEY
$ grep 'DEEPSEEK\|MINIMAX' ~/.hermes/profiles/engineer/.env
MINIMAX_API_KEY=sk-xxx...
# DEEPSEEK_API_KEY is missing!

# Result: routing fell back to minimax@api.minimax.io/anthropic
# → All 71 workers hit MiniMax HTTP 429 "Token Plan" rate limit
```

**Root cause diagnosis:**
- Config says `provider: deepseek` but `.env` has no `DEEPSEEK_API_KEY` → **definitive**, fix is to add the key
- Config says `provider: deepseek` and `.env` HAS `DEEPSEEK_API_KEY` but runtime still hits `minimax` → check global credential pool config (~/.hermes/config.yaml), model catalog, or gateway routing
- Config says `provider: deepseek` and `.env` has BOTH keys → routing-layer issue, check credential pool strategies

**The fix when `.env` lacks the configured provider's key:** Add the missing API key, then verify with one test dispatch before bulk-reclaiming tasks. Do NOT change the profile's `provider:` setting — the config is correct; the credential is what's missing.

### Step 4: Check WIP limits per assignee

```python
result = terminal("hermes kanban list 2>&1")
running_by_assignee = {}
for line in result["output"].strip().split("\n"):
    parts = line.strip().split()
    if len(parts) >= 4 and parts[0] == "●":  # running symbol
        assignee = parts[3]
        running_by_assignee[assignee] = running_by_assignee.get(assignee, 0) + 1

over_limit = {a: c for a, c in running_by_assignee.items() if c > 3}
if over_limit:
    for a, c in over_limit.items():
        print(f"WIP VIOLATION: {a} has {c} running tasks (limit: 3)")
```

Tasks in `blocked` status don't count toward WIP — only `running` (dispatched/in-progress) tasks.

The WIP check here is a **snapshot-based detection** (parsing `hermes kanban list` output), which is the most reliable approach. Do NOT rely on a hypothetical `kanban_wip_check()` tool — use the snapshot method.

### Step 5: Verify running tasks are alive

Running tasks with no recent API activity are likely **stuck workers** (PID alive but making zero progress). Check each running profile's agent.log freshness:

```bash
# For each assignee with running tasks, check their latest agent.log timestamp
for profile in engineer cpo cto cmo coo legal finance designer; do
    last_log=$(tail -1 ~/.hermes/profiles/$profile/logs/agent.log 2>/dev/null | grep -oP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')
    [ -n "$last_log" ] && echo "$profile: last activity $last_log"
done
```

A profile whose last log entry is >5 minutes old with no API call in the visible buffer may have a stuck worker. Cross-reference with `kanban_show` on that profile's running task — look for `claim_extended` events with `reason: pid_alive` (see Stuck Workers section above for diagnosis and recovery).

For the most reliable check, inspect the raw log for the last `API call` or tool completion timestamp:

```bash
# Get the most recent API call timestamp
grep 'API call #[0-9]' ~/.hermes/profiles/<profile>/logs/agent.log | tail -1 | grep -oP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
```

If the gap between "now" and the last API call exceeds the profile's `gateway_timeout`, the worker is likely stuck.

### Step 6: Check ready tasks for viability

Tasks in `ready` status will be dispatched next. If the board is in a bulk cascade failure (Step 3 confirmed Cause B), these tasks will also fail immediately upon dispatch. Note them in the report so the operator can hold dispatch or fix first:

```python
result = terminal("hermes kanban list 2>&1")
for line in result["output"].strip().split("\n"):
    parts = line.strip().split()
    if len(parts) >= 4 and parts[0] == "▶":  # ready symbol
        task_id = parts[1]
        assignee = parts[3]
        title = " ".join(parts[4:])
        print(f"READY (will fail if dispatched in current state): {task_id} ({assignee}): {title}")
```

**CRITICAL: Verify the assigned profile exists.** A ready task assigned to a non-existent profile will never be claimed. Check against `hermes profile list`:

```bash
# Get all valid profile names
profiles=$(hermes profile list 2>&1 | tail -n +2 | awk '{print $1}' | tr '\n' ' ')

# For each ready task, check if its assignee is in the profile list
# If not, the task is orphaned — fix immediately:
hermes kanban reassign <task_id> <correct_profile_name>
```

Do NOT just report orphaned ready tasks — fix them on the spot. Common mismatches:
- `audit` → `audit-governance`
- `cfo` → `finance`
- `sales` → `sales-bd`
- `cmo-team` → individual CMO team profile names

After reassigning, the dispatcher picks them up on the next cycle.

For the full worked example (including session that found `audit` and `cfo` assigned to non-existent profiles), see `references/proactive-fixes-during-board-scan.md`.

### Step 7: Produce the report

Format findings in a structured report with these sections, in order:

1. **Board Overview** — count by status
2. **Critical Findings** (🔴) — bulk cascade, gave_up≥3 tasks, stuck workers
3. **Yellow Findings** (🟡) — gave_up=2 tasks, WIP violations, tasks blocked >30 min
4. **Green Findings** (🟢) — running tasks verified alive, no issues
5. **Escalation / Recommended Actions** — specific commands to fix root cause, list of task IDs to reclaim, profiles to reconfigure

Example report format:

```
🔴 CRITICAL: Bulk Cascade Failure — MiniMax API Rate Limiting
  Root cause: provider=minimax returning HTTP 429 on all profiles
  Error: "The Token Plan is designed for individual, interactive developer workflows."
  Config says deepseek but .env files lack DEEPSEEK_API_KEY — routing falls back to minimax
  71 tasks blocked, all gave_up (retries exhausted)
  Affected profiles: engineer(11), growth-lead(8), community-manager(7), content-marketing(7),
    customer-success(6), operations-analyst(6), sales-bd(5), cpo(4), pmo(4), user-research(4),
    rmo(3), audit-governance(3), designer(2), tech-lead(1)
  Recommended fix: Add DEEPSEEK_API_KEY to all profile .env files, then bulk-reclaim

🟡 WIP: No violations (0 running tasks)
🟡 Stale blocked: N/A — all blocked tasks are from the same cascade event (<1h old)

🟢 Running tasks: 0 verified alive
🟢 Ready tasks: 0 (none queued — board is fully stalled)
```

For the full cascade diagnosis details including exact error transcripts, log examples, and the profile config vs runtime provider mismatch diagnostic, see `references/provider-429-cascade-diagnosis.md` in this skill. For the specific MiniMax 429 cascade pattern (the "Token Plan" error, `api.minimax.io/anthropic` endpoint, and config-deepseek vs runtime-minimax mismatch), see `references/minimax-429-cascade-pattern.md`. For the two-wave cascade pattern (protocol_violation → unblock → "pid not alive" on retry), see `references/two-wave-429-pid-not-alive-cascade.md`.

For the human-operator perspective on routing review-required blocks from the CLI, changing a running profile's model/provider, and the quick 3-command unblock sequence (`reassign → unblock → dispatch`), see `references/human-operator-review-routing.md`.

## CLI fallback (for scripting)

Every tool has a CLI equivalent for human operators and scripts:
- `kanban_show` ↔ `hermes kanban show <id> --json`
- `kanban_complete` ↔ `hermes kanban complete <id> --summary "..." --metadata '{...}'`
- `kanban_block` ↔ `hermes kanban block <id> "reason"`
- `kanban_create` ↔ `hermes kanban create "title" --assignee <profile> [--parent <id>]`
- etc.

Use the tools from inside an agent; the CLI exists for the human at the terminal.

## Review Router — Dedicated Agent Role

The Review Router is a cron-fired agent that scans blocked kanban tasks every 5 minutes and routes `review-required:` or `help-needed:` tasks to the Tech Lead. It does NOT diagnose root causes or fix provider issues — its scope is purely routing.

### Routing Rules

```python
# Pseudocode for the routing logic:
for each blocked task:
    block_reason = extract_block_reason(task)
    assignee = task.assignee
    events = task.events

    # Check for gave_up / crashed — these are dead tasks, not routable blocks
    if any(e.kind in ("gave_up", "crashed") for e in events):
        SKIP  # Note in report for CoS scan, do NOT touch

    if assignee == "tech-lead":
        SKIP  # Already at the right person. Leave a comment noting it was pre-routed.

    if block_reason.startswith("review-required:") and assignee != "tech-lead":
        ROUTE  # Reassign to tech-lead, then unblock
    elif block_reason.startswith("help-needed:") and assignee != "tech-lead":
        ROUTE  # Reassign to tech-lead, then unblock
    else:
        SKIP  # Unknown block reason — leave for CoS/monitoring agent
```

### What gave_up detection means for routing

Tasks with `gave_up` or `crashed` outcomes appear as `blocked` on the board but the block reason is **system-generated** (e.g. `"elapsed 901s > limit 900s"` or `"worker exited cleanly (rc=0)..."`), NOT from a worker's `kanban_block` call. The Review Router must distinguish these via the events array (check for `gave_up`/`crashed` event kinds). Do NOT rely on `kanban_list --status blocked` + block reason grep — you must `kanban_show` each task and inspect its event log.

### Reporting

After the scan, produce a concise report showing:
1. How many tasks were routed (with IDs and block reasons)
2. How many were skipped due to gave_up/crashed (count them)
3. How many were already on tech-lead
4. Any unexpected findings

If zero tasks needed routing, say so explicitly — do NOT return silent.

### Example session output

```
## Review Router — 2026-05-14 17:39

**71 blocked tasks scanned.**
- Routed to tech-lead: 0 (no review-required or help-needed blocks found)
- Skipped (gave_up/crashed): 71 (bulk cascade failure — flagged for CoS)
- Already on tech-lead: 0
```

### Common pitfalls for Review Routers

- **Do NOT route gave_up tasks** — calling `kanban_unblock` on a gave_up task without fixing the root cause creates a retry death spiral (unblock → spawn → timeout → gave_up → repeat)
- **Do NOT reassign from tech-lead** — if already assigned to tech-lead, leave it. The Tech Lead will handle it on the next dispatch cycle.
- **Do NOT diagnose provider issues** — the Review Router's job is routing only. If you spot a bulk cascade, flag it in your report for the CoS/monitoring agent but don't try to fix provider config or reclaim tasks.
- **Do NOT use `kanban_list()` as a Python tool** — it may not be available depending on profile config. Fall back to `hermes kanban list --status blocked` CLI output.
- **Events array is the source of truth** — the `latest_summary` field may be `null` for timed-out runs. Always read the events array to detect gave_up/crashed outcomes.

For automated board health scans and review-router runs, use the `scripts/scan-blocked-tasks.py` script bundled with this skill. It implements the full Step 1–7 scanning logic:

```bash
# Full scan — all blocked tasks, JSON report
python3 ~/.hermes/skills/devops/kanban-worker/scripts/scan-blocked-tasks.py

# Quick summary only
python3 ~/.hermes/skills/devops/kanban-worker/scripts/scan-blocked-tasks.py --summary-only

# Only show tasks that need routing to tech-lead
python3 ~/.hermes/skills/devops/kanban-worker/scripts/scan-blocked-tasks.py --routable-only

# CSV output for dashboards
python3 ~/.hermes/skills/devops/kanban-worker/scripts/scan-blocked-tasks.py --format csv
```

The script handles all three event kinds (`gave_up`, `crashed`, `protocol_violation`), extracts block reasons from both the task record and event log, and applies the correct routing/triage recommendation per the Board Health Scan procedure above.
