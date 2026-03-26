#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

# ─── GitHub Copilot CLI ──────────────────────────────────────────────────────
# Standalone binary installer — no gh CLI or npm required.
# Installs to ~/.local/bin/copilot (non-root) or /usr/local/bin/copilot (root).
# Ref: https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli
# Usage: copilot <question>
# First-run auth: copilot /login

function install_gh_copilot() {
    # Check the exact install path instead of `command -v copilot`, because other
    # tools (e.g. VS Code's Copilot Chat CLI shim) may shadow the name and hang
    # on --version with an interactive prompt.
    # The official installer places the binary in ~/.local/bin (non-root) or
    # /usr/local/bin (root).
    local copilot_bin
    if [[ $EUID -eq 0 ]]; then
        copilot_bin="/usr/local/bin/copilot"
    else
        copilot_bin="${HOME}/.local/bin/copilot"
    fi
    if [[ -x "$copilot_bin" ]]; then
        print_notice "GitHub Copilot CLI already installed: $copilot_bin"
        return 0
    fi

    print_info "Installing GitHub Copilot CLI (official installer)"
    if is_dry_run; then
        print_notice "[dry-run] would run: curl -fsSL https://gh.io/copilot-install | bash"
        return 0
    fi
    curl -fsSL https://gh.io/copilot-install | bash
    print_success "GitHub Copilot CLI installed: copilot"
}

# ─── Claude Code ────────────────────────────────────────────────────────────
# Standalone binary installer — no npm required.
# Installs to ~/.local/bin/claude.
# Ref: https://code.claude.com/docs/en/quickstart
# First-run auth: claude (prompts for Anthropic login)

function install_claude_code() {
    # Check the exact install path for the same reason as install_gh_copilot —
    # avoid calling `claude --version` in case another tool shadows the name.
    local claude_bin
    if [[ $EUID -eq 0 ]]; then
        claude_bin="/usr/local/bin/claude"
    else
        claude_bin="${HOME}/.local/bin/claude"
    fi
    if [[ -x "$claude_bin" ]]; then
        print_notice "Claude Code already installed: $claude_bin"
        return 0
    fi

    print_info "Installing Claude Code (official installer)"
    if is_dry_run; then
        print_notice "[dry-run] would run: curl -fsSL https://claude.ai/install.sh | bash"
        return 0
    fi
    curl -fsSL https://claude.ai/install.sh | bash
    print_success "Claude Code installed: claude"
}

install_gh_copilot
install_claude_code
