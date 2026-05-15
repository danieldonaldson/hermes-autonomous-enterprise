#!/usr/bin/env python3
"""
scan-blocked-tasks.py — Review Router & board health scan script

Scans blocked kanban tasks, classifies each by block reason, and outputs
structured JSON for routing decisions and reporting. Can be used as the
engine for a review-router cron job, a PMO board health scan, or a
CoS gave_up detection sweep.

Usage:
  # Scan all blocked tasks
  python3 scan-blocked-tasks.py

  # Scan specific tasks by ID
  python3 scan-blocked-tasks.py t_abc123 t_def456 ...

  # Output as CSV (for spreadsheets)
  python3 scan-blocked-tasks.py --format csv

  # Only show routable tasks (review-required: / help-needed:)
  python3 scan-blocked-tasks.py --routable-only

  # High-level summary only
  python3 scan-blocked-tasks.py --summary-only

Output (JSON default):
  {
    "board_summary": {
      "total_blocked": 72,
      "gave_up": 65,
      "crashed": 15,
      "with_block_reason": 3,
      "with_protocol_violation": 70
    },
    "routable": [
      {"task_id": "t_xxx", "assignee": "engineer",
       "block_reason": "review-required: rate limiter shipped, 14/14 tests pass",
       "action": "kanban_assign + kanban_unblock to tech-lead"}
    ],
    "gave_up": [
      {"task_id": "t_yyy", "assignee": "community-manager",
       "gave_up_count": 1, "crashed_count": 0, "protocol_violations": 1,
       "recommendation": "monitor (gave_up=1)"}
    ],
    "no_action": [
      {"task_id": "t_zzz", "assignee": "tech-lead",
       "block_reason": "review-required: ...",
       "reason": "already assigned to tech-lead"}
    ]
  }

Environment:
  HERMES_HOME — overrides ~/.hermes default
  KANBAN_CLI  — overrides default path to `hermes` binary
"""

import json
import os
import subprocess
import sys
from collections import Counter

# --- Config ---
HERMES_HOME = os.environ.get("HERMES_HOME", os.path.expanduser("~/.hermes"))
KANBAN_CLI = os.environ.get("KANBAN_CLI", "hermes")
KANBAN_DIR = os.path.join(HERMES_HOME, "kanban")

ROUTING_PREFIXES = ("review-required:", "help-needed:")
ROUTE_TO_PROFILE = "tech-lead"

# --- Helpers ---

def run(cmd: list[str], timeout: int = 30) -> str:
    """Run a command and return stdout. Raises on non-zero exit."""
    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=timeout
    )
    if result.returncode != 0:
        print(f"WARN: command {' '.join(cmd)} failed: {result.stderr.strip()}", file=sys.stderr)
        return ""
    return result.stdout


def get_all_blocked_task_ids() -> list[str]:
    """Parse 'hermes kanban list --status blocked' to extract task IDs."""
    output = run([KANBAN_CLI, "kanban", "list", "--status", "blocked"], timeout=30)
    task_ids = []
    for line in output.strip().split("\n"):
        parts = line.strip().split()
        if len(parts) >= 2:
            task_ids.append(parts[1])
    return task_ids


def inspect_task(task_id: str) -> dict:
    """Fetch full task JSON and extract classification fields."""
    raw = run([KANBAN_CLI, "kanban", "show", task_id, "--json"], timeout=15)
    if not raw:
        return {"task_id": task_id, "error": f"empty response from kanban show {task_id}"}

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        return {"task_id": task_id, "error": f"JSON parse error: {e}"}

    task = data.get("task", data)  # some versions nest under "task"
    events = data.get("events", [])

    result = {
        "task_id": task_id,
        "assignee": task.get("assignee", ""),
        "status": task.get("status", "unknown"),
        "block_reason": task.get("block_reason", ""),
        "gave_up_count": 0,
        "crashed_count": 0,
        "protocol_violations": 0,
        "worker_blocked": False,
        "error": None,
    }

    # Count event kinds
    for e in events:
        kind = e.get("kind", "")
        if kind == "gave_up":
            result["gave_up_count"] += 1
        elif kind == "crashed":
            result["crashed_count"] += 1
        elif kind == "protocol_violation":
            result["protocol_violations"] += 1
        elif kind == "blocked":
            result["worker_blocked"] = True
            # Capture block reason from event if task.block_reason was empty
            if not result["block_reason"]:
                result["block_reason"] = e.get("payload", {}).get("reason", "")

    return result


def classify(task: dict) -> str:
    """Return classification label: routable, gave_up, no_action"""
    if task.get("error"):
        return "error"

    # Gave up / crashed tasks should NOT be routed per kanban-worker rules
    if task["gave_up_count"] > 0 or task["crashed_count"] > 0:
        return "gave_up"

    # Check for routable block reasons
    if task["block_reason"]:
        for prefix in ROUTING_PREFIXES:
            if task["block_reason"].startswith(prefix):
                return "routable"

    return "no_action"


def format_csv(tasks: dict, fields: list[str]) -> str:
    """Render classified tasks as CSV."""
    lines = [",".join(fields)]
    for label, items in tasks.items():
        for item in items:
            row = [str(item.get(f, "")) for f in fields]
            lines.append(",".join(row))
    return "\n".join(lines)


# --- Main ---

def main():
    args = sys.argv[1:]
    format_flag = "json"
    routable_only = False
    summary_only = False
    explicit_tids = []

    i = 0
    while i < len(args):
        if args[i] == "--format" and i + 1 < len(args):
            format_flag = args[i + 1]
            i += 2
        elif args[i] == "--routable-only":
            routable_only = True
            i += 1
        elif args[i] == "--summary-only":
            summary_only = True
            i += 1
        elif args[i].startswith("t_"):
            explicit_tids.append(args[i])
            i += 1
        else:
            i += 1

    # Get task IDs
    task_ids = explicit_tids if explicit_tids else get_all_blocked_task_ids()

    if not task_ids:
        print("No blocked tasks found." if format_flag == "json" else "task_id,status,message\n,no_data,no blocked tasks found")
        return

    # Inspect all tasks
    results = [inspect_task(tid) for tid in task_ids]

    # Classify
    classified: dict[str, list] = {
        "routable": [],
        "gave_up": [],
        "no_action": [],
        "error": [],
    }
    for t in results:
        label = classify(t)
        classified[label].append(t)

    # Build summary
    board_summary = {
        "total_blocked": len(task_ids),
        "scanned": len(results),
        "gave_up": sum(1 for t in results if t["gave_up_count"] > 0 or t["crashed_count"] > 0),
        "crashed": sum(1 for t in results if t["crashed_count"] > 0),
        "with_block_reason": sum(1 for t in results if t["block_reason"]),
        "with_protocol_violation": sum(1 for t in results if t["protocol_violations"] > 0),
        "routable_count": len(classified["routable"]),
    }

    # Add routing recommendations for routable tasks
    for t in classified["routable"]:
        route = None
        if t["assignee"] != ROUTE_TO_PROFILE:
            route = f"kanban_assign({t['task_id']}, '{ROUTE_TO_PROFILE}') + kanban_unblock({t['task_id']})"
        else:
            route = f"already assigned to {ROUTE_TO_PROFILE} — skip"
        t["action"] = route

    # Add triage recommendation for gave_up tasks
    for t in classified["gave_up"]:
        g = t["gave_up_count"]
        if g >= 3:
            t["recommendation"] = f"ESCALATE — gave_up={g}x, create escalation task for founder"
        elif g == 2:
            t["recommendation"] = f"YELLOW — gave_up={g}x, diagnose root cause, create escalation if chronic"
        else:
            t["recommendation"] = f"monitor (gave_up={g})"

    # Output
    output = {
        "board_summary": board_summary,
        "routable": classified["routable"],
        "gave_up": classified["gave_up"],
        "no_action": classified["no_action"],
        "errors": classified["error"],
    }

    if routable_only:
        output = {"routable": classified["routable"]}
    elif summary_only:
        output = {"board_summary": board_summary}

    if format_flag == "csv":
        fields = ["task_id", "assignee", "status", "block_reason",
                   "gave_up_count", "crashed_count", "protocol_violations",
                   "classification"]
        # Build a flat list with classification labels
        flat = []
        for label, items in classified.items():
            for item in items:
                item["classification"] = label
                flat.append(item)
        print(format_csv({"tasks": flat}, fields))
    else:
        print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
