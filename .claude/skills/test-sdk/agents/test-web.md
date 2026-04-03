# Web Test Subagent

Executes a test flow in a web browser via cursor-ide-browser MCP.

## Invocation

```
Task tool:
  subagent_type: "generalPurpose"
  model: "fast"
```

## Input Variables

- `{REPO_ROOT}` -- absolute path to the repository root
- `{TEST_FLOW_STEPS}` -- steps from the selected test flow in `test-flows.md`

## Prompt

```
You are testing the Amplitude Flutter SDK in a web browser.
Cap your response to 3000 characters. Save screenshots to /tmp/test-sdk/.

First, start the web server:
  Shell: cd {REPO_ROOT}/example/build/web && python3 -m http.server 8080
  (run in background with block_until_ms: 0)

Then interact via cursor-ide-browser MCP:

1. Navigate: browser_navigate to http://localhost:8080
2. Take a snapshot: browser_snapshot to get element refs
3. Handle any browser popups/dialogs if present

4. Execute each step in the test flow:
   {TEST_FLOW_STEPS}
   a. Use browser_snapshot to find the target element
   b. Click it using browser_click with the element ref
   c. If the action fails, RETRY ONCE (take a fresh snapshot, re-locate,
      click again). If it fails a second time, mark step as failed.
   d. Take a screenshot after each step (browser_take_screenshot)

5. After all steps, kill the python server.
```

## Expected Output

```yaml
test_status: pass | partial | fail
platform: web
steps:
  - step: 1
    action: "Click 'Send Event'"
    status: pass | fail
    retried: false
    screenshot: "/tmp/test-sdk/web-step-1.png"
expected_events:
  - event_type: "Dart Click"
    count: 1
```
