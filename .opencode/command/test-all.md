---
description: Run all package tests via the test-runner subagent and summarize results.
agent: build
---

Delegate to the `test-runner` subagent: run `swift test` in every package under `Packages/`, plus the full xcodebuild scheme if Xcode is installed. Summarize per-package PASS/FAIL/SKIPPED, failure details with file:line and root-cause hints, and any toolchain gaps. Do not fix code. $ARGUMENTS
