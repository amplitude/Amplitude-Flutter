# Usage Examples

How to invoke the test-sdk skill in different scenarios.

## Default Smoke Test

> User: "Test the SDK on all platforms"

The agent:
1. Reads SKILL.md, detects test-sdk skill match
2. Runs pre-flight (subagent checks Flutter, devices, Amplitude MCP, API key)
3. Asks: "Default smoke test or customize?" -- user picks default
4. Builds iOS SPM, iOS CocoaPods, Android, Web (subagent)
5. Launches 4 parallel test subagents with the basic-event flow
6. Verifies "Dart Click" events in Amplitude (subagent)
7. Cleans up (reverts API key, resets config)
8. Presents results table

Total user interaction: 1 question (default vs customize).

## iOS-Only Quick Test

> User: "Quick smoke test on iOS SPM only"

The agent:
1. Reads SKILL.md
2. Runs pre-flight
3. Asks: "Default or customize?" -- user picks customize
4. Asks: "Which platforms?" -- user selects only "iOS (Swift Package Manager)"
5. Asks: "Which test flow?" -- user picks basic-event
6. Builds iOS SPM only
7. Runs test on one simulator
8. Verifies events
9. Cleans up

## Full Smoke Test

> User: "Run the full smoke test on Android"

The agent:
1. Reads SKILL.md
2. Runs pre-flight
3. Asks: "Default or customize?" -- user picks customize
4. Asks: "Which platforms?" -- user selects only "Android"
5. Asks: "Which test flow?" -- user picks full-smoke
6. Builds Android APK
7. Runs all flows (basic-event, identify, revenue, set-group) on emulator
8. Verifies all expected events in Amplitude
9. Cleans up

## Testing a New Feature

> User: "I added a new setOptOut method, test it on iOS and Android"

The agent:
1. Reads SKILL.md
2. Runs pre-flight
3. Asks: "Default or customize?" -- user picks customize
4. Asks: "Which platforms?" -- user selects iOS SPM + Android
5. Asks: "Which test flow?" -- user picks "Custom -- I'll describe what to test"
6. Agent asks: "Describe the test and whether the example app needs changes"
7. User: "Tap 'Opt Out', send an event, flush, then verify no events arrive.
   Then tap 'Opt In', send an event, flush, verify events arrive. The buttons
   are already in the example app."
8. Agent builds and tests with the custom flow
9. Verifies events in Amplitude

## Pre-flight Failure Example

> User: "Test the SDK"

Pre-flight subagent returns:

```yaml
preflight_status: fail
checks:
  - name: amplitude_mcp
    status: fail
    detail: "Authenticated to wrong org"
```

The agent stops and reports:

> Pre-flight failed: Amplitude MCP is authenticated to the wrong organization.
> Follow the token clearing instructions in `amplitude-project.md` to fix.

## Partial Build Failure Example

If iOS CocoaPods build fails but iOS SPM and Android succeed:

```
## E2E Test Results

| Platform      | Build  | Test   | Events Verified |
|---------------|--------|--------|-----------------|
| iOS SPM       | pass   | pass   | yes             |
| iOS CocoaPods | FAIL   | skip   | skip            |
| Android       | pass   | pass   | yes             |

Build log: /tmp/test-sdk-build-ios-cocoapods.log
```
