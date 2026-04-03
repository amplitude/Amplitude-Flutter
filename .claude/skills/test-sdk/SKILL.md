---
name: test-sdk
description: >-
  E2E smoke-test the Amplitude Flutter SDK on real simulators/emulators.
  Runs pre-flight checks, builds for selected platforms (iOS SPM, iOS CocoaPods,
  Android, Web), executes test flows via mobile-mcp and browser MCP, then
  verifies events landed in Amplitude. Use when testing SDK changes before
  a release or after modifying native plugin code.
  Triggers on: "test the SDK", "smoke test", "test my changes", "run E2E",
  "test on all platforms", "verify events".
compatibility:
  - cursor
  - claude-code
  - codex
allowed-tools: >-
  Read Write StrReplace Task AskQuestion CallMcpTool Shell Glob Grep
metadata:
  version: "1.1.0"
  created: "2026-03-31"
---

# test-sdk

Lightweight, agent-native E2E smoke-test orchestrator for the Amplitude Flutter
SDK. All heavy work is delegated to `fast` subagents to conserve main agent
context.

## Design Rationale

This skill is a **conversation-local smoke check** -- no external test runner
dependencies (no Appium, no WDIO, no Node). It complements the CI-grade
Appium/WebdriverIO E2E harness for interactive pre-PR validation.

## Reference Files

Read these from this skill directory before starting:

- `platform-flutter.md` -- build commands, paths, app IDs, known issues
- `amplitude-project.md` -- Amplitude project config, API key, org, token clearing
- `test-flows.md` -- structured test scenarios with UI elements and expected events

Subagent prompts live in `agents/`. Read the relevant file and fill its
`{VARIABLES}` before passing as the subagent prompt.

## Phase 1: Pre-flight

Read `agents/preflight.md`. Fill variables from `amplitude-project.md`.
Launch as a `fast` generalPurpose subagent.

**Result handling:**
- `preflight_status: fail` -- stop, report failures. Do not proceed.
- Any `warn` -- show warnings, ask user to continue via AskQuestion.
- All `pass` -- proceed to Phase 2.

## Phase 2: Interactive Planning

Run on the **main agent** (not a subagent). Use AskQuestion.

**Question 1 -- run mode:**
- "Default smoke test (iOS SPM, iOS CocoaPods, Android, Web)" -- sets all 4
  platforms, flow to `basic-event`, skips to Phase 3 with zero follow-ups.
- "Customize" -- ask Questions 2 and 3.

**Question 2 -- platforms** (only if custom, multi-select):
iOS SPM, iOS CocoaPods, Android, Web.

**Question 3 -- test flow** (only if custom, single-select):
basic-event, identify, revenue, set-group, full-smoke, or "Custom -- I'll
describe it." If custom, ask what to test and whether the example app needs
modification.

## Phase 3: Build

Read `agents/build.md`. Fill `{REPO_ROOT}`, `{PLATFORMS}`, and `{PLATFORM_FLUTTER_MD_CONTENTS}`
(paste the full contents of `platform-flutter.md`). Launch as a `fast` shell
subagent.

Before launching, set the API key in `example/lib/main.dart` using StrReplace.

**Result handling:**
- All built: proceed to Phase 4 with all platforms.
- Some failed: proceed with passing platforms, note failures.
- All failed: stop and report.

## Phase 4: Test

Read `agents/test-mobile.md` (for iOS/Android) and `agents/test-web.md` (for
Web). Fill variables from build results and the selected test flow from
`test-flows.md`. Launch **all in parallel** as `fast` generalPurpose subagents.

**Result handling:** Collect all subagent results. Merge `expected_events`.

## Phase 5: Verify

Read `agents/verify.md`. Fill `{PROJECT_ID}` from `amplitude-project.md` and
`{EXPECTED_EVENTS_YAML}` from Phase 4 results. Launch as a `fast`
generalPurpose subagent.

**Result handling:**
- All found: report success.
- Some missing after 5 min: report as "unverified" (not "failed").

## Phase 6: Cleanup

Read `agents/cleanup.md`. Launch as a `fast` shell subagent.

## Final Report

Present a summary table:

```
| Platform      | Build  | Test    | Events Verified |
|---------------|--------|---------|-----------------|
| iOS SPM       | pass   | pass    | yes             |
| Android       | pass   | partial | yes             |
| Web           | pass   | pass    | yes             |
```

Include: verification wait time, cleanup status, any warnings or failures
with screenshot paths.

## Error Handling

- **Subagent timeout**: include partial results, note in report.
- **MCP connection loss**: retry once, then skip with explanation.
- **Build failure**: skip that platform's test, continue others.
- **Device crash**: capture last screenshot, report partial.
- **Amplitude delay**: poll up to 5 min with exponential backoff.
- **Native dialogs**: subagents dismiss/accept. If unhandled, screenshot + fail step.
