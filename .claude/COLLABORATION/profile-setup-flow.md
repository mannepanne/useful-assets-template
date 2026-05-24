# Profile setup flow

Instructions for Claude when `PERSONAL_PROFILE_SETUP_REQUIRED` fires at session start. Run this flow before any other work.

---

## When this runs

The hook at `.claude/hooks/check-profile-setup.sh` detects the `<!-- profile_status: default -->` sentinel in `.claude/COLLABORATION/personal-profile.md` and emits the signal. This means the project is using the default (Magnus's) profile and hasn't been personalised yet.

---

## The flow

### Step 1: Check intent

Open with:

> "I see this project is using the default profile. If you're Magnus and want to keep it as-is, just say so and I'll clear the setup flag so this won't fire again. Otherwise, I'll ask a few quick questions so we can make it yours."

### Step 2a: Keep as-is

If they confirm they want to keep it (e.g. "that's me", "keep it", "I'm Magnus"):
- Remove the `<!-- profile_status: default -->` line from `.claude/COLLABORATION/personal-profile.md`
- Skip the rest of this flow and continue with whatever they came to do

### Step 2b: Personalise

Ask three questions one at a time — wait for the answer before asking the next:

1. *"What's your name, and how would you like me to address you?"*
2. *"What's your background? I calibrate how I explain things based on this — whether you're a developer, designer, non-technical founder, or something else entirely."*
3. *"How direct should I be? Think: whether to call out bad ideas bluntly, how much technical detail to include, whether a bit of humour is welcome."*

If they mention product work, add:

4. *"One more — when we're in product-thinking mode (strategy, discovery, requirements), how do you see yourself? Technical PM, domain expert, generalist, something else?"*

### Step 3: Rewrite the profile

Rewrite `.claude/COLLABORATION/personal-profile.md` based on their answers:
- Remove the sentinel line
- Keep the same section structure (Identity, Background and role, Communication style)
- Add a PM profile section only if they mentioned product work
- Write in first person from the operator's perspective, matching the style of the default profile

### Step 4: Privacy offer

> "The profile is saved to the repo by default. If the repo is private that's fine — it stays with the code. If the repo is public, or you'd rather keep your profile separate from the code, I can add it to `.gitignore`. Worth knowing: because the file is already committed, you'd also need to run `git rm --cached .claude/COLLABORATION/personal-profile.md` to untrack it — I can handle that too. Want me to make it private?"

If yes: add `.claude/COLLABORATION/personal-profile.md` to `.gitignore` and run `git rm --cached .claude/COLLABORATION/personal-profile.md`.

### Step 5: Guide to next step

> "You're all set. Now — tell me about the project you want to build. I'll ask whatever I need to understand the idea, then write it up as `project-outline.md` in `SPECIFICATIONS/ORIGINAL_IDEA/` so we have a starting point for a specification to work from."
