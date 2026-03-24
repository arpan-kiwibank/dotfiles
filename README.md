# Arpan's dotfiles


## Overview


## Supported OS

- Ubuntu

## Install

1. Download

   ```bash
   git clone https://github.com/arpan-kiwibank/dotfiles
   cd dotfiles
   ```

1. Install

   ```bash
   ./setup.sh
   ```

### Profile modes

The installer supports profile-driven linking to reduce redundant tool configs while keeping default behavior unchanged.

- `full` (default): links all dotfiles and tool configs.
- `hypr-minimal`: links a Hyprland-focused set and skips overlapping legacy configs (i3/river/wayfire/qtile, old launchers, legacy IME/tool managers).

Examples:

```bash
# default profile
./setup.sh

# reduced profile for a cleaner Hyprland setup
./setup.sh --profile hypr-minimal

# keep legacy configs even in minimal profile
./setup.sh --profile hypr-minimal --with-legacy
```

### Dry-run verification

Use dry-run mode to verify install, link, and update phases without changing your system:

```bash
./setup.sh --dry-run
```

You can also run a single phase:

```bash
./scripts/initiate.sh link --dry-run
./scripts/initiate.sh update --dry-run
```

### Controlled real link test (isolated HOME)

Run the link phase against a temporary HOME directory to validate actual symlink creation safely:

```bash
tmp_root=/tmp/dotfiles-real-link
mkdir -p "$tmp_root/home/.config" "$tmp_root/cache"
HOME="$tmp_root/home" XDG_CACHE_HOME="$tmp_root/cache" ./scripts/initiate.sh link
```

### Neovim nightly notes

The bootstrap script installs Neovim nightly from GitHub release assets and currently supports Linux architectures:

- x86_64 (amd64)
- arm64 (aarch64)

1. zsh plugin install

   ```bash
   exec zsh
   ```

1. neovim plugin install

   ```bash
   nvim --headless -c 'Lazy! sync' -c 'qall'
   ```

1. Enjoy!


## Components

- zsh
- neovim
- wezterm

## Usage

### Frequently used shortcuts

#### wezterm

| key                  | action        |
| -------------------- | ------------- |
| Alt-h/j/k/l          | switch window |
| Alt-j                | close window  |
| Alt-k                | create window |
| S-Up/Down/Left/Right | switch pane   |



