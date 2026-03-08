# Template customisation instructions

Step-by-step guide to transform this template into a new project.

**NOTE:** There are some very Magnus specific references (to me) and ways of working encapsulated in @.claude/CLAUDE.md and the @.claude/COLLABORATION files. That obviously works for me, but unless you want to be treated as a Swedish 50 something slightly detailed obsessive SciFi-geek, you probably want to either wipe it (and let Claude recreate it for your project) or spend some time making it your own.

**Customisation recommendation:** do these steps in collaboration with Claude. In conversation, discuss the idea, ask for feedback and critique, answer any and all questions from Claude to refine and iterate on the idea. Explicitly tell Claude to not write any code, just talk through what you are about to embark on. Save all the resulting thoughts and notes as Markdown files in the @SPECIFICATIONS/ folder, and I typically ask for a phased step by step implementation plan as the very last output.

When done, ask Claude to review all reference documentation and start making it project specific.

## Before you start

**Time required:** 30-60 minutes for initial setup

**Starter for 10:**
- Project idea and name
- Basic architecture decisions (framework, database, hosting)
- List of major features to implement

**Recommended approach:**
- Read through this entire guide first
- Complete customisation in one sitting
- Commit changes as you go

## Step-by-step customisation

### Phase 1: Project identity

#### 1.1 Update root README.md
- [ ] Replace this template's README with a new project README
- [ ] Include project description, setup instructions, and how to run
- [ ] Add badges, screenshots, or demos if applicable
- [ ] Update license section

#### 1.2 Customise root CLAUDE.md
- [ ] Open `CLAUDE.md` in project root
- [ ] Replace all `[PLACEHOLDER]` sections with new specific project details:
  - [ ] Project name and description
  - [ ] Core workflow steps
  - [ ] Technology stack
  - [ ] Key integrations
  - [ ] Current project status
- [ ] Update "Implementation Phases" section with actual phase names
- [ ] Customise "Code Conventions" examples to match the project
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

#### 1.3 Update this file
- [ ] Once customisation is complete, delete or archive this `TEMPLATE-INSTRUCTIONS.md` file

---

### Phase 2: Project planning

#### 2.1 Create the project specification
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

#### 2.2 Break down implementation phases
- [ ] Identify 4-8 major implementation phases
- [ ] Create phase files: `01-phase-name.md`, `02-phase-name.md`, etc.
- [ ] Use `00-TEMPLATE-phase.md` as a template for each phase
- [ ] Phases should be sequential (each builds on previous)

**Example phase breakdown using the "TaskMaster" example:**
1. `01-foundation.md` - Project setup, database (if used), basic deployment
2. `02-authentication.md` - User accounts and auth
3. `03-task-management.md` - Core CRUD for tasks
4. `04-ai-integration.md` - AI-powered task breakdown
5. `05-email-summaries.md` - Email service integration
6. `06-polish-launch.md` - UI refinement, testing, deployment

#### 2.3 Update SPECIFICATIONS/CLAUDE.md
- [ ] Open `SPECIFICATIONS/CLAUDE.md`
- [ ] Replace the "Template Replacement" section with actual phase list
- [ ] Update "Current phase" indicator
- [ ] List the `ORIGINAL_IDEA/` files (if used)
- [ ] Remove the ⚠️ template warning

---

### Phase 3: Environment configuration

#### 3.1 Document environment
- [ ] Open `REFERENCE/environment-setup.md`
- [ ] Replace template sections with actual services:
  - [ ] List all required environment variables
  - [ ] Document how to obtain each credential
  - [ ] Provide setup commands for local and production
  - [ ] Add third-party service setup instructions
- [ ] Remove the ⚠️ template warning

#### 3.2 Create environment file templates
- [ ] Create `.dev.vars.template` or `.env.local.template` (based on your framework)
- [ ] List all required variables with placeholder values
- [ ] Add comments explaining each variable
- [ ] Add template file to git, but ensure actual secrets file is in `.gitignore`

**Example `.dev.vars.template`:**
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Anthropic API
ANTHROPIC_API_KEY=sk-...

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
- [ ] Add common ignores for chosen framework
- [ ] Add system files (.DS_Store, Thumbs.db)

---

### Phase 4: Project-specific settings

#### 4.1 Customise Claude Code permissions
- [ ] Open `.claude/settings.local.json`
- [ ] Review auto-approved permissions
- [ ] Add project-specific permissions if needed:
  - File paths you want to allow reading
  - Additional bash commands
  - WebFetch domains for APIs you'll use
- [ ] Keep it minimal - only add what's required

**Example additions:**
```json
"Read(//path/to/project/src/**)",
"Bash(docker:*)",
"WebFetch(domain:your-api-domain.com)"
```

#### 4.2 Review collaboration preferences
- [ ] Check `.claude/CLAUDE.md` - collaboration principles (generally don't change)
- [ ] Review `.claude/COLLABORATION/technology-preferences.md`
- [ ] Update if chosen tech stack differs significantly from defaults
- [ ] Review `.claude/COLLABORATION/product-management-mode.md` (optional reading)

---

### Phase 5: Testing setup

#### 5.1 Set up test framework
- [ ] Install the testing framework:
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

#### 5.2 Review testing strategy
- [ ] Read `REFERENCE/testing-strategy.md`
- [ ] Ensure it matches the framework choice
- [ ] Update examples if using different testing library
- [ ] Keep coverage targets (95%+ lines/functions/statements, 90%+ branches)

---

### Phase 6: Final cleanup

#### 6.1 Remove template artifacts
- [ ] Delete `SPECIFICATIONS/00-TEMPLATE-phase.md` (or keep as reference)
- [ ] Delete or archive `TEMPLATE-INSTRUCTIONS.md` (this file)
- [ ] Search for remaining `⚠️ TEMPLATE` warnings
- [ ] Remove template README and replace with project specific one

#### 6.2 Initialise git repository
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

#### 6.3 Verify setup
- [ ] All template placeholders replaced
- [ ] Environment file template created
- [ ] `.gitignore` configured
- [ ] Tests run successfully
- [ ] Documentation reflects your project
- [ ] No template references remaining

---

## Customisation checklist summary

Quick reference to ensure you didn't miss anything:

### Core files
- [ ] `README.md` - Project-specific README
- [ ] `CLAUDE.md` - Project navigation with appropriate details
- [ ] `.gitignore` - Includes all secret files

### Specifications
- [ ] `SPECIFICATIONS/CLAUDE.md` - Project implementation phase list
- [ ] `SPECIFICATIONS/ORIGINAL_IDEA/project-outline.md` - Project vision and outline spec
- [ ] `SPECIFICATIONS/01-XX-phase-name.md` - Actual implementation phases

### Reference docs
- [ ] `REFERENCE/environment-setup.md` - Project environment variables
- [ ] `REFERENCE/testing-strategy.md` - Updated for chosen test framework
- [ ] `REFERENCE/troubleshooting.md` - Will update as issues are encountered

### Configuration
- [ ] `.claude/settings.local.json` - Project-specific permissions
- [ ] `.dev.vars.template` or `.env.local.template` - Environment file template
- [ ] `package.json` - Test scripts configured

### Cleanup
- [ ] Template warnings removed
- [ ] Template example files deleted
- [ ] Git repository initialised
- [ ] First commit made

---

## Starting development

Once customisation is complete:

1. **Read the Phase 1 specification**
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

## Troubleshooting customisation

### "I'm not sure how to break down phases"
- Start with 3-4 major milestones
- Each should deliver working, testable functionality
- Foundation phase always comes first (setup, database, deployment)
- End with a polish / launch phase
- Keep phases small (sensible size for continuous review and validation)

### "My project doesn't fit this structure"
- The template is flexible - adapt as needed
- Core principles (tests, docs, phases) apply broadly
- Feel free to reorganise folders for project specific purposes and needs
- Keep the lazy-loading CLAUDE.md pattern if possible

### "Do I need to use all the REFERENCE files?"

No, not at all. This is just how I have chosen to do things. Make it yours.

- `testing-strategy.md` - Yes, update for your framework
- `environment-setup.md` - Yes, document your env vars
- `troubleshooting.md` - Start with template, add issues as you encounter them
- `technical-debt.md` - Use as needed during development
- `pr-review-workflow.md` - Keep as-is unless you customise review process

### "Can I skip the ORIGINAL_IDEA folder?"
- Absolutely, but I am a stickler for remembering how something started, it's like a source of truth
- Even a simple outline helps maintain vision
- Useful when making trade-off decisions later
- Takes very little time to create and can be immensely helpful inn two month's time...

---

## Getting help

If you get stuck during customisation:
- Review the template README.md
- Look at collaboration principles in `.claude/CLAUDE.md`
- Ask Claude Code for help: "How should I structure my project phases for [describe your project]?"

---

**Once customisation is complete, the project is ready to build!** Start with Phase 1 and work through the implementation systematically. Good luck! 🚀
