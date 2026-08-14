# Subagent Architecture - Kegel Project

This directory contains project-specific subagent configuration and role definitions for the Kegel iOS app.

---

## Directory Structure

```
.claude/
├── agents/
│   ├── CLAUDE.md          # ← Subagent rules & domain constraints (read this first)
│   └── README.md          # This file
├── settings.json          # Project-level Claude Code config
└── settings.local.json    # Local overrides (not in git)
```

---

## How Subagents Work Here

All 158+ agents from [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) are available globally in `~/.claude/agents/`.

**Claude Code auto-selects agents based on your task context.** For example:
- "Review this diff for bugs" → `code-reviewer` agent
- "Design the onboarding flow" → `frontend-developer` + `ui-designer`
- "Optimize the workout engine" → `performance-engineer` + `refactoring-specialist`
- "Audit health compliance" → `security-auditor` + `compliance-auditor`

When an agent works on this project, it reads:
1. **Global rules** from `~/.claude/agents/` (your installed 158+ agents)
2. **Project rules** from `./.claude/agents/CLAUDE.md` (this repo's constraints)
3. **Root CLAUDE.md** (product decisions, architecture)

So every agent knows:
- Never claim health diagnosis
- Use SwiftUI, not UIKit
- `Core` package has no platform imports
- RevenueCat is hidden behind `Purchases` protocol
- Tests use `Swift Testing`, not XCTest
- etc.

---

## Agent Role Map

| Category | Agents | When to Use |
|---|---|---|
| **Swift & iOS** | `swift-expert`, `expo-react-native-expert`, `mobile-developer` | Language features, SwiftUI patterns, concurrency |
| **Code Quality** | `code-reviewer`, `refactoring-specialist`, `qa-expert` | Bug hunts, simplification, test coverage |
| **Architecture** | `architect-reviewer`, `microservices-architect`, `design-bridge` | System design, package structure, DI |
| **Performance** | `performance-engineer`, `database-optimizer`, `dx-optimizer` | Latency, memory, build times |
| **UI/UX** | `frontend-developer`, `ui-designer`, `ui-ux-tester`, `accessibility-tester` | Screens, components, WCAG compliance |
| **Testing** | `test-automator`, `qa-expert`, `accessibility-tester` | Test suites, e2e, usability |
| **DevOps** | `devops-engineer`, `deployment-engineer`, `ci-cd-architect` | CI/CD, XcodeGen, build automation |
| **Security** | `security-auditor`, `compliance-auditor`, `security-engineer` | GDPR, health data privacy, App Store guidelines |
| **Payments** | `payment-integration`, `fintech-engineer` | RevenueCat, StoreKit 2, IAP flows |
| **Analytics** | `data-analyst`, `cohort-analysis`, `ab-test-analysis` | Event tracking, user retention |
| **Documentation** | `documentation-engineer`, `technical-writer`, `readme-generator` | README, API docs, onboarding |
| **Localization** | `technical-writer`, `content-marketer` | String Catalog, multi-language |

---

## Example: Automatic Agent Invocation

**You ask Claude Code:**
> "Add dark mode support to the Settings screen and audit accessibility"

**Claude automatically spawns:**
1. `frontend-developer` (SwiftUI color tokens, dark mode)
2. `ui-designer` (dark mode aesthetics)
3. `accessibility-tester` (VoiceOver, contrast, Dynamic Type)

Each agent reads `.claude/agents/CLAUDE.md` and knows:
- Use `DesignSystem` tokens, not hardcoded colors
- Support Dynamic Type (no fixed font sizes)
- Test with VoiceOver and Reduce Motion enabled
- Verify dark/light mode work

---

## How to Request Work

### Option 1: Let Claude Auto-Select (Recommended)
```
"Add haptic feedback to workout completion."
```
Claude picks the right agent(s): `feedback` knowledge + `mobile-app-developer` expertise.

### Option 2: Name the Agent
```
"Ask the performance-engineer: should we cache content.json in memory or on disk?"
```
Claude routes to `performance-engineer` directly.

### Option 3: Multi-Agent Coordination
```
"Coordinate with architects to design the LiveActivity feature:
 - How should we structure the state machine?
 - Which modules own what?
 - Test strategy?"
```
Claude spawns `architect-reviewer`, `test-automator`, and routes async work.

---

## Key Constraints Every Agent Knows

1. **No diagnosis/treatment claims** — all agents know this
2. **SwiftUI, no UIKit** — platform experts know this
3. **Core package = pure domain** — architecture agents enforce it
4. **RevenueCat hidden behind protocol** — payment agents use this pattern
5. **JSON + Repository pattern** — no SwiftData
6. **Swift Testing only** — QA agents know this
7. **Health data on-device only** — security auditors verify this
8. **One type per file, max ~200 lines** — refactoring agents respect this

---

## Troubleshooting

### "An agent isn't respecting project constraints"
→ Make sure `.claude/agents/CLAUDE.md` is in the repo and agents read it (they should automatically).

### "I want a custom agent for domain X"
→ Create `.claude/agents/my-custom-agent.md` with role definition. Agents will discover it.

### "Global agents work; why not project agents?"
→ Project agents in `./.claude/agents/` are for **configuration** (like this CLAUDE.md). Global agents in `~/.claude/agents/` are the actual implementations.

### "How do I see all available agents?"
```bash
ls ~/.claude/agents/ | wc -l
ls ~/.claude/agents/ | sort
```
You have 158+ global agents. Project agents inherit these rules.

---

## Maintenance

- **Update CLAUDE.md** whenever product decisions or architecture rules change
- **Sync with root CLAUDE.md** — if section numbering changes there, reflect it here
- **Agent versions** are managed globally in `~/.claude/agents/` (updated via awesome-claude-code-subagents releases)

---

## References

- Root CLAUDE.md (product + architecture)
- [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) (global agent library)
- `project.yml` (XcodeGen build config)
- `CODEOWNERS` (package ownership, tied to dev responsibility)

---

**Last updated:** 2026-08-14
