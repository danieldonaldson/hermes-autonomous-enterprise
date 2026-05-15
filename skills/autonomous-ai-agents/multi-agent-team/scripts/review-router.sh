#!/usr/bin/env bash
# review-router.sh — Route "review-required" blocked tasks to Tech Lead
#
# Scans the kanban board for tasks blocked by engineers with "review-required",
# re-assigns them to tech-lead, and unblocks them so the 60s dispatcher picks them up.
#
# Intended to run as a no_agent cron job (every 5 min):
#   hermes cron create "Review Router" \
#     --schedule "*/5 * * * *" \
#     --script review-router.sh \
#     --deliver local
#
# Works with hermes kanban list --json and hermes kanban show --json.
# Uses python3 for reliable JSON parsing (available on both Linux and macOS).

set -euo pipefail

blocked_json=$(hermes kanban list --status blocked --json 2>/dev/null) || {
  echo "[review-router] No blocked tasks found or kanban not accessible"
  exit 0
}

task_ids=$(echo "$blocked_json" | python3 -c "
import json, sys
tasks = json.load(sys.stdin)
for t in tasks:
    print(t.get('id', ''))
" 2>/dev/null) || {
  echo "[review-router] No blocked tasks to process"
  exit 0
}

if [ -z "$task_ids" ]; then
  echo "[review-router] No blocked tasks"
  exit 0
fi

routed=0

for task_id in $task_ids; do
  # Get task details including latest_summary for block reason
  detail_json=$(hermes kanban show "$task_id" --json 2>/dev/null) || continue

  # Check if block reason starts with "review-required"
  reason=$(echo "$detail_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
summary = data.get('latest_summary', '')
print(summary[:80])
" 2>/dev/null) || continue

  if echo "$reason" | grep -iq "^review-required"; then
    assignee=$(echo "$detail_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('task', {}).get('assignee', 'unknown'))
" 2>/dev/null)

    # Only route if currently assigned to someone other than tech-lead
    if [ "$assignee" != "tech-lead" ]; then
      echo "[review-router] Routing $task_id to tech-lead (block reason: $reason)"
      hermes kanban assign "$task_id" tech-lead 2>/dev/null || true
      hermes kanban unblock "$task_id" 2>/dev/null || true
      routed=$((routed + 1))
    else
      echo "[review-router] $task_id already assigned to tech-lead, skipping"
    fi
  fi
done

echo "[review-router] Routed $routed task(s) to tech-lead for review"
