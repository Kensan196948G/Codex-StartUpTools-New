# Migration Master Plan

## Scope

Source:
- `D:\ClaudeCode-StartUpTools-New`

Target:
- `D:\Codex-StartUpTools-New`

## Migration Principles

- migrate capabilities, not directory trees
- separate policy, implementation, and templates
- rewrite Claude-specific runtime assumptions into Codex-oriented operations
- keep every migrated area independently reviewable
- treat Codex as the default development agent for implementing the target repository

## Workstreams

1. Operating policy
2. Documentation and source-of-truth structure
3. Reusable PowerShell and helper scripts
4. Verification and tests
5. Optional automation and backlog support

## First Pass Classification

- likely high portability
  - governance docs
  - loop definitions
  - architecture checks
  - generic script utilities
  - tests that validate reusable script behavior
- requires adaptation
  - launcher flows
  - state management
  - agent team abstractions
  - issue sync operations
- likely partial or replace
  - Claude hooks
  - Claude templates
  - Claude runtime specific commands

## Session Definition

One working session should complete one of the following:
- one document family audit
- one script module audit
- one migrated feature skeleton
- one verification pass

## Done Criteria

- source mapping recorded
- target structure decided
- migrated files written
- verification notes added

## Completed Slices

- Token budget manager
  - target module: `scripts/lib/TokenBudget.psm1`
  - verification: `tests/unit/TokenBudget.Tests.ps1`
  - migration notes: `docs/migration/token-budget-migration.md`

## Next Candidates

1. `ArchitectureCheck`
2. `Config` and schema loading
3. `WorktreeManager`
