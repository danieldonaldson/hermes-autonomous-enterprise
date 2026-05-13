#!/usr/bin/env bash
# Check if a domain is available for registration
# Runs daily until the domain drops from pendingDelete
#
# Set PRODUCT_DOMAIN in your overlay's env.sh or as an env var
#
# Requires: whois (available by default on macOS, install via apt/brew on Linux)
#
# Note: whois output format varies by registrar and TLD. The grep patterns below
# work for most generic TLDs (.com, .net, .org) but may not work for .io, .co,
# country-code TLDs, or registrars with non-standard output. Verify manually if
# the result looks wrong.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/env.sh" ] && source "$SCRIPT_DIR/env.sh"

DOMAIN="${PRODUCT_DOMAIN:?PRODUCT_DOMAIN not set — set in env.sh or export it}"
RESULT=$(whois "$DOMAIN" 2>/dev/null | grep -i "pendingDelete")

if [ -z "$RESULT" ]; then
    AVAIL=$(whois "$DOMAIN" 2>/dev/null | grep -iE "(available|no match|not found)")
    if [ -n "$AVAIL" ]; then
        echo "🎉 $DOMAIN is AVAILABLE for registration! Register it now!"
    else
        echo "⚠️  $DOMAIN status changed. Check manually: whois $DOMAIN"
    fi
else
    echo "⏳ $DOMAIN still in pendingDelete. Check again tomorrow."
    echo "    Last seen: $(date)"
fi
