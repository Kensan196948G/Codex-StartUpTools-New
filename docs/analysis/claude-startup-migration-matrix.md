# Claude-StartUp Migration Matrix

## Source

- source root: `D:\Codex-StartUpTools-New\Claude-StartUp`
- intent: classify all major source areas before Codex-native migration

## Classification Summary

### Migrate directly

- `scripts/lib/TokenBudget.psm1`
- `scripts/lib/RecentProjects.ps1`
- `scripts/lib/ConfigSchema.ps1`
- `scripts/lib/ConfigLoader.ps1`
- `scripts/lib/Config.psm1`
- `scripts/lib/ArchitectureCheck.psm1`
- matching unit tests under `tests/unit`

### Migrate with adaptation

- `config/config.json.template`
  - adapt default tool and examples for Codex-first operation
- `docs/codex/*`
  - keep reusable guidance, remove references to disabled launcher paths
- `scripts/lib/MessageBus.psm1`
- `scripts/lib/SessionTabManager.psm1`
- `scripts/lib/StatuslineManager.psm1`

### Migrate directly (additional completed slice)

- `scripts/lib/LogManager.psm1`
- `scripts/lib/ErrorHandler.psm1`
- `scripts/lib/WorktreeManager.psm1`

### Reference only

- `Claude/templates/claudeos/**`
- `.claude/claudeos/**`
- `CLAUDE.md`
- `docs/claude/*`
- `docs/copilot/*`
- Linux cron launcher templates and mail scripts

### Do not migrate as-is

- `node_modules/**`
- `.worktrees/**`
- `logs/**`
- generated reports and local runtime state

## Current Codex Target Status

- migrated modules:
  - `TokenBudget`
  - `Config` family
  - `RecentProjects`
  - `ArchitectureCheck`
  - `LogManager`
  - `ErrorHandler`
  - `WorktreeManager`
- migrated tests:
  - `TokenBudget`
  - `Config`
  - `ConfigSchema`
  - `RecentProjects`
  - `ArchitectureCheck`
  - `LogManager`
  - `ErrorHandler`
  - `WorktreeManager`

## Next Migration Queue

1. `MessageBus`
2. `StatuslineManager`
3. `SessionTabManager`
4. `Worktree`-adjacent launcher utilities
5. `LauncherCommon`
