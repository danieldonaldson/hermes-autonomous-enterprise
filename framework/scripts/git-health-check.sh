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
# 4. Profiles with real files where symlinks should be
# ═══════════════════════════════════════════
non_symlink=""
for profile_dir in "$PROFILES_DIR"/*/; do
  [ -d "$profile_dir" ] || continue
  name="$(basename "$profile_dir")"
  issues=""
  # Check for real files (not symlinks) where symlinks are expected
  if [ -f "$profile_dir/SOUL.md" ] && [ ! -L "$profile_dir/SOUL.md" ]; then
    issues="${issues}SOUL.md(real) "
  fi
  if [ -f "$profile_dir/config.yaml" ] && [ ! -L "$profile_dir/config.yaml" ]; then
    issues="${issues}config.yaml(real) "
  fi
  # Check for missing files entirely
  if [ ! -e "$profile_dir/SOUL.md" ]; then
    issues="${issues}SOUL.md(missing) "
  fi
  if [ ! -e "$profile_dir/config.yaml" ]; then
    issues="${issues}config.yaml(missing) "
  fi
  if [ -n "$issues" ]; then
    non_symlink="$non_symlink  $name: $issues\n"
  fi
done
if [ -n "$non_symlink" ]; then
  HAS_ISSUES=true
  section "⚠️  Profile File Issues (should be symlinks to framework)"
  echo -e "$non_symlink"
fi

# ═══════════════════════════════════════════
# 5. Product leak scan in framework repo
# ═══════════════════════════════════════════
# Uses PRODUCT_BLOCKLIST from env.sh (sourced by shunt before exec).
# Falls back to individual vars if blocklist is not set.
if [ -n "${PRODUCT_BLOCKLIST:-}" ]; then
  SEARCH_TERMS="$PRODUCT_BLOCKLIST"
elif [ -n "${COMPANY_NAME:-}${FOUNDER_NAME:-}${PRODUCT_DOMAIN:-}" ]; then
  # Fallback: construct from individual vars
  SEARCH_TERMS="${COMPANY_NAME:-} ${FOUNDER_NAME:-} ${PRODUCT_DOMAIN:-} ${TELEGRAM_CHAT_ID:-}"
  SEARCH_TERMS="$(echo "$SEARCH_TERMS" | tr ' ' '\n' | grep -v '^$' | tr '\n' '|')"
  SEARCH_TERMS="${SEARCH_TERMS%|}"
fi

if [ -n "${SEARCH_TERMS:-}" ]; then
  leaks=$(cd "$FRAMEWORK_REPO" && grep -rIn --include='*.md' --include='*.yaml' -i -E "$SEARCH_TERMS" \
    framework/roles/ framework/scripts/ skills/ \
    2>/dev/null | grep -v 'product-context.yaml' | grep -v 'context.md' || true)
  if [ -n "$leaks" ]; then
    HAS_ISSUES=true
    section "🔴 Product Leaks in Framework Repo"
    echo "$leaks"
    echo "These terms belong in the overlay, not the framework."
  fi
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
