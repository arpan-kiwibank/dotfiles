---
applyTo: "profiles/**"
description: "Use when: editing profile manifests, deciding what gets linked, changing full or minimal profile contents, or reviewing manifest-driven linking behavior."
---

# Manifest Instructions

- `profiles/*.list` is the source of truth for what gets linked; do not assume recursive linking from repository folders.
- Any `profiles/*.list` file is a valid profile. Built-in: `full`, `minimal`. Custom profiles are created by copying `profiles/TEMPLATE.list`.
- Keep manifest edits minimal and aligned with the target profile's intent.
- If a manifest entry points to install behavior or special handling, inspect `scripts/` before changing it.
- If manifest changes alter user-visible profile behavior, check whether `README.md` also needs to be updated.
- **`config/optional/` entries must only appear in `full.list`** — never in `minimal.list`. `validate_no_optional_in_minimal()` in `home-dir.sh` enforces this at link time (hard abort), and `run_manifest_lint_test()` in the harness enforces it statically. Adding a new optional tool to `minimal.list` will cause both the harness and a live `./setup.sh` run to fail. Custom profiles may include optional entries.
- When adding a new optional tool: add its `config/optional/<name>` directory, add the entry to `full.list`, and add any zinit plugin to the `full`-only block in `pluginlist.zsh` (see shell.instructions.md). Do not touch `minimal.list`.
