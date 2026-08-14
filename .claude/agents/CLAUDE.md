# Subagent Instructions - Kegel Project

This file contains domain rules and constraints that apply to all subagents working on this iOS application.
Read this before implementing features, architecture changes, or code reviews.

---

## 1. Project Overview

**Product:** Male pelvic floor exercise guide for iOS 17+.

**Core Constraints (Non-negotiable):**
- ❌ **No diagnosis:** Never output "you have X condition" or "this treats Y symptom"
- ❌ **No health claims:** Text like "cures incontinence" or "treats ED" is forbidden
- ❌ **No inference from data:** Show user data, but don't comment on it medically
- ❌ **No server-side health data:** Session records, personal info, and medical details stay on-device
- ❌ **No complex branching onboarding:** Single health warning screen, then level/time selection

These constraints keep the app outside medical device regulation. If a feature requests touch these, **halt and ask before coding.**

---

## 2. Technical Stack

| Component | Decision | Rationale |
|---|---|---|
| **UI Framework** | SwiftUI (no UIKit unless bridging) | Modern, type-safe, native to iOS 17+ |
| **Min iOS** | 17.0 | Latest stable, deprecation horizon |
| **State Management** | `@Observable`, `@State`, `@Environment` | Observation framework, strict concurrency |
| **Concurrency** | Swift 6 language mode, strict | Actor isolation, no data races |
| **Persistence** | `Codable` + JSON, `Repository` protocol | SwiftData adds coupling we don't need |
| **3rd Party** | RevenueCat (subscriptions), Analytics SDK only | No other external deps without PR justification |
| **Build System** | XcodeGen (`project.yml`) | Eliminates `.pbxproj` merge conflicts |
| **Testing** | Swift Testing (`import Testing`) | Modern, native framework |
| **Localization** | String Catalog (`.xcstrings`) | No hardcoded strings in code |

**Why not SwiftData?** Our data model is small and flat; SwiftData's strict concurrency friction gives us no value. `Repository` protocol lets us swap it later if we need to.

**Why XcodeGen?** Two developers working in parallel need to avoid `.pbxproj` conflicts. Config-as-code in `project.yml` nearly eliminates conflicts. `.xcodeproj` goes in `.gitignore`. Setup: `brew install xcodegen && xcodegen generate`.

---

## 3. Module Structure

Code is split across local Swift Packages. **One type per file**, max ~200 lines/file. Break it up if larger.

```
PelvicApp/
├── project.yml
├── CLAUDE.md                     (root level — product + architecture)
├── .claude/
│   ├── agents/
│   │   ├── CLAUDE.md             (this file)
│   │   └── README.md             (agent role map)
│   └── settings.json
├── App/
│   ├── PelvicApp.swift
│   ├── AppEnvironment.swift      (DI container)
│   └── RootView.swift
├── Packages/
│   ├── Core/                     (sane domain, no UIKit/SwiftUI import)
│   │   └── Sources/Core/
│   │       ├── Models/           (Phase, WorkoutStep, Level, SessionRecord)
│   │       ├── Engine/           (WorkoutEngine, Clock, StateTransition)
│   │       ├── Screening/        (ScreeningQuestion, ScreeningRouter, RedFlag)
│   │       └── Program/          (ProgramBuilder, ProgressionRule)
│   ├── Persistence/              (Repository protocol + JSON impl)
│   ├── Feedback/                 (CoreHaptics, AVSpeechSynthesizer, AVAudioSession)
│   ├── Notifications/            (UNUserNotificationCenter wrapper)
│   ├── Purchases/                (SubscriptionProviding + RevenueCat impl)
│   ├── RemoteContent/            (content.json fetch, validation, cache, fallback)
│   ├── Analytics/                (AnalyticsTracking protocol + impl)
│   ├── LiveSession/              (Live Activity + Dynamic Island)
│   ├── DesignSystem/             (color, typography, spacing tokens + shared components)
│   └── Features/                 (screens, one folder per feature)
│       ├── Onboarding/
│       ├── Workout/
│       ├── Progress/
│       ├── Paywall/
│       └── Settings/
└── Tests/                        (each package has its own test target)
```

**Dependency direction (single-way):**
`App` → `Features` → `DesignSystem` / `Core` / `Persistence` / `Feedback` / `Notifications` / `Purchases` / `RemoteContent` / `Analytics`.

`Core` imports **nothing platform-related** and has **no external dependencies**.

**SDK isolation:** RevenueCat only in `Purchases`. Analytics SDK only in `Analytics`. `Features` never imports these directly, only protocols.

---

## 4. Domain Rules

### Workout Flow
```
prepare → (contract → [hold] → relax) × reps → rest → ... → finished
```

### Engine (WorkoutEngine)
- Lives in `Core`, imports **no platform frameworks**
- Time calculation: measure elapsed time from step start via `Date()`, not tick counting (timers drift)
- Inject `Clock` protocol for testing. Tests use `TestClock`, never `sleep()`
- States: `idle`, `running`, `paused`, `finished`. Transitions are centralized

### Program Structure
- Levels are progressive: short contractions → longer holds, more reps
- Parameters live in `content.json`, **not in code**
- First level is "basic": learn correct muscle, proper breathing, full release — safety gate in UX, not feature lock
- Progression unlocks by completed sessions, no complex branching

### Onboarding
- Brief: health warning → goal/level pick → reminder time → first session
- **No multi-step branching questionnaires**
- Health warning is standard disclosure, not a gatekeeper

### Identity
- No signup, login, email, password
- User opens app → starts immediately (anonymous)
- Generate anonymous ID, show in Settings (copy for support)
- "Restore purchases" button in Settings

### Screenless Usage (Differentiator)
Three layers:
1. **Dim mode:** app stays foreground, screen goes almost-black session view, `isIdleTimerDisabled = true`
2. **Live Activity:** lock screen + Dynamic Island show phase and remaining time
3. **Apple Watch:** haptic feedback (requires watch app, Phase 2)

*Note:* CoreHaptics cannot run in background. So real "locked screen" vibration only works via Watch.

### Health Warning Screen
- Onboarding only screen, dismissible
- States: not medical advice, consult doctor if pain/symptoms
- Accessible from Settings for re-read
- This is standard App Store health category disclosure, not a feature lock

### Content Stays Outside Code
- Exercise text, level parameters → `content.json`
- `Core` parses it type-safely
- Load order:
  1. Embedded copy (fallback, always present)
  2. Fetch remote version at startup, validate schema
  3. If remote > embedded and passes validation, use it; else stay on embedded
  4. Invalid content silently fails over to embedded (app never crashes on bad JSON)
- **Mandatory test:** publish broken JSON, verify app still works

---

## 5. Backend, Subscriptions, Analytics

**No custom backend.** We buy what we need:

| Need | Solution | Owner |
|---|---|---|
| Purchase + subscription status | StoreKit 2 + RevenueCat | `Purchases` package |
| Content updates | Static `content.json` on CDN | `RemoteContent` package |
| Analytics | Analytics SDK, `AnalyticsTracking` protocol | `Analytics` package |
| Reminders | Local notifications only, no push | `Notifications` package |
| User account | None. Anonymous ID (RevenueCat App User ID) | App init |
| Cross-device sync | None (Phase 1). CloudKit private DB (Phase 2) | TBD |

**Health data never leaves the device.** Session records stay on-device. Analytics carries only behavior events (screen viewed, session started/finished, paywall shown/converted); no exercise content, level history, or personal data.

**Paywall timing:** Show after first completed session, not at download. Users convert better once they feel value.

**Free/paid boundary:** Define in `content.json`, not code. Default: first few levels + timer free; advanced levels, progress screen, dim mode paid.

---

## 6. Platform Constraints (Design Impact)

These directly affect design decisions—account for them upfront:

- **CoreHaptics cannot run in background.** When app backgrounded or device locked, haptic stops. **Solution:** *dim mode* — app foreground, screen near-black session view, `isIdleTimerDisabled = true`. Real locked-screen usage → Apple Watch (Phase 2).
- **Audio can run in background** via `UIBackgroundModes: audio` + AVAudioSession `.playback`. Only enable if actually playing audio; silent audio-loop tricks risk App Store rejection.
- **AVAudioSession config:** always `.mixWithOthers` + `.duckOthers`. We don't steal the user's music.
- **Notifications can't drive workouts**, only remind.

---

## 7. Quality Bar (Every PR)

- **Dynamic Type:** layouts unbroken up to Accessibility largest size. Use `DesignSystem` tokens, never bare `font(.system(size:))`
- **VoiceOver:** every interactive element labeled. Phase transitions announced via `accessibilityAnnouncement`
- **Reduce Motion:** breathing animation stops, replaced by text/color transition
- **Dark mode:** all screens work
- **Localization:** all user-facing strings in String Catalog (`.xcstrings`). No hardcoded strings in code
- **Core tests:** new domain logic gets a test. Use `TestClock`

---

## 8. Git & Collaboration

- **Branch naming:** `feat/workout-engine`, `fix/haptic-timing`, `chore/ci`
- **Commits:** Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- **PR size:** small — one feature, ideally <400 lines. If bigger, split
- **Review:** every PR needs eyes. CI green before merge
- **Merge strategy:** squash

**Ownership (to avoid conflicts):**
- **Dev A:** `Core`, `Persistence`, `RemoteContent`, `Notifications`, test
- **Dev B:** `DesignSystem`, `Features`, `Feedback`, `Purchases`, `Analytics`, `App`

---

## 9. Subagent Auto-Selection

Claude Code will route work to specialized agents based on context. Common mappings:

| Task | Agent(s) | Why |
|---|---|---|
| New SwiftUI screen | `frontend-developer`, `ui-designer` | UI/UX expertise |
| Workout engine refactor | `refactoring-specialist`, `performance-engineer` | Corelogic + timing |
| RevenueCat integration issue | `payment-integration`, `dependency-manager` | SDK expertise |
| Code review on diff | `code-reviewer` | Catches bugs, regressions |
| Architecture decision | `architect-reviewer`, `api-designer` | System design |
| Test coverage audit | `qa-expert`, `test-automator` | Quality gates |
| Performance bottleneck | `performance-engineer`, `database-optimizer` | Latency, memory |
| Security audit | `security-auditor`, `compliance-auditor` | GDPR/privacy, health compliance |
| Documentation | `documentation-engineer`, `technical-writer` | Clarity, completeness |
| Accessibility check | `accessibility-tester` | WCAG, VoiceOver, Dynamic Type |
| Swift version/language update | `swift-expert` | Language features, patterns |
| CI/CD pipeline | `devops-engineer`, `deployment-engineer` | Build automation |

When asking for help, Claude will pick the right agent(s) automatically. If you want a specific agent, name it: "ask the swift-expert about actor isolation patterns."

---

## 10. Health & Compliance Notes

- **Scope:** exercise guidance, progress tracking, reminders. No diagnosis, no treatment claims.
- **Data privacy:** on-device only. No health data to servers.
- **GDPR/CCPA:** minimal surface. No accounts, no email tracking. If you add telemetry, document it.
- **App Store category:** Health. Expect review scrutiny on any medical-sounding text.
- **Localization risk:** when translating exercise text, ensure no idiom accidentally claims treatment.

**If in doubt: ask. Don't guess on health/compliance topics.**

---

## 11. Claude Code Workflow

- **Read first, then plan, then code.** Scan the relevant modules, outline an approach, get alignment.
- **One feature per PR.** No "while I'm at it" fixes.
- **No everything-in-one-file.** New type = new file, correct package.
- **No `ContentView` pattern.** Screens are `Features/YourScreen/YourScreenView.swift`, not generic names.
- **Uncertain product decisions?** Ask instead of guessing.
- **Touching section 1 constraints?** Warn before coding.
- **When done:** clearly state what changed and what you didn't test.

---

## 12. Appendix: Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` (root) | Product decisions, architecture, domain rules |
| `.claude/agents/CLAUDE.md` | This file — subagent rules |
| `.claude/agents/README.md` | Agent role map and responsibilities |
| `project.yml` | XcodeGen build config |
| `content.json` | Exercise levels, timings, text (versioned, remote) |
| `String Catalog (.xcstrings)` | All user-facing text, multi-language |
| `CODEOWNERS` | Package ownership for PR review assignment |

---

**Last updated:** 2026-08-14
**Format:** UTF-8, LF line endings, no trailing whitespace
