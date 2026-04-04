# Cleanup Subagent

Tears down test infrastructure after E2E tests complete.

## Invocation

```
Task tool:
  subagent_type: "shell"
  model: "fast"
```

## Input Variables

- `{PLATFORMS_TESTED}` -- comma-separated list of platforms that were tested

## Prompt

```
You are cleaning up after the Amplitude Flutter SDK E2E test.
Cap your response to 1000 characters.

Platforms tested: {PLATFORMS_TESTED}

Tasks:
1. Reset flutter config (ONLY if iOS was tested):
   If {PLATFORMS_TESTED} contains "ios-spm" or "ios-cocoapods":
     Shell: flutter config --no-enable-swift-package-manager
   Otherwise: skip this step (flutter config is a global persistent setting
   and should not be changed unless the test run modified it).

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
    status: pass | fail | skipped
  - task: kill_servers
    status: pass | fail
  - task: clean_logs
    status: pass | fail
```
