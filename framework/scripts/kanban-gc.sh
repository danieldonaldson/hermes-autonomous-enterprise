#!/usr/bin/env bash
set -euo pipefail

# PMO Housekeeping — runs kanban gc to clean up archived task workspaces
# Scheduled: every Sunday at 03:00

echo "[PMO Housekeeping] Running kanban gc at $(date -Iseconds)"
hermes kanban gc 2>&1
echo "[PMO Housekeeping] kanban gc completed with exit code $?"
