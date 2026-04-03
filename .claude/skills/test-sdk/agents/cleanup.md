# Cleanup Subagent

Tears down test infrastructure after E2E tests complete.

## Invocation

```
Task tool:
  subagent_type: "shell"
  model: "fast"
```

## Input Variables

None.

## Prompt

```
You are cleaning up after the Amplitude Flutter SDK E2E test.
Cap your response to 1000 characters.

Tasks:
1. Reset flutter config:
   Shell: flutter config --no-enable-swift-package-manager

2. Kill any background python HTTP servers on port 8080:
   Shell: lsof -ti:8080 | xargs kill -9 2>/dev/null || true

3. Clean up build logs:
   Shell: rm -rf /tmp/test-sdk-build-*.log
```

## Expected Output

```yaml
cleanup_status: pass | partial
tasks:
  - task: reset_flutter_config
    status: pass | fail
  - task: kill_servers
    status: pass | fail
  - task: clean_logs
    status: pass | fail
```
