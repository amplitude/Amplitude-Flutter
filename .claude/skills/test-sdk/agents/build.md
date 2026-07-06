# Build Subagent

Builds the Flutter example app for selected platforms.

## Invocation

```
Task tool:
  subagent_type: "shell"
  model: "fast"
```

## Input Variables

- `{REPO_ROOT}` -- absolute path to the repository root
- `{PLATFORMS}` -- comma-separated list of selected platform IDs
- `{SKILL_ROOT}` -- absolute path to the skill directory

## Self-Read References

Read this file before building:
- `{SKILL_ROOT}/platform-flutter.md` -- platform build commands, paths, known issues

## Prompt

```
You are building the Amplitude Flutter example app for E2E testing.
Working directory: {REPO_ROOT}/example

IMPORTANT: Cap your response to 3000 characters. Save build logs to
/tmp/test-sdk-build-{platform}.log for each platform.

Selected platforms: {PLATFORMS}

Step 1: Read `{SKILL_ROOT}/platform-flutter.md` for platform-specific build
commands, output paths, and known issues.

All flutter build commands MUST include --dart-define-from-file=.env to inject
the Amplitude API key at compile time. The .env file is in the working directory.
Do NOT read, echo, or log the contents of the .env file.

Key rules:
- iOS SPM and iOS CocoaPods builds MUST be sequential (flutter config is global)
- Run `flutter clean && flutter pub get` between iOS build variants
- Android and Web builds can run alongside iOS
- If a build fails, log the error and continue with remaining platforms
```

## Expected Output

```yaml
build_status: pass | partial | fail
platforms:
  - id: ios-spm
    status: pass | fail
    artifact: "/path/to/Runner.app"
    log: "/tmp/test-sdk-build-ios-spm.log"
  - id: android
    status: pass | fail
    artifact: "/path/to/app-debug.apk"
    log: "/tmp/test-sdk-build-android.log"
```
