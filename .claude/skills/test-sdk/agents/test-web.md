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
- `{TEST_FLOW_NAME}` -- name of the test flow to execute from test-flows.md
- `{SKILL_ROOT}` -- absolute path to the skill directory

## Self-Read References

Read this file before testing:
- `{SKILL_ROOT}/test-flows.md` -- find the flow matching `{TEST_FLOW_NAME}`

## Prompt

```
You are testing the Amplitude Flutter SDK in a web browser.
Cap your response to 3000 characters. Save screenshots to /tmp/test-sdk/.

Step 1: Read `{SKILL_ROOT}/test-flows.md` and find the test flow named
`{TEST_FLOW_NAME}`. Extract its steps and expected events.

Start the web server:
  Shell: cd {REPO_ROOT}/example/build/web && python3 -m http.server 8080
  (run in background with block_until_ms: 0)

Then interact via cursor-ide-browser MCP:

1. Navigate: browser_navigate to http://localhost:8080
2. Take a snapshot: browser_snapshot to get element refs
3. ACTIVATE SEMANTICS: Flutter Web renders to a canvas element, so widgets
   are invisible to browser_snapshot by default. Find the element with
   aria-label "Enable accessibility" in the snapshot and click it using
   browser_click. Wait 2 seconds for the semantics DOM tree to populate.
   Take a fresh browser_snapshot -- you should now see all Flutter widgets
   (buttons, text fields, etc.) as flt-semantics elements with ARIA labels.
   If the "Enable accessibility" button is not found, take a screenshot and
   report the issue.
4. Handle any browser popups/dialogs if present

5. Execute each step from the test flow. IMPORTANT: use refs from the
   post-semantics snapshot (step 3), not the initial snapshot (step 2).
   a. Use browser_snapshot to find the target element by its ARIA label
   b. Click it using browser_click with the element ref
   c. If the action fails, RETRY ONCE (take a fresh snapshot, re-locate,
      click again). If it fails a second time, mark step as failed.
   d. Take a screenshot after each step (browser_take_screenshot)

6. After all steps, kill the python server.
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
