# Source Inventory

Initial observations from `D:\ClaudeCode-StartUpTools-New`:

- source repo is documentation-heavy
- reusable logic is concentrated in `scripts/lib` and `scripts/main`
- source contains large Claude-specific template and instruction trees
- tests already exist and can guide selective migration

High-level counts observed during initial audit:

- non-`node_modules` files: about 382
- markdown files: 263
- PowerShell files: 86
- config-like files: 17

## Immediate Focus

1. map root docs to Codex-native equivalents
2. classify `scripts/lib`
3. classify `tests`
4. decide what to ignore from `Claude/templates`

## Migrated Slice

- `scripts/lib/TokenBudget.psm1`
  - classification: migrate with adaptation
  - reason: budgeting logic is generic, but repository-root detection was simplified for Codex-local execution
  - verification: `tests/unit/TokenBudget.Tests.ps1`
