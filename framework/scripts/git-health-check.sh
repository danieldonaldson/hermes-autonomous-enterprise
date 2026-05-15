#!/usr/bin/env bash
# git-health-check.sh — Daily audit of enterprise repo health.
# Silent when clean (no output = nothing to report = cron skips delivery).
# Reports: uncommitted changes, unpushed commits, broken symlinks, local-only skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"

FRAMEWORK_REPO="${FRAMEWORK_REPO:-$HOME/Work/hermes-autonomous-enterprise}"
OVERLAY_REPO="${OVERLAY_REPO:-$HOME/Work/hermes-yethu-overlay}"
PROFILES_DIR="$HOME/.hermes/profiles"
SKILLS_DIR="$HOME/.hermes/skills"

HAS_ISSUES=false

# ── helper: print section header ──
section() { echo ""; echo "━━━ $1 ━━━"; }

# ═══════════════════════════════════════════
# 1. Framework repo
# ═══════════════════════════════════════════
check_repo() {
  local repo="$1" label="$2"
  cd "$repo" 2>/dev/null || { echo "⚠️  $label: repo not found at $repo"; HAS_ISSUES=true; return; }

  local issues=false

  # Uncommitted changes (modified + staged)
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    issues=true
  fi

  # Untracked files (excluding .gitignore'd)
  if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    issues=true
  fi

  # Unpushed commits
  local ahead
  ahead=$(git rev-list --count origin/HEAD..HEAD 2>/dev/null || echo 0)
  if [ "$ahead" -gt 0 ] 2>/dev/null; then
    issues=true
  fi

  if $issues; then
    HAS_ISSUES=true
    section "$label — $(basename "$repo")"
    git -C "$repo" status --short 2>/dev/null
    if [ "${ahead:-0}" -gt 0 ] 2>/dev/null; then
      echo "📤 $ahead unpushed commit(s)"
    fi
  fi
}

check_repo "$FRAMEWORK_REPO" "🔓 Open Source"
check_repo "$OVERLAY_REPO"     "🔒 Private Overlay"

# ═══════════════════════════════════════════
# 2. Broken symlinks in profiles
# ═══════════════════════════════════════════
broken=$(find "$PROFILES_DIR" -xtype l 2>/dev/null || true)
if [ -n "$broken" ]; then
  HAS_ISSUES=true
  section "🔗 Broken Symlinks in Profiles"
  find "$PROFILES_DIR" -xtype l -ls 2>/dev/null
fi

# ═══════════════════════════════════════════
# 3. Enterprise skills only in ~/.hermes/skills/ (not in framework)
# ═══════════════════════════════════════════
FRAMEWORK_SKILLS="$FRAMEWORK_REPO/skills"
if [ -d "$FRAMEWORK_SKILLS" ] && [ -d "$SKILLS_DIR" ]; then
  local_only=""
  for cat in autonomous-ai-agents devops; do
    if [ -d "$SKILLS_DIR/$cat" ]; then
      for skill_dir in "$SKILLS_DIR/$cat"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        if [ ! -d "$FRAMEWORK_SKILLS/$cat/$skill_name" ]; then
          local_only="$local_only  $cat/$skill_name\n"
        fi
      done
    fi
  done
  if [ -n "$local_only" ]; then
    HAS_ISSUES=true
    section "📦 Local-Only Enterprise Skills (not in framework repo)"
    echo -e "$local_only"
    echo "These should be moved to $FRAMEWORK_SKILLS/"
  fi
fi

# ═══════════════════════════════════════════
# 4. Profiles missing SOUL.md or config.yaml symlinks
# ═══════════════════════════════════════════
missing=""
for profile_dir in "$PROFILES_DIR"/*/; do
  [ -d "$profile_dir" ] || continue
  name="$(basename "$profile_dir")"
  issues=""
  if [ ! -e "$profile_dir/SOUL.md" ]; then
    issues="${issues}SOUL.md "
  fi
  if [ ! -e "$profile_dir/config.yaml" ]; then
    issues="${issues}config.yaml "
  fi
  if [ -n "$issues" ]; then
    missing="$missing  $name: missing $issues\n"
  fi
done
if [ -n "$missing" ]; then
  HAS_ISSUES=true
  section "⚠️  Profiles Missing Key Files"
  echo -e "$missing"
fi

# ═══════════════════════════════════════════
# Result
# ═══════════════════════════════════════════
if $HAS_ISSUES; then
  echo ""
  echo "── Run 'hermes' and ask to fix these issues. ──"
else
  # Silent = no issues. Cron won't deliver.
  :
fi
