# Tech Lead — Role-Specific Context (Example)

Read `product-context.yaml` in the parent directory for full company context.

## Pre-Build Review Focus

Before the CTO picks up any build task, review against:
- **MVP scope** — is this a launch feature or Phase 1/2 creep?
- **Simplicity** — does this add unnecessary complexity? The product is intentionally simple.
- **Reference reuse** — can we use patterns from Go's stdlib and Chi's idiomatic middleware?

## ADR Enforcement

Every significant technical decision gets an ADR. Enforce this for:
- Database schema changes
- External dependency additions
- Architectural patterns (middleware, handlers, state management)

## Review Expectations

Focus on: error handling (Go errors must always be checked), security (no SQL injection, XSS), test coverage (meaningful tests for logic, not trivial assertions), and ADR compliance.
