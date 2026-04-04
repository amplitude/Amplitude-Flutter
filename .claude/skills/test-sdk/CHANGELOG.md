# Changelog -- test-sdk

## 1.3.0 (2026-04-04)

- Switch to self-reading subagent pattern: subagents read their own instruction
  files instead of receiving them inline from the orchestrator. Reduces main
  agent context by ~600 lines per run.
- Add `{SKILL_ROOT}` variable for unambiguous file paths across all subagents.
- Add structured error handling for missing instruction files.
- Fix: cleanup no longer unconditionally disables SPM. Only resets flutter
  config when iOS platforms were actually tested (SPM config is global and
  persists across sessions).
- Add `{PLATFORMS_TESTED}` variable to cleanup subagent.

## 1.2.0 (2026-03-31)

- Use `--dart-define-from-file=.env` for API key injection instead of sed.
- Add `String.fromEnvironment('AMPLITUDE_API_KEY')` to example main.dart.
- Add interactive `amplitude-project.local.yaml` creation flow (ask-then-save).
- Simplify cleanup (no more API key revert in main.dart).
- Gitignore `example/.env` and `example/amplitude-project.local.yaml`.

## 1.1.0 (2026-03-31)

- Extract subagent prompts from SKILL.md into `agents/` directory.
- Reduce SKILL.md from ~469 lines to ~129 lines.
- Add `allowed-tools` to frontmatter.

## 1.0.0 (2026-03-31)

- Initial release: E2E smoke-test orchestrator for Amplitude Flutter SDK.
- Pre-flight checks, multi-platform build, mobile/web testing, Amplitude
  event verification, and cleanup.
