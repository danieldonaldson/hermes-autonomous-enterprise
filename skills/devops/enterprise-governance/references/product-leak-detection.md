# Product Leak Detection — Technical Notes

## grep -E compatibility: `\d` does NOT work

**Critical pitfall:** `grep -E` (extended regex) does NOT support PCRE shorthand classes like `\d` for digits. In `grep -E`, `\d` matches a literal backslash-d or just literal 'd' depending on the shell quoting. This causes massive false positives — `R\d+` matches ANY word containing "Rd" (onboa**Rd**ing, coo**Rd**ination).

**Fix:** Use `[0-9]` instead:
```bash
# WRONG — matches "onboarding", "coordination", etc.
grep -rIn -E "R\d+" framework/

# RIGHT — only matches R followed by digits
grep -rIn -E "R[0-9]+" framework/
```

## PRODUCT_BLOCKLIST format

In `env.sh`, define as pipe-separated grep -E patterns:

```bash
export PRODUCT_BLOCKLIST="CompanyName|domain\.com|FounderName|PaymentProvider|R[0-9]+[0-9]*[kKmM]|\\$0\.0226|market-specific-term"
```

**Escaping rules for bash strings:**
- `.` → `\.` (match literal dot, not any char)
- `$` → `\\$` (double-escape: bash consumes one, grep gets `\$`)
- `[0-9]` → works as-is in grep -E
- Spaces in terms are fine (e.g. `SA teacher` matches the exact phrase)

**What to include (unique identifiers):**
- Company name, domain, founder name
- Payment provider names (Paystack, Stripe)
- Currency amounts with specific values (R[0-9]+, $0.0226)
- Market-specific jargon that uniquely identifies the product
- Overlay repo name if it contains the company name

**What NOT to include (too broad → false positives):**
- Generic platform names appearing in docs (WhatsApp, Discord — hermes-agent lists supported platforms)
- Timezone abbreviations used by many setups (SAST, UTC, EST)
- Generic business terms (bulk licensing, onboarding)
- Acronyms that appear in common words (CAPS → matches "CAPSlock")

## The leak scan in git-health-check.sh

The scan uses `grep -rIn -i -E "$SEARCH_TERMS"` across `framework/roles/`, `framework/scripts/`, and `skills/`. The `-i` flag makes it case-insensitive. Lines referencing `product-context.yaml` or `context.md` are excluded (these are pointers to overlay files, not leaks).

## Testing the blocklist

```bash
# Source the blocklist
source ~/Work/hermes-yethu-overlay/scripts/env.sh

# Test with a deliberate leak
echo "# test leak: Yethu marketplace" > /tmp/test_leak.md
cd ~/Work/hermes-autonomous-enterprise
grep -rIn -i -E "$PRODUCT_BLOCKLIST" /tmp/test_leak.md
# Should match

# Verify no false positives in framework
grep -rIn -i -E "$PRODUCT_BLOCKLIST" framework/roles/ framework/scripts/ skills/ \
  | grep -v 'product-context.yaml' | grep -v 'context.md'
# Should be empty (or only show intentional meta-references in audit docs)
```
