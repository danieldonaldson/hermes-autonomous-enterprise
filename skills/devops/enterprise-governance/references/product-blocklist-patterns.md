# Product Blocklist Patterns for git-health-check

## The grep -E pitfall (CRITICAL)

The git-health-check uses `grep -E` (extended regex), NOT `grep -P` (Perl regex). This matters:

| Pattern | grep -E behavior | grep -P behavior |
|---------|-----------------|-----------------|
| `\\d` | Matches literal `d` (escaped 'd' = 'd' in ERE) | Matches digit [0-9] |
| `\\w` | Matches literal `w` | Matches word char |
| `\\s` | Matches literal `s` | Matches whitespace |

**The `$\\d+` disaster (real session, May 2026):** A blocklist containing `$\\d+` was deployed. `grep -E` interpreted `\\d` as literal 'd', so `$\\d+` matched "$" followed by one or more 'd's — which matched every occurrence of "$d" in shell scripts and config files, returning thousands of false positives.

**Fix:** Use `[0-9]` for digits in grep -E patterns:
- `$\\d+` → `$[0-9]+`  ($ followed by digits)
- `\\d{4}` → `[0-9]{4}` (exactly 4 digits)

## Blocklist construction rules

1. **Use grep -E compatible syntax** — character classes (`[0-9]`, `[A-Z]`), not PCRE shortcuts
2. **Escape special chars** — `.` → `\\.`, `$` → `\\$` (double-escape in bash: `\\\\$`)
3. **Pipe-separated** — terms joined with `|`
4. **Case-insensitive** — the scan uses `grep -i`, so don't worry about casing
5. **Test with a fake leak** — create a file with a known term, run the scan, verify it's caught
6. **Trim aggressively** — remove terms that cause false positives. It's better to miss a borderline term than to cry wolf daily

## Good patterns (specific, low false-positive rate)

```
AcmeCorp                                    # company name (unique)
acme-corp-overlay                           # overlay repo name (unique)
John                                        # founder name (common name, but specific in context)
1234567890                                  # chat ID (unique numeric)
Stripe                                      # payment provider (unique)
$[0-9]+[0-9]*[kKmM]                        # currency amounts: $150, $1M, $20K
\\$0\\.0226                              # specific dollar amount
```

## Bad patterns (removed — too many false positives)

```
$\\d+              # matches every word with "$d" (overly broad in code/config files)
standards          # too short, matches "standards" in many contexts
messaging          # appears in hermes-agent platform listing (generic)
discord            # in every config.yaml disabled_toolsets
SAST               # timezone used by many non-AcmeCorp setups
bulk licensing     # generic business term
```

## Testing the blocklist

Always test before deploying:

```bash
# 1. Source the blocklist
source ~/Work/acme-corp-overlay/scripts/env.sh

# 2. Create a fake leak
echo "# test: AcmeCorp platform" > /tmp/test_leak.md
cp /tmp/test_leak.md ~/Work/hermes-autonomous-enterprise/framework/roles/TEST_LEAK.md

# 3. Run the scan
bash ~/.hermes/scripts/git-health-check.sh

# 4. Verify the leak was caught under "🔴 Product Leaks"
# 5. Clean up
rm ~/Work/hermes-autonomous-enterprise/framework/roles/TEST_LEAK.md
```

## The env.sh PRODUCT_BLOCKLIST variable

Located at: `product-overlay/scripts/env.sh`

Format:
```bash
export PRODUCT_BLOCKLIST="term1|term2\\.com|term3|$[0-9]+|specific-phrase"
```

The git-health-check script checks for `PRODUCT_BLOCKLIST` first. If not set, it falls back to individual vars (`COMPANY_NAME`, `FOUNDER_NAME`, `PRODUCT_DOMAIN`, `TELEGRAM_CHAT_ID`).

When adding new product-specific terms to the framework audit passes or to agent prompts, add them to the blocklist FIRST so the automated scan catches leaks in real time.
