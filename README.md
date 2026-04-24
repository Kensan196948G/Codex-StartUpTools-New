# Codex StartUp Tools

Codex latest edition oriented startup toolkit workspace.

This repository is intended to be developed with Codex as the primary implementation agent.

This repository is the migration target for extracting reusable operating policies,
documentation patterns, scripts, and verification flows from
`D:\ClaudeCode-StartUpTools-New` into a Codex-native structure for ongoing development in Codex.

## Initial Goal

- rebuild the core operating model for Codex
- separate reusable logic from Claude-specific runtime assumptions
- migrate in small verified batches

## Working Rules

- do not bulk-copy the source repository into this root
- migrate by feature group with validation
- keep docs, scripts, and tests aligned
- prefer Codex-native configuration and workflows over vendor-specific compatibility shims
- perform implementation work in Codex and document any required manual follow-up

## Suggested Phases

1. Audit and classify source assets
2. Define Codex-native root structure
3. Migrate core policies and operating docs
4. Migrate reusable scripts and tests
5. Add verification and maintenance workflows
