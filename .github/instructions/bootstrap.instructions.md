---
applyTo: "setup.sh,scripts/**"
description: "Use when: changing bootstrap scripts, setup flow, install/update/link logic, dry-run behavior, package installation, or linker mechanics in setup.sh and scripts/."
---

# Bootstrap Instructions

- Start with `setup.sh` or the specific file in `scripts/` named by the task.
- If install behavior or linked paths change, inspect `profiles/` before editing.
- Never call `sudo` directly — use `run_cmd sudo <cmd>` so dry-run suppresses it.
- Always use `checkinstall <pkg>` instead of calling `apt-get`/`yum`/`pacman` directly. Exception: `ensure_prerequisites()`, which runs before `ensure_sudo()`.
- `whichdistro()` returns one of: `debian`, `redhat`, `arch`, `alpine`. Use these four values in every distro branch.
- Do not broaden scope into shell, desktop, or editor folders unless the task explicitly crosses those domains.
- Prefer validating changes with dry-run or the update harness before concluding.

## Profile switching

Profiles are manifest-driven: any `profiles/*.list` file is a valid profile.
Built-in profiles are `full` and `minimal`; custom profiles are created by
copying `profiles/TEMPLATE.list`.

On a profile switch, `home-dir.sh` calls in order:

1. `unlink_removed_entries()` — removes symlinks for entries absent in the new profile.
2. `purge_switch_residues()` — removes stale zsh compdump, XDG cache dirs, and zinit plugin dirs for removed entries.
3. `validate_no_optional_in_minimal()` — hard-aborts if `minimal.list` contains any `config/optional/` entry. Never bypass this.
4. `run_autoremove()` (in `initiate.sh`) — runs distro autoremove when `DOTFILES_PROFILE_SWITCHED=true`.

Add optional tools to `full.list` only. The state file is `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile`.

## Test harness

Run after any change to `initiate.sh`, `home-dir.sh`, `utils.sh`, `helix.sh`, or `nvim.sh`:

```bash
./scripts/test-update-harness.sh             # both profiles, mocked
./scripts/test-update-harness.sh --docker    # + in-container distro tests
./scripts/test-update-harness.sh --keep      # keep tmp dirs on success
```

The harness runs `run_manifest_lint_test()` automatically — aborts if `minimal.list` has `config/optional/` entries.

For implementation details (sudo internals, is_wsl(), idempotency, cross-platform, architecture, harness isolation): see [docs/BOOTSTRAP_INTERNALS.md](../../docs/BOOTSTRAP_INTERNALS.md).
