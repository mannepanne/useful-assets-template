# Template Customization Instructions

Step-by-step guide to transform this template into your own project.

## Before You Start

**Time required:** 30-60 minutes for initial setup

**What you'll need:**
- Your project idea and name
- Basic architecture decisions (framework, database, hosting)
- List of major features to implement

**Recommended approach:**
- Read through this entire guide first
- Complete customization in one sitting
- Commit changes as you go

## Step-by-Step Customization

### Phase 1: Project Identity (15 minutes)

#### 1.1 Update Root README.md
- [ ] Replace this template's README with your project README
- [ ] Include project description, setup instructions, and how to run
- [ ] Add badges, screenshots, or demos if applicable
- [ ] Update license section

#### 1.2 Customize Root CLAUDE.md
- [ ] Open `CLAUDE.md` in project root
- [ ] Replace all `[PLACEHOLDER]` sections with your project details:
  - [ ] Project name and description
  - [ ] Core workflow steps
  - [ ] Technology stack
  - [ ] Key integrations
  - [ ] Current project status
- [ ] Update "Implementation Phases" section with your phase names
- [ ] Customize "Code Conventions" examples to match your project
- [ ] Add any project-specific notes at the bottom
- [ ] Remove the ⚠️ template warning at the top

**Example:** If building "TaskMaster" (a task management app):
```markdown
**TaskMaster** - A minimalist task management app with AI-powered task breakdown

**Core workflow:**
1. Create task with natural language
2. AI breaks down into subtasks
3. Track progress with simple interface
4. Get daily summaries via email
```

#### 1.3 Update This File
- [ ] Once customization is complete, delete or archive this `TEMPLATE-INSTRUCTIONS.md` file

---

### Phase 2: Project Planning (20-30 minutes)

#### 2.1 Create Your Project Specification
- [ ] Create `SPECIFICATIONS/ORIGINAL_IDEA/project-outline.md`
- [ ] Document:
  - [ ] Project vision and goals
  - [ ] Target users and use cases
  - [ ] Core features and scope
  - [ ] Success criteria
  - [ ] Technical constraints
- [ ] Optionally create `naming-rationale.md` if your project name has interesting context
- [ ] Delete the placeholder `README.md` in `ORIGINAL_IDEA/`

**Tip:** Use [00-TEMPLATE-phase.md](./SPECIFICATIONS/00-TEMPLATE-phase.md) as a reference, but create a higher-level document here.

#### 2.2 Break Down Implementation Phases
- [ ] Identify 4-8 major implementation phases
- [ ] Create phase files: `01-phase-name.md`, `02-phase-name.md`, etc.
- [ ] Use `00-TEMPLATE-phase.md` as a template for each phase
- [ ] Each phase should be 1-2 weeks of work maximum
- [ ] Phases should be sequential (each builds on previous)

**Example phase breakdown:**
1. `01-foundation.md` - Project setup, database, basic deployment
2. `02-authentication.md` - User accounts and auth
3. `03-task-management.md` - Core CRUD for tasks
4. `04-ai-integration.md` - AI-powered task breakdown
5. `05-email-summaries.md` - Email service integration
6. `06-polish-launch.md` - UI refinement, testing, deployment

#### 2.3 Update SPECIFICATIONS/CLAUDE.md
- [ ] Open `SPECIFICATIONS/CLAUDE.md`
- [ ] Replace the "Template Replacement" section with your actual phase list
- [ ] Update "Current phase" indicator
- [ ] List your `ORIGINAL_IDEA/` files
- [ ] Remove the ⚠️ template warning

---

### Phase 3: Environment Configuration (10-15 minutes)

#### 3.1 Document Environment Variables
- [ ] Open `REFERENCE/environment-setup.md`
- [ ] Replace template sections with your actual services:
  - [ ] List all required environment variables
  - [ ] Document how to obtain each credential
  - [ ] Provide setup commands for local and production
  - [ ] Add third-party service setup instructions
- [ ] Remove the ⚠️ template warning

#### 3.2 Create Environment File Templates
- [ ] Create `.dev.vars.template` or `.env.local.template` (based on your framework)
- [ ] List all required variables with placeholder values
- [ ] Add comments explaining each variable
- [ ] Add template file to git, but ensure actual secrets file is in `.gitignore`

**Example `.dev.vars.template`:**
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# OpenAI API
OPENAI_API_KEY=sk-...

# Email Service
RESEND_API_KEY=re_...
```

#### 3.3 Update .gitignore
- [ ] Create `.gitignore` if it doesn't exist
- [ ] Add all secret files:
  ```
  .dev.vars
  .env.local
  .env.production
  ```
- [ ] Add common ignores for your framework
- [ ] Add system files (.DS_Store, Thumbs.db)

---

### Phase 4: Project-Specific Settings (5-10 minutes)

#### 4.1 Customize Claude Code Permissions
- [ ] Open `.claude/settings.local.json`
- [ ] Review auto-approved permissions
- [ ] Add project-specific permissions if needed:
  - File paths you want to allow reading
  - Additional bash commands
  - WebFetch domains for APIs you'll use
- [ ] Keep it minimal - only add what you need

**Example additions:**
```json
"Read(//path/to/your/project/src/**)",
"Bash(docker:*)",
"WebFetch(domain:your-api-domain.com)"
```

#### 4.2 Review Collaboration Preferences
- [ ] Check `.claude/CLAUDE.md` - collaboration principles (generally don't change)
- [ ] Review `.claude/COLLABORATION/technology-preferences.md`
- [ ] Update if your tech stack differs significantly from defaults
- [ ] Review `.claude/COLLABORATION/product-management-mode.md` (optional reading)

---

### Phase 5: Testing Setup (5 minutes)

#### 5.1 Set Up Test Framework
- [ ] Install your testing framework:
  ```bash
  npm install -D vitest @vitest/ui
  # or
  npm install -D jest @types/jest
  ```
- [ ] Create test configuration file
- [ ] Add test scripts to `package.json`:
  ```json
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
  ```
- [ ] Verify tests run: `npm test`

#### 5.2 Review Testing Strategy
- [ ] Read `REFERENCE/testing-strategy.md`
- [ ] Ensure it matches your framework choice
- [ ] Update examples if using different testing library
- [ ] Keep coverage targets (95%+ lines/functions/statements, 90%+ branches)

---

### Phase 6: Final Cleanup (5 minutes)

#### 6.1 Remove Template Artifacts
- [ ] Delete `SPECIFICATIONS/00-TEMPLATE-phase.md` (or keep as reference)
- [ ] Delete or archive `TEMPLATE-INSTRUCTIONS.md` (this file)
- [ ] Search for remaining `⚠️ TEMPLATE` warnings
- [ ] Remove template README and replace with your own

#### 6.2 Initialize Git Repository
- [ ] If not already a git repo:
  ```bash
  git init
  git add .
  git commit -m "Initial commit from template"
  ```
- [ ] Create GitHub repository
- [ ] Push to GitHub:
  ```bash
  git remote add origin https://github.com/yourusername/your-project.git
  git branch -M main
  git push -u origin main
  ```

#### 6.3 Verify Setup
- [ ] All template placeholders replaced
- [ ] Environment file template created
- [ ] `.gitignore` configured
- [ ] Tests run successfully
- [ ] Documentation reflects your project
- [ ] No Ansible or template references remaining

---

## Customization Checklist Summary

Quick reference to ensure you didn't miss anything:

### Core Files
- [ ] `README.md` - Project-specific README
- [ ] `CLAUDE.md` - Project navigation with your details
- [ ] `.gitignore` - Includes all secret files

### Specifications
- [ ] `SPECIFICATIONS/CLAUDE.md` - Your phase list
- [ ] `SPECIFICATIONS/ORIGINAL_IDEA/project-outline.md` - Your project spec
- [ ] `SPECIFICATIONS/01-XX-phase-name.md` - Your implementation phases (4-8 files)

### Reference Docs
- [ ] `REFERENCE/environment-setup.md` - Your environment variables
- [ ] `REFERENCE/testing-strategy.md` - Updated for your test framework
- [ ] `REFERENCE/troubleshooting.md` - Will update as you encounter issues

### Configuration
- [ ] `.claude/settings.local.json` - Project-specific permissions
- [ ] `.dev.vars.template` or `.env.local.template` - Environment file template
- [ ] `package.json` - Test scripts configured

### Cleanup
- [ ] Template warnings removed
- [ ] Template example files deleted
- [ ] Git repository initialized
- [ ] First commit made

---

## Starting Development

Once customization is complete:

1. **Read your Phase 1 specification**
   - Review deliverables and acceptance criteria
   - Understand technical approach
   - Note testing requirements

2. **Start with Claude Code**
   ```bash
   # If not already running Claude Code
   claude

   # Ask Claude to start Phase 1
   "Let's start implementing Phase 1: [phase name]. Can you review the specification at SPECIFICATIONS/01-phase-name.md and create a todo list for this phase?"
   ```

3. **Follow the workflow**
   - Claude will create todo list
   - Work through todos systematically
   - Run tests frequently (`npm test`)
   - Type check regularly (`npx tsc --noEmit`)
   - Commit often

4. **Use PR reviews**
   - When phase complete: `/review-pr`
   - For critical changes: `/review-pr-team`
   - Address feedback
   - Merge to main

5. **Update documentation**
   - Move completed spec to `ARCHIVE/`
   - Create how-it-works docs in `REFERENCE/`
   - Update root `CLAUDE.md` with current phase

6. **Move to next phase**
   - Repeat for each implementation phase
   - Build systematically
   - Maintain high test coverage
   - Keep documentation current

---

## Troubleshooting Customization

### "I'm not sure how to break down phases"
- Start with 3-4 major milestones
- Each should deliver working, testable functionality
- Foundation phase always comes first (setup, database, deployment)
- End with a polish/launch phase
- Keep phases small (1-2 weeks max)

### "My project doesn't fit this structure"
- The template is flexible - adapt as needed
- Core principles (tests, docs, phases) apply broadly
- Feel free to reorganize folders for your needs
- Keep the lazy-loading CLAUDE.md pattern if possible

### "Do I need to use all the REFERENCE files?"
- `testing-strategy.md` - Yes, update for your framework
- `environment-setup.md` - Yes, document your env vars
- `troubleshooting.md` - Start with template, add issues as you encounter them
- `technical-debt.md` - Use as needed during development
- `pr-review-workflow.md` - Keep as-is unless you customize review process

### "Can I skip the ORIGINAL_IDEA folder?"
- Not recommended - it's your source of truth
- Even a simple outline helps maintain vision
- Useful when making trade-off decisions later
- Takes 15-30 minutes to create

---

## Getting Help

If you get stuck during customization:
- Review the template README.md
- Look at collaboration principles in `.claude/CLAUDE.md`
- Ask Claude Code for help: "How should I structure my project phases for [describe your project]?"

---

**Once customization is complete, you're ready to build!** Start with Phase 1 and work through your implementation systematically. Good luck! 🚀
