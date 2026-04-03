# Cleanup Subagent

Reverts temporary changes and tears down test infrastructure.

## Invocation

```
Task tool:
  subagent_type: "shell"
  model: "fast"
```

## Input Variables

- `{API_KEY_PLACEHOLDER}` -- the placeholder string to restore (typically `API_KEY`)

## Prompt

```
You are cleaning up after the Amplitude Flutter SDK E2E test.
Cap your response to 1000 characters.

Tasks:
1. Revert the API key in example/lib/main.dart:
   Read the file, replace the current API key with '{API_KEY_PLACEHOLDER}' in
   the MyApp() constructor call. Use StrReplace.

2. Reset flutter config:
   Shell: flutter config --no-enable-swift-package-manager

3. Kill any background python HTTP servers on port 8080:
   Shell: lsof -ti:8080 | xargs kill -9 2>/dev/null || true

4. Clean up build logs:
   Shell: rm -rf /tmp/test-sdk-build-*.log
```

## Expected Output

```yaml
cleanup_status: pass | partial
tasks:
  - task: revert_api_key
    status: pass | fail
  - task: reset_flutter_config
    status: pass | fail
  - task: kill_servers
    status: pass | fail
```
