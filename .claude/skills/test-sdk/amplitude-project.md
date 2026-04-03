# Amplitude Project Configuration

Project-specific Amplitude settings for event verification. Swap this file to
test against a different Amplitude project.

## Project Details

| Field          | Value                                     |
|----------------|-------------------------------------------|
| Project Name   | `<YOUR_PROJECT_NAME>`                     |
| Project ID     | `<YOUR_PROJECT_ID>`                       |
| API Key        | `<YOUR_API_KEY>`                          |
| Expected Org   | `<YOUR_ORG_NAME>`                         |
| Org ID         | `<YOUR_ORG_ID>`                           |

> **Setup**: Copy this file to `amplitude-project.local.md`, fill in your
> values, and add `amplitude-project.local.md` to `.gitignore`. The skill
> will check for the `.local` variant first, falling back to this template.

## MCP Server

- **Server name**: `plugin-amplitude-amplitude`
- **Auth tool**: `mcp_auth` (call if `get_context` fails)
- **Verification tool**: `search` with `projectId: <YOUR_PROJECT_ID>`

## Default Tracking

The example app uses `DefaultTrackingOptions.all()`, which automatically sends:

- `Application Installed` -- first launch
- `Application Opened` -- every launch
- `Application Updated` -- after version change
- `Application Backgrounded` -- when app goes to background

These events appear in Amplitude without any user interaction. They can be used
as a baseline to confirm the SDK is initialized and sending data.

## API Key Validation

During pre-flight, check `example/lib/main.dart` for the API key:

- **Pass**: Contains the real API key (matches `<YOUR_API_KEY>` from this file)
- **Warn (placeholder)**: Contains `API_KEY` literal -- events will not reach
  Amplitude. The agent should offer to set the real key.
- **Warn (different key)**: Contains a different key -- events will go to a
  different project. Alert the user but do not block.

## Token Clearing Instructions

If the Amplitude MCP authenticates to the wrong organization, the cached OAuth
token needs to be cleared manually. This happens when the user has multiple
Amplitude orgs and the MCP cached a token for the wrong one.

### Steps to fix

1. **Quit Cursor completely** (Cmd+Q, not just close window)

2. **Delete the cached MCP token**:

```bash
sqlite3 ~/Library/Application\ Support/Cursor/User/globalStorage/state.vscdb \
  "DELETE FROM ItemTable WHERE key LIKE '%amplitude%';"
```

3. **Open Cursor** and start a new chat

4. **Before triggering `mcp_auth`**, log into the correct Amplitude org in
   your browser at https://app.amplitude.com -- the org selector is in the
   top-left dropdown. Select the org matching `<YOUR_ORG_NAME>`.

5. **Trigger `mcp_auth`** by calling:

```
CallMcpTool server="plugin-amplitude-amplitude" toolName="mcp_auth"
```

6. **Verify** by calling `get_context` and checking that the org matches
   `<YOUR_ORG_NAME>` (ID `<YOUR_ORG_ID>`).
