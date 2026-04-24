# SOURCE_OF_TRUTH

This file defines the canonical sources for project intent, migration scope, and development rules.

## Primary Canonical Files

1. `PROJECT_POLICY.md`
   - the top-level operating policy for this repository
2. `AGENTS.md`
   - agent behavior, execution order, and delivery rules
3. `.codex/config.toml`
   - Codex-oriented project configuration
4. `docs/migration/migration-master-plan.md`
   - migration scope, workstreams, and done criteria
5. `docs/analysis/source-inventory.md`
   - current understanding of the source repository and migration inputs

## Source Repository Reference

The source repository for migration is:

- `D:\ClaudeCode-StartUpTools-New`

Source files are reference inputs, not automatic truth for the target repository.
When the source and target differ, the target repository's Codex-native rules take priority unless an intentional migration note says otherwise.

## Decision Priority

When conflicts appear, resolve them in this order:

1. `PROJECT_POLICY.md`
2. `AGENTS.md`
3. verified target implementation
4. target tests
5. migration plan and analysis docs
6. source repository artifacts

## Change Control

Update this file when:

- a new root policy file becomes authoritative
- a migration area changes ownership
- a former source-of-truth file is deprecated

Do not introduce new root guidance documents without linking them here.
