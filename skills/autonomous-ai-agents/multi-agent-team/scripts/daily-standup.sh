#!/bin/bash
# Daily standup script — reads kanban board and formats Telegram summary
# Runs as no_agent cron job, stdout is delivered verbatim
# Usage: bash ~/.hermes/skills/devops/multi-agent-team/scripts/daily-standup.sh

BOARD=$(hermes kanban list 2>&1)

# Count states
BLOCKED=$(echo "$BOARD" | grep -c '⊘')
RUNNING=$(echo "$BOARD" | grep -c '●')
DONE=$(echo "$BOARD" | grep -c '✓')
TOTAL=$(echo "$BOARD" | grep -c 't_')

# Details
BLOCKED_DETAILS=$(echo "$BOARD" | grep '⊘' | sed 's/.*⊘/⊘/')
RUNNING_DETAILS=$(echo "$BOARD" | grep '●' | sed 's/.*●/●/')
READY_DETAILS=$(echo "$BOARD" | grep '▶' | sed 's/.*▶/▶/')

cat << EOF
📋 Daily Standup

━━━ Status ━━━━━━━━━━━━━━
Running:     $RUNNING
Ready:       $(echo "$BOARD" | grep -c '▶')
Blocked:     $BLOCKED
Completed:   $DONE
Total tasks: $TOTAL

$(if [ -n "$BLOCKED_DETAILS" ]; then echo "━━━ Blocked ━━━━━━━━━━━"; echo "$BLOCKED_DETAILS"; echo ""; fi)
$(if [ -n "$RUNNING_DETAILS" ]; then echo "━━━ In Progress ━━━━━━"; echo "$RUNNING_DETAILS"; echo ""; fi)
$(if [ -n "$READY_DETAILS" ]; then echo "━━━ Ready ━━━━━━━━━━━━"; echo "$READY_DETAILS"; echo ""; fi)

🕐 $(date '+%Y-%m-%d %H:%M')
EOF
