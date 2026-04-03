# Pre-flight Check Subagent

Validates the environment before running E2E tests.

## Invocation

```
Task tool:
  subagent_type: "generalPurpose"
  model: "fast"
```

## Input Variables

- `{API_KEY}` -- expected API key from `amplitude-project.md`
- `{EXPECTED_ORG}` -- expected Amplitude org name
- `{EXPECTED_ORG_ID}` -- expected Amplitude org ID
- `{TOKEN_CLEARING_INSTRUCTIONS}` -- steps to clear cached MCP tokens

## Prompt

```
You are running pre-flight checks for the Amplitude Flutter SDK E2E test skill.
Run each check and return a YAML summary. Cap your response to 3000 characters.

Checks (run all, report pass/fail/warn for each):

1. FLUTTER SDK
   Run `flutter --version` via Shell. Fail if not found.

2. MOBILE DEVICES
   Call `mobile_list_available_devices` on MCP server `user-mobile-mcp`.
   Fail if no iOS simulators or Android emulators are available.
   Return the list of device IDs and names.

3. AMPLITUDE MCP
   Call `get_context` on MCP server `plugin-amplitude-amplitude`.
   Expected org: {EXPECTED_ORG} (ID {EXPECTED_ORG_ID}).
   If not authenticated or wrong org, FAIL and include these token-clearing
   instructions in your response:
   {TOKEN_CLEARING_INSTRUCTIONS}

4. API KEY
   Read `example/lib/main.dart`. Check line containing `MyApp(`.
   - If it contains '{API_KEY}' (the real key): PASS
   - If it contains 'API_KEY' (placeholder): WARN -- "API key is placeholder,
     events won't reach Amplitude. Set it to {API_KEY} before testing."
   - If it contains a different key: WARN -- "API key is {found_key}, expected
     {API_KEY}. Events will go to a different project."

5. GIT BRANCH
   Run `git branch --show-current`. If on `main` or `master`: WARN.

6. MCP SCHEMA SPOT-CHECK
   Call `mobile_list_available_devices` and `get_context` -- if either tool
   name is not found on the respective server, FAIL with
   "MCP server missing expected tools -- server may have changed."
```

## Expected Output

```yaml
preflight_status: pass | fail
checks:
  - name: flutter_sdk
    status: pass | fail
    detail: "Flutter 3.x.x"
  - name: mobile_devices
    status: pass | fail
    detail: "Found N devices: ..."
    devices:
      - id: "DEVICE_ID"
        name: "iPhone 16 Pro"
        platform: ios
      - id: "DEVICE_ID"
        name: "Pixel 8 API 34"
        platform: android
  - name: amplitude_mcp
    status: pass | fail
    detail: "Authenticated to {org_name}"
  - name: api_key
    status: pass | warn
    detail: "..."
  - name: git_branch
    status: pass | warn
    detail: "On branch feature/xyz"
  - name: mcp_schema
    status: pass | fail
    detail: "All expected tools present"
```
