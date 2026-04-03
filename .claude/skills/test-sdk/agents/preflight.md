# Pre-flight Check Subagent

Validates the environment before running E2E tests.

## Invocation

```
Task tool:
  subagent_type: "generalPurpose"
  model: "fast"
```

## Input Variables

- `{REPO_ROOT}` -- absolute path to the repository root
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

3. AMPLITUDE API KEY (.env file)
   Run via Shell:
   grep -cq '^AMPLITUDE_API_KEY=[0-9a-f]\{32\}$' {REPO_ROOT}/example/.env
   Do NOT read or echo the file contents.
   - Exit 0: PASS
   - File missing: FAIL -- "Create example/.env with AMPLITUDE_API_KEY=<your-32-char-hex-key>"
   - Format invalid: FAIL -- "example/.env must contain exactly: AMPLITUDE_API_KEY=<32-char-lowercase-hex>"

4. PROJECT CONFIG (amplitude-project.local.yaml)
   Check if {REPO_ROOT}/example/amplitude-project.local.yaml exists.
   - If missing: return config_needed: true (not a FAIL -- main agent handles
     this interactively by asking the user for project ID, org name, org ID).
   - If present: read it, extract project_id, org_name, org_id. Include these
     values in your output under project_config.

5. AMPLITUDE MCP
   Call `get_context` on MCP server `plugin-amplitude-amplitude`.
   If config from check 4 is available, verify the org matches.
   If not authenticated or wrong org, FAIL and include these token-clearing
   instructions in your response:
   {TOKEN_CLEARING_INSTRUCTIONS}
   If check 4 returned config_needed, skip org verification but still confirm
   the MCP is authenticated.

6. API KEY IN MAIN.DART
   Read {REPO_ROOT}/example/lib/main.dart. Check for the pattern
   String.fromEnvironment('AMPLITUDE_API_KEY'.
   - If found: PASS
   - If not found (hardcoded key or old pattern): WARN -- "main.dart should
     use String.fromEnvironment('AMPLITUDE_API_KEY') for dart-define injection"

7. GIT BRANCH
   Run `git branch --show-current`. If on `main` or `master`: WARN.

8. MCP SCHEMA SPOT-CHECK
   Call `mobile_list_available_devices` and `get_context` -- if either tool
   name is not found on the respective server, FAIL with
   "MCP server missing expected tools -- server may have changed."
```

## Expected Output

```yaml
preflight_status: pass | fail
config_needed: true | false
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
  - name: api_key_env
    status: pass | fail
    detail: "example/.env present and valid"
  - name: project_config
    status: pass | config_needed
    detail: "..."
    project_id: 697899
    org_name: "My Org"
    org_id: 255821
  - name: amplitude_mcp
    status: pass | fail
    detail: "Authenticated to {org_name}"
  - name: api_key_main_dart
    status: pass | warn
    detail: "Uses String.fromEnvironment"
  - name: git_branch
    status: pass | warn
    detail: "On branch feature/xyz"
  - name: mcp_schema
    status: pass | fail
    detail: "All expected tools present"
```
