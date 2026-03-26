# Prompt System Reference

This dotfiles repo uses [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (p10k) loaded via
zinit. This document covers the architecture, how to customise the prompt, how icons work, and
exactly what was needed to get Nerd Font icons rendering correctly on this machine.

---

## Architecture

```
zsh startup
  └── pluginlist.zsh
        ├── sets PROMPT="%~\n> "         (fallback while zinit downloads)
        └── zinit wait'!0b' → powerlevel10k
              ├── atload → powerlevel10k_atload.zsh
              │     └── sources p10k.zsh
              │           ├── sets all POWERLEVEL9K_* defaults (MODE=ascii, segments, colours)
              │           ├── sources ~/.config/zsh/p10k.local.zsh  ← machine-local overrides
              │           └── calls p10k reload  ← ONE reload with merged final state
              └── p10k takes over PROMPT / RPROMPT
```

| File | Tracked | Role |
|------|---------|------|
| `config/core/zsh/rc/pluginconfig/p10k.zsh` | ✅ repo | Repo defaults — all `POWERLEVEL9K_*` settings |
| `config/core/zsh/rc/pluginconfig/powerlevel10k_atload.zsh` | ✅ repo | Wires `p10k.zsh` into zinit's atload hook |
| `config/core/zsh/p10k.local.zsh.template` | ✅ repo | Template to copy for machine-local overrides |
| `~/.config/zsh/p10k.local.zsh` | ❌ not tracked | Live machine-local overrides (copy from template) |

**Do not** set `PROMPT` or `RPROMPT` directly — p10k owns them after it loads.  
**Do not** run `p10k configure` — the wizard overwrites `p10k.zsh`.  
Reload after edits: `source ~/.config/zsh/rc/pluginconfig/p10k.zsh`

---

## Prompt layout

**Line 1:**
```
user@hostname  ~/workspace/project   main >1 +2 !1
```
- `context` — `user@hostname`, always visible (cyan / magenta in SSH / red as root, bold username)
- `dir`     — current path, yellow, anchor segment bold
- `vcs`     — git status via custom `my_git_formatter` (see below)

**Line 2:**
```
>
```
- `prompt_char` — green `>` on success, red on failure

**Right prompt:** exit code, execution time (>3s), background jobs, direnv, mise, virtualenv,
kubecontext, terraform, aws, azure, gcloud.

---

## Git status format

The `vcs` segment uses a **custom `my_git_formatter` function** in `p10k.zsh` rather than p10k's
built-in formatter. Output format:

```
 main >1 <2 +3 !4
│      │  │  │  └─ !N  unstaged changes
│      │  │  └──── +N  staged changes
│      │  └─────── <N  behind remote
│      └────────── >N  ahead of remote
└──────────────── branch icon (see Icons section)
```

> **Important:** `my_git_formatter` reads `POWERLEVEL9K_VCS_BRANCH_ICON` directly.
> Setting `POWERLEVEL9K_MODE=nerdfont-complete` does **not** auto-populate this variable —
> you must set it explicitly (see Icons section below).

---

## Icons and Nerd Font setup

### How it works

`POWERLEVEL9K_MODE` controls the icon tables for p10k's **built-in segments** (prompt_char,
dir, etc.). It does **not** affect the custom `my_git_formatter`.

The branch icon requires explicit opt-in via `POWERLEVEL9K_VCS_BRANCH_ICON`.

### Repo default: ascii (safe everywhere)

```zsh
# p10k.zsh repo default — works on any machine, no font needed
typeset -g POWERLEVEL9K_MODE=ascii
typeset -g POWERLEVEL9K_ICON_PADDING=none
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=      # no branch icon in ascii mode
```

### Per-machine opt-in: Nerd Font icons

**Step 1 — Install the font on the machine that renders the terminal**

| Environment | How |
|-------------|-----|
| Linux native | **Automated** — `scripts/fonts.sh` runs at bootstrap and installs JetBrainsMono to `~/.local/share/fonts/` |
| WSL (Windows Terminal / VS Code) | **Manual** — bootstrap prints instructions; install on the Windows side |
| macOS | **Manual** — download from nerd-fonts releases |

WSL / Windows (PowerShell, **not** WSL):
```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
# or download manually from https://github.com/ryanoasis/nerd-fonts/releases
```

Re-run Linux font install manually (idempotent):
```bash
bash scripts/fonts.sh
fc-list | grep -i "JetBrains.*Nerd"   # confirm registered
```

**Step 2 — Configure the terminal to use the font**

VS Code — add to `settings.json`:
```json
"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font Mono",
"terminal.integrated.fontSize": 13
```

Windows Terminal — add to the WSL profile in `settings.json`:
```json
"font": { "face": "JetBrainsMono Nerd Font Mono" }
```

**Step 3 — `~/.config/zsh/p10k.local.zsh` (automated at bootstrap)**

`setup.sh` automatically copies the template to `~/.config/zsh/p10k.local.zsh` during
the link phase if the file doesn't exist yet. On a fresh install you don't need to do
anything — the file is already there with Nerd Font settings enabled.

To re-create it manually:
```zsh
cp ~/.config/zsh/p10k.local.zsh.template ~/.config/zsh/p10k.local.zsh
```

The file already has the three nerdfont lines active (NerdFont is the template default):

```zsh
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_ICON_PADDING=moderate
# Branch icon for the custom git formatter (\uE0A0 = Nerd Font branch glyph)
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=$'\uE0A0 '
```

Open a new terminal. Icons and the  branch glyph will appear.

---

## Why `p10k.local.zsh` must be sourced inside `p10k.zsh`

`p10k.zsh` starts with `unset -m 'POWERLEVEL9K_*'` which wipes all variables. Attempting to
pre-seed `POWERLEVEL9K_MODE` before the file is sourced (e.g. in zinit `atinit`) or to apply
overrides after the file is sourced (in zinit `atload`) and then call `p10k reload` both fail:

- **atinit pre-seed** — wiped by `unset -m` near the top of `p10k.zsh`
- **atload + p10k reload** — `p10k reload` re-runs `p10k.zsh`, which calls `unset -m` again,
  then sets `MODE=ascii`, and the local file is never re-sourced inside that reload

**The only correct place** is the local source inside `p10k.zsh` itself, just before its own
`p10k reload` call at the bottom. Sequence:
1. `unset -m 'POWERLEVEL9K_*'` wipes everything
2. Repo defaults set (`MODE=ascii`, segments, colours, etc.)
3. `p10k.local.zsh` sourced — local overrides win
4. Single `p10k reload` runs with the final merged state

---

## VS Code settings symlink note

The live `~/.config/Code/User/settings.json` is a symlink managed by bootstrap. After the `Code`
config was moved from `config/core/Code/` to `config/optional/Code/` the symlink became dangling.
Fix applied:
```zsh
rm ~/.config/Code/User/settings.json
ln -s ~/workspace/dotfiles/config/optional/Code/User/settings.json \
      ~/.config/Code/User/settings.json
```
The `full` profile links `config/optional/Code` so re-running `./setup.sh` will keep this correct
going forward.

---

## Quick reference: customising the prompt

| Goal | Where to change |
|------|----------------|
| Add/remove left or right segments | `p10k.zsh` — `POWERLEVEL9K_{LEFT,RIGHT}_PROMPT_ELEMENTS` |
| Change segment colours | `p10k.zsh` — `POWERLEVEL9K_<SEGMENT>_FOREGROUND` |
| Enable transient prompt | `p10k.local.zsh` — `POWERLEVEL9K_TRANSIENT_PROMPT=same-dir` |
| Enable instant prompt | `p10k.local.zsh` — `POWERLEVEL9K_INSTANT_PROMPT=quiet` |
| Enable Nerd Font icons | `p10k.local.zsh` — see Icons section above |
| Show time in right prompt | `p10k.local.zsh` — `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=(time)` |
| Show user@host always | Already enabled in repo — `context` is on the left prompt |
