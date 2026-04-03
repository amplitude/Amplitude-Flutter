# Mobile Test Subagent

Executes a test flow on an iOS simulator or Android emulator via mobile MCP.

## Invocation

```
Task tool:
  subagent_type: "generalPurpose"
  model: "fast"
```

Launch one instance per mobile platform. All instances run in parallel.

## Input Variables

- `{PLATFORM}` -- platform ID (e.g., `ios-spm`, `android`)
- `{DEVICE_ID}` -- simulator/emulator device ID from pre-flight
- `{ARTIFACT_PATH}` -- path to built app (.app or .apk)
- `{APP_ID}` -- bundle ID or package name
- `{TEST_FLOW_STEPS}` -- steps from the selected test flow in `test-flows.md`

## Prompt

```
You are testing the Amplitude Flutter SDK on a mobile device.
Cap your response to 3000 characters. Save screenshots to /tmp/test-sdk/.

Platform: {PLATFORM}
Device ID: {DEVICE_ID}
App path: {ARTIFACT_PATH}
Package/Bundle ID: {APP_ID}

Test flow to execute:
{TEST_FLOW_STEPS}

Instructions:
1. Install the app: CallMcpTool server="user-mobile-mcp" tool="mobile_install_app"
   args: { appPath: "{ARTIFACT_PATH}", deviceId: "{DEVICE_ID}" }

2. Launch the app: CallMcpTool server="user-mobile-mcp" tool="mobile_launch_app"
   args: { packageName: "{APP_ID}", deviceId: "{DEVICE_ID}" }

3. Wait 3 seconds for app to initialize, then take a screenshot.

4. Handle native dialogs: If you see a system dialog (e.g., tracking
   transparency, permissions), dismiss or accept it by tapping the
   appropriate button. Use mobile_list_elements_on_screen to find the
   dialog buttons.

5. Execute each step in the test flow:
   a. Use mobile_list_elements_on_screen to find the target element
   b. Tap it using mobile_click_on_screen_at_coordinates
   c. If the action fails, RETRY ONCE (take a fresh element list, re-locate,
      tap again). If it fails a second time, mark step as failed and continue.
   d. Take a screenshot after each step

6. After all steps, take a final screenshot.
```

## Expected Output

```yaml
test_status: pass | partial | fail
platform: "{PLATFORM}"
device: "{DEVICE_ID}"
steps:
  - step: 1
    action: "Tap 'Send Event'"
    status: pass | fail
    retried: false
    screenshot: "/tmp/test-sdk/{PLATFORM}-step-1.png"
  - step: 2
    action: "Tap 'Flush Events'"
    status: pass | fail
    retried: true
    screenshot: "/tmp/test-sdk/{PLATFORM}-step-2.png"
expected_events:
  - event_type: "Dart Click"
    count: 1
```
