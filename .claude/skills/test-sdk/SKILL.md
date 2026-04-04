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
  version: "1.3.0"
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

## Architecture: Self-Reading Subagents

Subagent instruction files live in `agents/`. The main agent does NOT read
these files. Instead, each phase launches a subagent with a compact delegation
prompt that tells it to read its own instruction file. This keeps the main
agent's context lean (~130 lines vs ~930 lines).

Reference files (read by subagents, not the main agent):

- `platform-flutter.md` -- build commands, paths, app IDs, known issues
- `amplitude-project.md` -- Amplitude project config template, token clearing
- `test-flows.md` -- structured test scenarios with UI elements and expected events

### Delegation prompt contract

Every subagent delegation prompt follows this structure:

1. "Step 1: Read `{SKILL_ROOT}/agents/<file>.md` for your full instructions."
2. Additional reference files to read.
3. Variable values (short runtime strings only).
4. "Return the expected YAML output format defined in the instruction file."
5. "If any file is not found, return: status: fail, error: 'File not found: <path>'."

`SKILL_ROOT` is the absolute path to `.claude/skills/test-sdk` in the current
workspace. Determine it once at the start of the run.

## Phase 1: Pre-flight

Launch a `fast` generalPurpose subagent with this prompt:

  "Step 1: Read `{SKILL_ROOT}/agents/preflight.md` for your full instructions.
   Step 2: Read `{SKILL_ROOT}/amplitude-project.md` for token-clearing instructions.
   Variable values: REPO_ROOT={absolute repo path}, SKILL_ROOT={skill root path}.
   Follow the instructions, fill variables, and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

**Result handling:**
- `preflight_status: fail` -- stop, report failures. Do not proceed.
- `config_needed: true` -- the local project config is missing. Ask the user
  in chat for their Amplitude project ID, org name, and org ID. Create
  `example/amplitude-project.local.yaml` with those values. Then proceed.
- Any `warn` -- show warnings, ask user to continue via AskQuestion.
- All `pass` -- proceed to Phase 2. Save `project_config` from output for
  use in Phase 5.

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

Launch a `fast` shell subagent with this prompt:

  "Step 1: Read `{SKILL_ROOT}/agents/build.md` for your full instructions.
   Step 2: Read `{SKILL_ROOT}/platform-flutter.md` for platform build commands.
   Variable values: REPO_ROOT={absolute repo path}, PLATFORMS={selected platforms},
   SKILL_ROOT={skill root path}.
   Follow the instructions and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

The API key is injected at compile time via `--dart-define-from-file=.env`
(already configured in the build commands). No file modification needed.

**Result handling:**
- All built: proceed to Phase 4 with all platforms.
- Some failed: proceed with passing platforms, note failures.
- All failed: stop and report.

## Phase 4: Test

Launch subagents **in parallel** for each platform:

**For each mobile platform** (iOS/Android), launch a `fast` generalPurpose subagent:

  "Step 1: Read `{SKILL_ROOT}/agents/test-mobile.md` for your full instructions.
   Step 2: Read `{SKILL_ROOT}/test-flows.md` for test scenarios.
   Variable values: PLATFORM={platform id}, DEVICE_ID={device id},
   ARTIFACT_PATH={built app path}, APP_ID={bundle/package id},
   TEST_FLOW_NAME={selected flow name}, SKILL_ROOT={skill root path}.
   Follow the instructions and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

**For Web**, launch a `fast` generalPurpose subagent:

  "Step 1: Read `{SKILL_ROOT}/agents/test-web.md` for your full instructions.
   Step 2: Read `{SKILL_ROOT}/test-flows.md` for test scenarios.
   Variable values: REPO_ROOT={absolute repo path},
   TEST_FLOW_NAME={selected flow name}, SKILL_ROOT={skill root path}.
   Follow the instructions and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

**Result handling:** Collect all subagent results. Merge `expected_events`.

## Phase 5: Verify

Launch a `fast` generalPurpose subagent with this prompt:

  "Step 1: Read `{SKILL_ROOT}/agents/verify.md` for your full instructions.
   Variable values: PROJECT_ID={id from local yaml},
   EXPECTED_EVENTS_YAML={merged events yaml from Phase 4},
   SKILL_ROOT={skill root path}.
   Follow the instructions and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

**Result handling:**
- All found: report success.
- Some missing after 5 min: report as "unverified" (not "failed").

## Phase 6: Cleanup

Launch a `fast` shell subagent with this prompt:

  "Step 1: Read `{SKILL_ROOT}/agents/cleanup.md` for your full instructions.
   Variable values: PLATFORMS_TESTED={comma-separated platforms from Phase 2},
   SKILL_ROOT={skill root path}.
   Follow the instructions and return the expected YAML output.
   If any file is not found, return: status: fail, error: 'File not found: <path>'."

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
- **Instruction file not found**: treat as phase failure, report the missing path.
- **MCP connection loss**: retry once, then skip with explanation.
- **Build failure**: skip that platform's test, continue others.
- **Device crash**: capture last screenshot, report partial.
- **Amplitude delay**: poll up to 5 min with exponential backoff.
- **Native dialogs**: subagents dismiss/accept. If unhandled, screenshot + fail step.
