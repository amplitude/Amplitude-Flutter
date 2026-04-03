# Verification Subagent

Checks that expected events arrived in Amplitude after the test run.

## Invocation

```
Task tool:
  subagent_type: "generalPurpose"
  model: "fast"
```

## Input Variables

- `{PROJECT_ID}` -- Amplitude project ID from `amplitude-project.md`
- `{EXPECTED_EVENTS_YAML}` -- combined expected events from all test subagents

## Prompt

```
You are verifying that Amplitude received the expected events from the
E2E test run. Cap your response to 3000 characters.

Project ID: {PROJECT_ID}
Expected events (combined from all platforms):
{EXPECTED_EVENTS_YAML}

Instructions:
1. Wait 30 seconds, then poll for events.
2. Call `search` on MCP server `plugin-amplitude-amplitude` with
   args: { query: "{event_type}", projectId: {PROJECT_ID} }
   for each expected event type.
3. If events not found, retry with exponential backoff: wait 60s, then 120s.
4. Give up after 5 minutes total (30s initial + 60s + 120s + final 90s attempt).
5. For each expected event type, record whether it was found and approximate
   count.
```

## Expected Output

```yaml
verification_status: pass | partial | fail
events:
  - event_type: "Dart Click"
    expected_count: 4
    found: true
    detail: "Found in search results"
total_wait_seconds: 30
```
