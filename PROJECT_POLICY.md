# PROJECT_POLICY

## Purpose

This repository exists to rebuild the useful parts of
`D:\ClaudeCode-StartUpTools-New` into a Codex-native startup toolkit.

Codex is the primary development environment and implementation agent for this project.

## Core Principles

- build for Codex first, not for cross-tool appearance parity
- migrate capabilities, not entire directory trees
- prefer small verified increments over large bulk imports
- keep documentation, scripts, and tests in sync
- remove or replace source behaviors that depend on Claude-only runtime features
- document every meaningful adaptation from the source repository

## Development Standard

- every feature should have a clear purpose before implementation
- executable behavior should be paired with verification
- docs should describe how the Codex version works, not only how the source version worked
- if a feature cannot be faithfully migrated, define the supported Codex behavior explicitly

## Migration Classification Rules

Each source artifact should be classified as one of the following:

- migrate directly
- migrate with adaptation
- replace with Codex-native implementation
- archive as reference only
- do not migrate

## Working Model

Preferred sequence:

1. monitor the current state
2. define a narrow migration slice
3. implement the Codex-native version
4. verify behavior
5. record migration notes

## Quality Bar

A migration slice is considered acceptable when:

- its purpose is documented
- its source mapping is known
- its target behavior is explicit
- tests or verification steps are recorded
- no unsupported parity claim is made

## Repository Layout Intent

Root files:
- policy, truth, onboarding, and summary files only

`docs/`
- analysis, migration notes, operating guides, and design references

`scripts/`
- Codex-oriented automation and reusable implementation helpers

`tests/`
- verification for migrated executable behavior

`.codex/`
- Codex configuration and project-specific agent setup

## Non-Goals

- full behavioral emulation of Claude-specific hooks
- exact reproduction of vendor-specific command ecosystems
- copying large source trees without redesign

## Review Rule

If a change makes the target repository less Codex-native just to preserve superficial parity with the source repository, prefer redesign over compatibility.
