# `kanban show --json` — Schema Reference

Captured from actual usage (May 2026). The JSON output differs from the text output in ways that snag automated parsers.

## Top-level structure

```json
{
  "task": { ... },           // the task record
  "latest_summary": "...",   // may be null
  "parents": [...],          // parent task IDs
  "children": [...],         // child task IDs
  "comments": [...],         // comment thread
  "events": [...],           // event log (source of truth for block reasons)
  "runs": [...]              // worker run records
}
```

## Task record fields

```json
{
  "id": "t_XXXXXXXX",
  "title": "...",
  "body": "...",               // May contain unescaped control characters! Use json.loads(strict=False)
  "assignee": "...",
  "status": "blocked|todo|running|done",
  "priority": 0-5,
  "tenant": null,
  "workspace_kind": "scratch|worktree|dir:...",
  "workspace_path": "...",
  "created_by": "...",
  "created_at": unix_timestamp,
  "started_at": unix_timestamp,
  "completed_at": null,
  "result": null,
  "skills": [],
  "max_retries": null
}
```

## Critical: block_reason is NOT in the task record

There is no `block_reason` or `blocked_reason` field on the task JSON object. To find why a task is blocked, you must inspect the `events` array:

```python
events = detail.get("events", [])
block_reason = None
for e in events:
    if e.get("kind") == "blocked":
        block_reason = e.get("reason") or e.get("message")
        break
```

System-blocked tasks (gave_up, crash, protocol violation) won't have a `kind=blocked` event at all — the block is implicit from the `gave_up` event. To check if a task is system-blocked:

```python
gave_up_count = sum(1 for e in events if e.get("kind") == "gave_up")
crash_count = sum(1 for e in events if e.get("kind") == "crashed")
protocol_count = sum(1 for e in events if e.get("kind") == "protocol_violation")
```

## Events array — event kinds

| kind | meaning |
|---|---|
| `created` | Task created |
| `promoted` | Task moved to ready/next state |
| `claimed` | Dispatcher claimed the task |
| `spawned` | Worker process spawned |
| `crashed` | Worker process crashed (non-zero exit, segfault, etc.) |
| `protocol_violation` | Worker exited cleanly (rc=0) without calling kanban_complete/kanban_block |
| `gave_up` | Failed after exhausting retries |
| `blocked` | Worker explicitly blocked the task (has `reason` field) |
| `unblocked` | Task was unblocked |
| `commented` | Comment added (check the `comments` array, not events, for comment bodies) |

## Runs array

```json
{
  "run_id": "...",
  "outcome": "crashed|timed_out|blocked|completed|spawn_failed|reclaimed",
  "summary": "...",
  "error": "...",
  "pid": 12345,
  "started_at": unix_timestamp,
  "duration_seconds": 123.4,
  "card_claimed_ids": []
}
```

The `summary` field may be `null` for timed-out or crashed runs — do not rely on it for gave_up detection.

## Parsing pitfalls

1. **Control characters in `body`**: Task body text may contain tab/newline characters that cause `json.loads()` to fail. Always use `json.loads(raw, strict=False)`.
2. **Truncated list output**: `kanban list --json` may return a very long JSON array that gets truncated in terminal output. Parse via tool return value, not screen scraping.
3. **Events vs runs**: Events are the definitive history. Runs are a summary of individual worker attempts — a single task can have multiple runs but single gave_up event if retries consumed. The `gave_up` event count from events is the authoritative failure count.
4. **Blocked != gave_up**: A task can be `status: blocked` because of:
   - Worker called `kanban_block(reason=...)` → check events for `kind=blocked`
   - System blocked after gave_up → check events for `kind=gave_up`
   - System blocked after crash → check events for `kind=crashed`
   Each requires different handling.
