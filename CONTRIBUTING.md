# Contributing to Hermes Autonomous Enterprise Framework

Thank you for considering contributing! This framework is open source and we welcome improvements.

## How to Contribute

1. **Fork the repo** and create a feature branch from `main`
2. **Make your changes** — keep them focused on one thing per PR
3. **Test locally** — run `./bootstrap.sh` with the example overlay to verify your changes work
4. **Submit a PR** with a clear description of what and why

## Guidelines

- **Role SOUL.md files** should be product-agnostic. Product-specific context belongs in the overlay, not the framework.
- **Config changes** — keep profile configs minimal. Add only the toolsets that should be disabled for that role.
- **Documentation** — update README.md if you add new roles or change the setup flow.
- **Backward compatibility** — the bootstrap.sh script must work without changes. New features should be opt-in.

## Questions?

Open an issue for discussion before starting significant work.
