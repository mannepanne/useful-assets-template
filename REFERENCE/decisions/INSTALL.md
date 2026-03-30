# Installing the ADR System

This guide shows how to add Architecture Decision Records (ADRs) to another project.

---

## What is the ADR system?

**Architecture Decision Records** document significant technical choices to prevent re-debating settled decisions. They capture:
- What was decided
- Why it came up
- Alternatives considered
- Why this option won
- Trade-offs accepted

**See:** `REFERENCE/decisions/CLAUDE.md` in this template for complete explanation.

---

## Installation steps

### Step 1: Copy ADR files

Copy these files from the useful-assets-template repository to your target project:

```bash
# From useful-assets-template:
REFERENCE/decisions/CLAUDE.md
REFERENCE/decisions/TEMPLATE-adr.md

# To target project:
REFERENCE/decisions/CLAUDE.md
REFERENCE/decisions/TEMPLATE-adr.md
```

**Create the directory first if it doesn't exist:**
```bash
mkdir -p REFERENCE/decisions
```

### Step 2: Integrate into `.claude/CLAUDE.md`

Add this section to the **"Learning and Memory Management"** section:

*Note: Line numbers below are approximate based on the template - search by section name if not found at expected location.*

```markdown
- **Architecture Decision Records (ADRs):** When making decisions that affect architecture beyond today's PR (library choice, architectural pattern, API design, deciding NOT to do something):
  - Prompt user: "This decision affects future architecture. Should I create an ADR in REFERENCE/decisions/?"
  - If confirmed, create ADR documenting: decision, context, alternatives considered, reasoning, trade-offs accepted
  - Before making similar decisions, search `REFERENCE/decisions/` for precedent
  - Follow existing ADRs unless new information invalidates the reasoning
  - See [REFERENCE/decisions/CLAUDE.md](../REFERENCE/decisions/CLAUDE.md) for complete ADR guidance
```

**Where to add it:**
- Find the "Learning and Memory Management" section
- Add as a new bullet point after existing memory guidance
- Usually goes after "Track patterns in user feedback to improve collaboration over time"

### Step 3: Integrate into `SPECIFICATIONS/CLAUDE.md`

**Location 1: Technical Approach section**

Find the "Technical Approach" section in the phase template and update to:

```markdown
3. **Technical Approach**
   - Architecture decisions (document significant choices as ADRs in REFERENCE/decisions/)
   - Technology choices (check existing ADRs for precedent before deciding)
   - Key files and components
   - Database schema changes (if applicable)
```

**Location 2: Supporting documentation section**

Add this subsection after the ARCHIVE section:

```markdown
**[REFERENCE/decisions/](../REFERENCE/decisions/)** - Architecture Decision Records
- Search here BEFORE making architectural decisions (library choice, patterns, API design)
- Follow existing ADRs unless new information invalidates reasoning
- Document new architectural decisions here (prevents re-debating settled choices)
- See [ADR guidance](../REFERENCE/decisions/CLAUDE.md) for when and how to create ADRs
```

### Step 4: Integrate into root `CLAUDE.md`

Add this line to the **"Quick reference links"** section under the "Reference Docs" subsection:

```markdown
- **Architecture decisions?** → [decisions/](./REFERENCE/decisions/) - ADRs explaining why things are this way
```

**Where to add it:**
- Find the "Quick reference links" section
- Locate the "Reference Docs" subsection
- Add after other reference links (testing-strategy, technical-debt, troubleshooting, etc.)

### Step 5: Verify installation

Run through this checklist:

- [ ] `REFERENCE/decisions/CLAUDE.md` exists in target project
- [ ] `REFERENCE/decisions/TEMPLATE-adr.md` exists in target project
- [ ] `.claude/CLAUDE.md` has ADR workflow in "Learning and Memory Management"
- [ ] `SPECIFICATIONS/CLAUDE.md` has ADR reference in "Technical Approach"
- [ ] `SPECIFICATIONS/CLAUDE.md` has ADR reference in "Supporting documentation"
- [ ] Root `CLAUDE.md` has ADR reference in "Quick reference links"
- [ ] All file paths in copied text match target project structure

---

## What this enables

After installation, Claude will:
1. **Proactively suggest** creating ADRs when making architectural decisions
2. **Search precedent** in `REFERENCE/decisions/` before making similar decisions
3. **Follow existing ADRs** unless new information invalidates reasoning
4. **Document trade-offs** systematically for future reference

**Key benefit:** Prevents re-debating settled architectural choices across sessions/weeks/months.

---

## Customisation notes

**Different project structures:**
- If target project doesn't have `REFERENCE/` folder, create it or adapt paths
- If CLAUDE.md files have different sections, integrate ADR references appropriately
- Core concept stays same: Claude needs to know ADRs exist and when/how to use them

**Minimal installation:**
- At minimum: Copy the two ADR files + add workflow to `.claude/CLAUDE.md`
- Other integrations are helpful reminders but not strictly required

---

## Example workflow after installation

**User:** "Let's add authentication to the app"

**Claude:** "Before we choose an approach, let me search for existing ADRs..."
*Searches `REFERENCE/decisions/`*

**Scenario A - No precedent:**
"I don't see existing ADRs about authentication. We need to choose between JWT, sessions, or OAuth. This decision affects future architecture. Should I create an ADR in REFERENCE/decisions/?"

**User:** "Yes, let's use JWT"

**Claude:** "I'll create an ADR documenting this decision..."
*Creates `REFERENCE/decisions/2026-03-30-jwt-authentication.md` with decision, context, alternatives, reasoning, and trade-offs*
"ADR created. I'll now implement JWT authentication following the documented approach."

**Scenario B - Precedent exists:**
"Found ADR from 2026-01-15: we chose JWT for authentication due to stateless API requirements. I'll follow that precedent unless you want to reconsider based on new information."

---

## Maintenance

**After installation:**
- ADRs accumulate in `REFERENCE/decisions/` over time
- Update index in `REFERENCE/decisions/CLAUDE.md` when adding new ADRs
- Mark old ADRs as "Superseded" when decisions change (don't delete them)
- Link related ADRs together for context

**ADR files are permanent:**
- Version controlled with the codebase
- Survive compaction, crashes, long breaks
- Searchable and linkable from PRs/docs/code
- Build institutional knowledge over time
