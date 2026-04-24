# AGENTS.md

## Codex Operating Model

This repository is operated as a Codex-native migration project.
Codex is also the primary development environment and implementation engine for this repository.

Primary intent:
- analyze the source repository in `D:\ClaudeCode-StartUpTools-New`
- preserve reusable architecture, governance, and verification patterns
- reimplement only the parts that make sense for Codex
- build and evolve the target repository through Codex-first development workflows

Execution priorities:
1. monitor
2. build
3. verify
4. improve

Core rules:
- prefer small, reversible changes
- do not claim feature parity unless verified
- translate concepts before translating files
- keep source-specific assumptions documented in migration notes
- add tests when migrating executable behavior

Stop conditions:
- same blocking error repeated 3 times
- unknown external dependency blocks migration
- feature depends on Claude-only runtime behavior with no safe Codex substitute

Deliverable standard:
- every migrated feature should have
  - purpose
  - source mapping
  - Codex adaptation notes
  - verification method
