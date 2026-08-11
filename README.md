# PelvicApp

Architecture, product constraints, and rules live in [`CLAUDE.md`](./CLAUDE.md). Read it
before making structural changes.

## Setup

```sh
brew install xcodegen
xcodegen generate
open PelvicApp.xcodeproj
```

`PelvicApp.xcodeproj` is generated from `project.yml` and is not committed — regenerate
it any time `project.yml` or a package's file list changes.

## Subscriptions (RevenueCat)

Purchasing stays switched off until a key is provided — the app then reports
"not subscribed" and the paywall shows no plans. That's deliberate: shipping a
paywall whose button can't complete a sale is an App Store rejection.

To turn it on:

1. In **App Store Connect**, create two auto-renewable subscriptions in one
   group — monthly and yearly — and submit them for review alongside the build.
2. In the **RevenueCat dashboard**, add both products to an Offering, and have
   each grant a single entitlement named `pro`
   (`AppConfiguration.entitlementID`).
3. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig`
   (gitignored) and set `REVENUECAT_API_KEY` to the **public** SDK key
   (`appl_…`). Set that file as the project's base configuration in Xcode.
4. Test purchases in the simulator with a StoreKit configuration file, or on
   device with a Sandbox Apple ID.

The app passes its own anonymous ID as the RevenueCat App User ID, so a
reinstall restores without any sign-in. Only `Packages/Purchases` imports
RevenueCat; everything else sees `SubscriptionProviding`.

## Remote content

`Packages/Core/Sources/Core/Program/Resources/content.json` ships inside the
app and is always the fallback. Set `AppConfiguration.remoteContentURL` to a
CDN URL to enable updates without a release; until then the embedded copy is
used. Content that fails validation is ignored, so a broken publish cannot
break a running app.

## Running tests

Each package under `Packages/` is a standalone Swift package and can be tested on its
own without opening Xcode:

```sh
cd Packages/Core && swift test
```

Full app tests run through the generated Xcode scheme:

```sh
xcodegen generate
xcodebuild test -project PelvicApp.xcodeproj -scheme PelvicApp \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

## Branching and PRs

- `main` is protected — no direct pushes, no force pushes.
- Branch names: `feat/workout-engine`, `fix/haptic-timing`, `chore/ci`.
- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Keep PRs small — one feature, ideally under 400 lines.
- Every PR needs one review. CI must be green before merge.
- Merge strategy: squash.

## Module ownership

See `CODEOWNERS` and CLAUDE.md section 4.
