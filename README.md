# Project Template for AI-Assisted Development

A comprehensive, opinionated project template designed for seamless collaboration between humans and AI coding assistants (specifically optimized for Claude Code).

## What This Template Provides

This template gives you a complete foundation for starting new software projects with:

- **Collaboration framework** - Clear principles for working with AI coding assistants
- **Documentation lifecycle** - Organized approach to specifications, implementation, and reference docs
- **Testing philosophy** - Tests as both validation and AI development guardrails
- **PR review workflows** - Skills for automated code review
- **Project organization** - Proven folder structure that minimizes token usage

## Who This Is For

- **Solo developers** working with AI coding assistants like Claude Code
- **Small teams** who want standardized collaboration patterns
- **Anyone** starting new TypeScript/JavaScript projects (though patterns apply broadly)

## Quick Start

### Using This as a GitHub Template

1. **Create a new repository** from this template:
   - Click "Use this template" button on GitHub
   - Name your new project
   - Clone to your local machine

2. **Follow the setup guide**:
   - Read [TEMPLATE-INSTRUCTIONS.md](./TEMPLATE-INSTRUCTIONS.md) for step-by-step customization
   - Customize files marked with ⚠️ **TEMPLATE** warnings
   - Set up your project-specific details

3. **Start building**:
   - Create your initial project specification
   - Break down into implementation phases
   - Work through phases with AI assistance

### Manual Setup

If not using GitHub templates:

```bash
# Clone this repository
git clone https://github.com/[your-username]/useful-assets-template.git my-new-project

# Remove git history
cd my-new-project
rm -rf .git

# Initialize fresh git repo
git init

# Follow TEMPLATE-INSTRUCTIONS.md
```

## Key Features

### 1. Lifecycle-Based Documentation

Documents move through a clear lifecycle:
- **SPECIFICATIONS/** - What you're building now
- **REFERENCE/** - How implemented features work
- **ARCHIVE/** - Historical specs from completed phases

This keeps active context minimal and focused.

### 2. AI Collaboration Principles

The `.claude/` folder contains:
- Behavioral guidelines (Swedish directness, no silk gloves)
- Product management thinking mode
- Technology preferences
- Documentation standards

These auto-load when working with Claude Code.

### 3. Testing as Development Guardrails

Tests serve dual purposes:
- **Validation** - Traditional test coverage
- **Directional Context** - Guide AI on what to build and how

Targets: 95%+ coverage on lines/functions/statements, 90%+ on branches.

### 4. PR Review Skills

Built-in skills for automated code review:
- `/review-pr` - Fast single-reviewer (1-2 min)
- `/review-pr-team` - Multi-perspective team review (5-10 min)

### 5. Token-Efficient Design

CLAUDE.md files act as "library indexes":
- Auto-load relevant context
- Link to detailed docs
- Keep active token usage low
- Scale to large projects

## What You Need to Customize

When starting a new project, update these files:

**Essential:**
- [ ] `CLAUDE.md` - Replace template with your project details
- [ ] `SPECIFICATIONS/CLAUDE.md` - List your implementation phases
- [ ] `SPECIFICATIONS/ORIGINAL_IDEA/` - Add your project specification
- [ ] `.claude/settings.local.json` - Add project-specific permissions
- [ ] `REFERENCE/environment-setup.md` - Document your env vars

**As Needed:**
- [ ] `REFERENCE/troubleshooting.md` - Add project-specific issues as you encounter them
- [ ] Technology preferences in `.claude/COLLABORATION/technology-preferences.md` if different from defaults

**See:** [TEMPLATE-INSTRUCTIONS.md](./TEMPLATE-INSTRUCTIONS.md) for complete customization checklist.

## Philosophy

This template embodies several core beliefs:

1. **AI assistants are coworkers, not servants** - Collaboration works best when both parties contribute expertise
2. **Documentation is an investment** - Good docs enable future work and knowledge transfer
3. **Tests guide development** - Especially important when working with AI
4. **Simplicity over perfection** - Start simple, add complexity when needed
5. **Systematic > ad-hoc** - Consistent patterns scale better than case-by-case decisions

## Structure Overview

```
project-root/
├── .claude/                    # Claude Code configuration (auto-loads)
│   ├── CLAUDE.md              # Collaboration principles (reusable across projects)
│   ├── COLLABORATION/         # Behavioral guidance, PM mode, tech preferences
│   ├── skills/                # PR review skills
│   ├── settings.json          # Claude Code settings
│   └── settings.local.json    # Project-specific permissions
├── SPECIFICATIONS/             # Forward-looking implementation plans
│   ├── CLAUDE.md              # How to structure phases (template guidance)
│   ├── 00-TEMPLATE-phase.md   # Example phase structure
│   ├── ORIGINAL_IDEA/         # Initial project concept documents
│   └── ARCHIVE/               # Completed phase specs
├── REFERENCE/                  # How-it-works docs for implemented features
│   ├── CLAUDE.md              # Reference library index
│   ├── testing-strategy.md    # Testing philosophy and approach
│   ├── technical-debt.md      # Known issues tracker
│   ├── environment-setup.md   # API keys and env var guide
│   ├── troubleshooting.md     # Common issues and solutions
│   └── pr-review-workflow.md  # PR review process
├── CLAUDE.md                   # Project navigation index (customize per project)
├── README.md                   # This file (replace with your project README)
└── TEMPLATE-INSTRUCTIONS.md    # Step-by-step customization guide
```

## Technology Defaults

The template assumes these technologies (but you can change):
- TypeScript for web applications
- Next.js for frontend frameworks
- Cloudflare Workers for hosting
- Supabase for database
- Vitest for testing

See `.claude/COLLABORATION/technology-preferences.md` for complete list and rationale.

## Contributing

Found ways to improve this template? Contributions welcome!

1. Fork this repository
2. Make your improvements
3. Submit a PR with clear description of the benefit

## License

[Choose your license - MIT, Apache 2.0, etc.]

## Credits

Collaboration principles and documentation patterns inspired by:
- [@obra](https://github.com/obra) - Agentic coding patterns
- [@harperreed](https://github.com/harperreed) - AI collaboration workflows
- [OpenAI's Harness Engineering](https://openai.com/index/harness-engineering/) - Tests as development guardrails
- [steipete/agent-rules](https://github.com/steipete/agent-rules) - Comprehensive agent guidance

---

**Ready to start?** → Read [TEMPLATE-INSTRUCTIONS.md](./TEMPLATE-INSTRUCTIONS.md) next!
