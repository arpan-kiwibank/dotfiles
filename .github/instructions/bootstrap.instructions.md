---
applyTo: "setup.sh,scripts/**"
description: "Use when: changing bootstrap scripts, setup flow, install/update/link logic, dry-run behavior, package installation, or linker mechanics in setup.sh and scripts/."
---

# Bootstrap Instructions

- Start with `setup.sh` or the specific file in `scripts/` named by the task.
- Treat bootstrap changes as behavior changes to install, update, link, dry-run, or validation flow.
- If install behavior or linked paths change, inspect `profiles/` before editing.
- Keep fixes in the bootstrap layer; do not rewrite config files to compensate for script defects unless that is clearly the correct fix.
- Prefer validating bootstrap or linker changes with dry-run or the update harness when practical.
- Do not broaden bootstrap scope into shell, desktop, or editor folders unless the task explicitly crosses those domains.
