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

## Distro detection

`whichdistro()` in `utils.sh` maps `/etc/*-release` files to: `debian`, `redhat`, `arch`, `alpine`. Use these four values everywhere.

`checkinstall()` dispatches to the correct package manager. Always use `checkinstall` instead of calling `apt-get`/`yum`/`pacman`/`apk` directly — it handles `sudo`, RHEL EPEL/CRB setup, and package name aliases (e.g. `python-pip` → `python3-pip` on Debian).

## is_wsl() behaviour

`is_wsl()` requires **both**: `/proc/version` containing `microsoft` AND `/proc/sys/fs/binfmt_misc/WSLInterop` existing. Docker-on-WSL2 shares the kernel so the string matches inside containers, but `WSLInterop` is absent — `is_wsl()` correctly returns false in Docker.

## Script call-site conventions

- `helix.sh` and `nvim.sh` contain top-level install calls guarded by `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` — they only run when executed directly. When `initiate.sh` sources them to load functions, it **must** call the install function explicitly afterwards:
  ```bash
  source "$current_dir"/helix.sh
  install_helix || print_warning "..."
  source "$current_dir"/nvim.sh
  neovim_nightly || print_warning "..."
  ```
- Both install calls are non-fatal (`|| print_warning`) because network download failures should not abort the rest of bootstrap.

## Architecture support

Neovim (`nvim.sh`) and Helix (`helix.sh`) detect `uname -m` and download:
- `x86_64` / `amd64` → `nvim-linux-x86_64.tar.gz` / `x86_64-linux.tar.xz`
- `aarch64` / `arm64` → `nvim-linux-arm64.tar.gz` / `aarch64-linux.tar.xz`

## Bare metal vs Docker differences

| Context | sudo required | chsh works | is_wsl() | Package install |
|---|---|---|---|---|
| Bare metal (non-root) | Yes | Yes (needs auth) | `true` only on WSL2 | Needs distro pkgs first |
| Docker (root) | sudo is a no-op | Mocked in harness | Always false | Image-dependent |
| WSL2 | Yes | Yes (needs auth) | true | Same as bare metal |

For Docker testing, inject the host CA bundle for Alpine (`SSL_CERT_FILE`). Fedora and Arch have bash pre-installed in their base images and work without any package install step.

## Test harness

`scripts/test-update-harness.sh` mocks: `apt-get`, `yum`, `dnf`, `pacman`, `apk`, `curl`, `tar` (smart: creates fake extracted dirs), `chsh`, `sudo` (passthrough exec so mocked commands remain reachable within sudo calls). Run it after any change to `initiate.sh`, `utils.sh`, `helix.sh`, or `nvim.sh`.
