# Marketplace Cold-Start: Content Seeding via Free Open-Licensed Resources

## Problem

A new marketplace needs content to attract either side of the marketplace (buyers or sellers). Without content, there's nothing to browse. Without browsers, sellers have no reason to list. Classic chicken-and-egg.

## Solution

Seed the platform with free, open-licensed content from existing sources. This gives buyers something to search and download on Day 1, proving the platform works. The seed content also serves as a demonstration for potential sellers — "you could list your own resources here too."

## Source Types

| Source | License | Attribution Required | Best For |
|--------|---------|---------------------|----------|
| Government education portals | Public domain | Yes (source attribution) | Lesson plans, worksheets, past exam papers |
| CC BY / CC BY-SA textbooks | CC BY 3.0+ | Yes (source + license) | Textbook chapters, reference content |
| NGO/open education projects | Varies (check per-source) | Yes | Workbooks, activities, guides |
| Creator outreach | None (negotiated) | Per agreement | Unique/niche content |

## Cost Validation

**CRITICAL: Do NOT apply paid-transaction costs to free content.** Free resources downloaded within the 24-hour WhatsApp session window cost R0 in WhatsApp fees. The paid cost model (Paystack fees, watermarking, multi-step notifications) does not apply. Real costs are:
- Storage (negligible)
- One-time pipeline build effort
- Attribution compliance (documentation time)

## Implementation Pattern

1. **Research** — Find sources with clear, permissive licenses. Verify license terms on the actual source site.
2. **Pipeline** — Build a bulk-import script that downloads, formats, and uploads resources as R0 listings
3. **Attribution** — Each listing includes: "Source: [Name] ([License]). View original at [URL]"
4. **Launch** — Let teachers browse, search, and download freely
5. **Measure** — Track which resources get browsed/downloaded most to understand demand signals

## Real-World Example

For a SA teacher marketplace: Siyavula textbooks (CC BY 3.0, 12 textbooks, ~600-1,000 chapter listings) + DBE past exam papers (public domain, 200-500 papers) + WCED ePortal lesson plans (government portal). Combined seed of 1,500-2,000 free listings for ~R0 in WhatsApp fees.
