---
applyTo: "profiles/**"
description: "Use when: editing profile manifests, deciding what gets linked, changing full or hypr-minimal profile contents, or reviewing manifest-driven linking behavior."
---

# Manifest Instructions

- `profiles/*.list` is the source of truth for what gets linked; do not assume recursive linking from repository folders.
- Keep manifest edits minimal and aligned with the target profile's intent.
- If a manifest entry points to install behavior or special handling, inspect `scripts/` before changing it.
- If manifest changes alter user-visible profile behavior, check whether `README.md` also needs to be updated.
- Treat `config/optional/` as excluded from active profiles unless the user explicitly asks to link optional tools.
