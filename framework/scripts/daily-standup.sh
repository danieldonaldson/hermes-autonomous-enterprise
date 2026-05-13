#!/usr/bin/env bash
# Daily standup script — reads kanban board and formats summary
# Runs as no_agent cron job, stdout is delivered verbatim
#
# Set COMPANY_NAME in your overlay's env.sh or as an env var

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"

COMPANY="${COMPANY_NAME:-Your Company}"

BOARD=$(hermes kanban list 2>&1)

BLOCKED=$(echo "$BOARD" | grep -c '⊘')
RUNNING=$(echo "$BOARD" | grep -c '●')
READY=$(echo "$BOARD" | grep -c '⚑\|ready')
DONE=$(echo "$BOARD" | grep -c '✓')
TODO=$(echo "$BOARD" | grep -c '○\|todo')

TOTAL=$(echo "$BOARD" | grep -c 't_')

cat << EOF
📋 $COMPANY Daily Standup

Active tasks: $RUNNING
Ready to claim: $READY
Blocked: $BLOCKED
Completed since last standup: $(hermes kanban list 2>&1 | grep '✓' | wc -l)
Tasks on board: $TOTAL

$(if [ "$BLOCKED" -gt 0 ]; then echo "🚫 Blocked tasks:"; echo "$BOARD" | grep '⊘' | sed 's/.*⊘/⊘/'; echo ""; fi)
$(if [ "$RUNNING" -gt 0 ]; then echo "🔄 Running:"; echo "$BOARD" | grep '●' | sed 's/.*●/●/'; echo ""; fi)
$(if [ "$READY" -gt 0 ]; then echo "⏳ Ready to claim:"; echo "$BOARD" | grep '⚑\|ready' | head -5 | sed 's/.*ready/ready/'; echo ""; fi)

$(echo "$BOARD" | grep -E 't_' | head -1 | grep -q . && echo "🕐 Board updated: $(date '+%H:%M')")
EOF
