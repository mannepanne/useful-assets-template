# Project Template for AI-Assisted Development

A battle-tested project template for working with AI coding assistants, refined over 12-18 months of LLM-assisted development.

## What This Is

This template encapsulates patterns and workflows that have consistently delivered results when building software with AI assistants like Claude Code. It's opinionated, practical, and designed to minimize friction while maximizing collaboration quality.

## Core Principles

**Lifecycle-based documentation** - Documents move through clear stages (SPECIFICATIONS → REFERENCE → ARCHIVE), keeping active context minimal and focused.

**Tests as guardrails** - Tests serve dual purposes: validation and directional context for AI. They guide what to build, not just verify it works.

**Token efficiency** - CLAUDE.md files act as "library indexes" that lazy-load context only when needed. This pattern scales to large projects.

**Collaboration framework** - Clear behavioral guidelines for working with AI (directness over politeness, evidence-based pushback, systematic decision-making).

**Systematic over ad-hoc** - Consistent patterns (PR reviews, phase structure, testing strategy) that compound over time.

## What You Get

```
.claude/                    # AI collaboration config (auto-loads)
├── COLLABORATION/          # Behavioral guidance, PM mode, tech preferences
└── skills/                 # Automated PR review workflows

SPECIFICATIONS/             # What you're building now
├── ORIGINAL_IDEA/         # Initial project vision
└── ARCHIVE/               # Completed phase specs

REFERENCE/                  # How implemented features work
├── testing-strategy.md
├── environment-setup.md
└── troubleshooting.md
```

## Getting Started

1. **Use this template** (click "Use this template" button on GitHub)
2. **Follow setup guide** - See [TEMPLATE-INSTRUCTIONS.md](./TEMPLATE-INSTRUCTIONS.md) (30-60 min)
3. **Customize for your project** - Replace placeholders with your details
4. **Start building** - Break project into phases, work systematically

## Why These Patterns Work

After 12-18 months of LLM-assisted coding, a few things became clear:

- **AI assistants are coworkers, not servants** - Best results come from treating them as collaborators with domain expertise
- **Documentation is leverage** - Good docs enable both AI and humans to pick up work quickly
- **Tests guide better than specs alone** - Especially with AI, executable specifications prevent drift
- **Simple beats clever** - Patterns that are easy to explain work better than complex optimization
- **Consistency compounds** - Using the same structure across projects builds muscle memory (yours and the AI's)

## Technology Defaults

TypeScript, Next.js, Cloudflare Workers, Supabase, Vitest - but easily customizable. See `.claude/COLLABORATION/technology-preferences.md` for rationale.

## Credits

Collaboration patterns inspired by [@obra](https://github.com/obra), [@harperreed](https://github.com/harperreed), [OpenAI's Harness Engineering](https://openai.com/index/harness-engineering/), and [steipete/agent-rules](https://github.com/steipete/agent-rules).

## License

MIT - Use freely, adapt as needed, share improvements.

---

**Ready to start?** Read [TEMPLATE-INSTRUCTIONS.md](./TEMPLATE-INSTRUCTIONS.md) for step-by-step setup.
