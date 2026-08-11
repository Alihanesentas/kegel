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
