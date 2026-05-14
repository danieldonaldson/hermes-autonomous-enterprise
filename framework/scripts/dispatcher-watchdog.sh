#!/usr/bin/env bash
set -euo pipefail

# Dispatcher Heartbeat Watchdog
# Checks if the hermes gateway dispatcher is alive and running.
# Fails silently (no output) when healthy — only reports when something's wrong.
# Scheduled: every 30 minutes

KANBAN_ROOT="${HOME}/.hermes/kanban"

# 1. Check gateway service is running
if ! systemctl --user is-active --quiet hermes-gateway.service 2>/dev/null; then
  echo "🚨 [DISPATCHER WATCHDOG] Gateway service is NOT running!"
  systemctl --user status hermes-gateway.service 2>&1 | head -10
  exit 1
fi

# 2. Check last dispatch activity by looking at the most recent task event
# Dispatch events logged in state.db show as 'claimed' or 'spawned' events
# We check via kanban stats for oldest_ready_age
LAST_CHECK=$(hermes kanban stats --json 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "⚠️ [DISPATCHER WATCHDOG] Cannot query kanban stats — dispatcher may be stalled"
  exit 1
fi

# 3. Check for any tasks that have been ready too long (stale dispatch)
OLDEST_READY=$(echo "$LAST_CHECK" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('oldest_ready_age_seconds') or 'null')" 2>/dev/null)
if [ "$OLDEST_READY" != "null" ] && [ "$OLDEST_READY" -gt 600 ] 2>/dev/null; then
  echo "⚠️ [DISPATCHER WATCHDOG] Task has been ready for ${OLDEST_READY}s without being claimed (>10min threshold)"
  echo "$LAST_CHECK" | python3 -c "import sys,json; d=json.load(sys.stdin); print('by_status:', d.get('by_status'), 'by_assignee:', json.dumps(d.get('by_assignee',{}), indent=2))" 2>/dev/null
  exit 1
fi

# Healthy — silent exit (watchdog pattern: no news is good news)
exit 0
