# Amplitude Project Configuration

Project-specific Amplitude settings for event verification. This file is a
**template** -- the skill reads actual values from
`example/amplitude-project.local.yaml` (gitignored).

## Project Details

Non-secret project identifiers. On first run, the skill asks for these values
and creates `example/amplitude-project.local.yaml` automatically.

Expected YAML format:

```yaml
project_id: 697899
project_name: "My Test Project"
org_name: "My Org"
org_id: 255821
```

## API Key

The API key lives in `example/.env` (gitignored, never read by the agent).
It is injected at compile time via `--dart-define-from-file=.env`.

Expected format:

```
AMPLITUDE_API_KEY=<32-char-hex-key>
```

## MCP Server

- **Server name**: `plugin-amplitude-amplitude`
- **Auth tool**: `mcp_auth` (call if `get_context` fails)
- **Verification tool**: `search` with `projectId` from local YAML

## Default Tracking

The example app uses `DefaultTrackingOptions.all()`, which automatically sends:

- `Application Installed` -- first launch
- `Application Opened` -- every launch
- `Application Updated` -- after version change
- `Application Backgrounded` -- when app goes to background

These events appear in Amplitude without any user interaction. They can be used
as a baseline to confirm the SDK is initialized and sending data.

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
   top-left dropdown. Select the org matching your expected org.

5. **Trigger `mcp_auth`** by calling:

```
CallMcpTool server="plugin-amplitude-amplitude" toolName="mcp_auth"
```

6. **Verify** by calling `get_context` and checking that the org matches
   the expected org name and ID from your local YAML.
