#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — Set up Hermes Autonomous Enterprise on a new machine
#
# Usage:
#   ./bootstrap.sh /path/to/product-overlay
#
# Where product-overlay/ contains:
#   product-context.yaml     — Shared company/product info
#   roles/<name>/context.md  — Per-role context (optional)
#   scripts/                 — Custom scripts (optional)
#   cron/jobs.json           — Cron job definitions (optional)
#
# This script creates symlinks from ~/.hermes/ into this repo and
# the overlay directory. Runtime state (sessions, logs, databases)
# stays in ~/.hermes/ — only config files are symlinked.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_DIR="${1:-}"

if [ -z "$OVERLAY_DIR" ]; then
  echo "Usage: $0 /path/to/product-overlay"
  echo ""
  echo "Your overlay should contain:"
  echo "  product-context.yaml     — required"
  echo "  roles/<name>/context.md  — optional per-role context"
  echo "  scripts/                 — optional custom scripts"
  echo "  cron/jobs.json           — optional cron definitions"
  exit 1
fi

if [ ! -f "$OVERLAY_DIR/product-context.yaml" ]; then
  echo "Error: $OVERLAY_DIR/product-context.yaml not found"
  exit 1
fi

# Check for unfilled placeholder values
PLACEHOLDERS=$(grep -n "YOUR_\|PLACEHOLDER\|FIXME\|TODO\|example\.com" "$OVERLAY_DIR/product-context.yaml" 2>/dev/null || true)
if [ -n "$PLACEHOLDERS" ]; then
  echo "Warning: product-context.yaml may still contain placeholder values:"
  echo "$PLACEHOLDERS" | sed 's/^/  /'
  echo "Continue anyway? [y/N] "
  read -r answer
  [ "${answer:-N}" = "y" ] || [ "${answer:-N}" = "Y" ] || exit 1
fi

OVERLAY_DIR="$(cd "$OVERLAY_DIR" && pwd)"
FRAMEWORK_DIR="$REPO_DIR/framework"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

echo "=== Hermes Autonomous Enterprise Bootstrap ==="
echo "Repo:     $REPO_DIR"
echo "Overlay:  $OVERLAY_DIR"
echo "Hermes:   $HERMES_HOME"
echo ""

# 1. Check Hermes is installed
if ! command -v hermes &>/dev/null; then
  echo "[1/5] Installing Hermes Agent..."
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
else
  echo "[1/5] Hermes Agent found: $(hermes --version 2>/dev/null || echo 'installed')"
fi

# 2. Stop gateway while we rewire
echo "[2/5] Stopping gateway..."
hermes gateway stop 2>/dev/null || true

# 3. Link all role profiles
echo "[3/5] Linking role profiles..."
for role_dir in "$FRAMEWORK_DIR/roles/"*/; do
  role="$(basename "$role_dir")"
  profile_dir="$HERMES_HOME/profiles/$role"
  mkdir -p "$profile_dir"
  
  # Symlink SOUL.md
  if [ -f "$role_dir/SOUL.md" ]; then
    ln -sf "$role_dir/SOUL.md" "$profile_dir/SOUL.md"
    echo "  ✓ $role/SOUL.md"
  fi
  
  # Symlink config.yaml
  if [ -f "$role_dir/config.yaml" ]; then
    ln -sf "$role_dir/config.yaml" "$profile_dir/config.yaml"
    echo "  ✓ $role/config.yaml"
  fi
  
  # Symlink shared product-context.yaml
  ln -sf "$OVERLAY_DIR/product-context.yaml" "$profile_dir/product-context.yaml"
  echo "  ✓ $role/product-context.yaml"
  
  # Symlink per-role context if it exists
  if [ -f "$OVERLAY_DIR/roles/$role/context.md" ]; then
    ln -sf "$OVERLAY_DIR/roles/$role/context.md" "$profile_dir/context.md"
    echo "  ✓ $role/context.md"
  fi
done

# 4. Link scripts (framework first, overlay second so it can override)
echo "[4/5] Linking scripts..."
mkdir -p "$HERMES_HOME/scripts"
for script in "$FRAMEWORK_DIR/scripts/"*; do
  if [ -f "$script" ]; then
    name="$(basename "$script")"
    ln -sf "$script" "$HERMES_HOME/scripts/$name"
    echo "  ✓ scripts/$name (framework)"
  fi
done
if [ -d "$OVERLAY_DIR/scripts" ]; then
  for script in "$OVERLAY_DIR/scripts/"*; do
    if [ -f "$script" ]; then
      name="$(basename "$script")"
      ln -sf "$script" "$HERMES_HOME/scripts/$name"
      echo "  ✓ scripts/$name (overlay)"
    fi
  done
fi

# 5. Restart gateway
echo "[5/5] Restarting gateway..."
if hermes gateway start 2>/dev/null; then
  echo "  ✓ Gateway started"
else
  echo "  ⚠ Gateway could not start — check ~/.hermes/.env has your tokens"
fi

echo ""
echo "=== Bootstrap complete ==="
echo "Your autonomous enterprise profiles are ready."
echo "Start a session: hermes --profile ceo"
echo ""
echo "To pull structural updates later:"
echo "  cd $REPO_DIR && git pull"
echo "  # Symlinks update automatically"
