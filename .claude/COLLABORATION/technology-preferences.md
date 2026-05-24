# Technology Stack and Choices

**When to read this:** Selecting frameworks, libraries, services, or making technology stack decisions.

**Related Documents:**
- [CLAUDE.md](./../../CLAUDE.md) - Project navigation index
- [CLAUDE.md](./../CLAUDE.md) - Collaboration principles

---

Reference guide for selecting technologies across projects.

## General preferences

- Free or low cost solutions are always preferred
- We prefer state-of-the-art solutions, but avoid experimental code or beta versions (unless nothing else is available)
- Never use outdated or deprecated solutions
- If a suitable technology doesn't seem to be available, recommend running a deep research task first to understand the topic better and find potential alternatives
- For any selected framework, library, third party component, API or other service, read the manual to ensure you use the latest stable version and follow best practice usage and patterns

## Platform-specific preferences

| Use Case | Preferred Technology | Reason |
| --- | --- | --- |
| CLI/Headless projects | Python | Simplicity and extensive standard library |
| Web application projects | TypeScript (strict mode) | Industry standard type safety |
| Web frontend framework | Next.js (React) with App Router | Server-side rendering, SEO, and strong ecosystem |
| Web frontend design | Tailwind CSS with shadcn/ui | Utility-first styling with a solid accessible component library |
| Hosting of websites and web apps | Cloudflare | Global edge network, generous free tier, excellent Workers platform for serverless |
| CDN / DNS / Basic data storage | Cloudflare KV | Tightly integrated with Cloudflare hosting; fast and low-cost |
| Database, Storage | Cloudflare D1, R2, Images or Supabase where Cloudflare falls short | Cloudflare-native options keep infrastructure consolidated; Supabase covers relational depth that D1 doesn't yet handle |
| Email communication | Cloudflare Email Routing or Resend where Cloudflare falls short | Resend is developer-friendly with excellent deliverability; Cloudflare handles basic routing for free |
| Authentication | Magic link systems (or Cloudflare Zero Trust) | No password management; simple and secure for most use cases |
| Payment processing | Stripe | Industry standard with excellent developer experience and global coverage |
| Web analytics | Cloudflare Web Analytics | Privacy-focused, cookie-free — no consent banner required |
