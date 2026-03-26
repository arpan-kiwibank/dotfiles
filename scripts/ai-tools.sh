#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

# ─── GitHub Copilot CLI ──────────────────────────────────────────────────────
# Installed as a gh CLI extension (Go binary, no npm/node required).
# Usage: gh copilot suggest "<task>", gh copilot explain "<cmd>"
# First-run auth: gh auth login

function install_gh_copilot() {
    if ! command -v gh >/dev/null 2>&1; then
        print_warning "gh CLI not found — skipping GitHub Copilot CLI (gh is installed by zinit on first zsh start)"
        print_notice "  Re-run './setup.sh update' after opening a zsh session to complete Copilot CLI install"
        return 0
    fi

    if gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
        print_notice "GitHub Copilot CLI extension already installed"
        return 0
    fi

    print_info "Installing GitHub Copilot CLI (gh extension)"
    run_cmd gh extension install github/gh-copilot
    print_success "GitHub Copilot CLI installed: gh copilot suggest / gh copilot explain"
}

# ─── Claude Code ────────────────────────────────────────────────────────────
# Anthropic's agentic coding CLI.
# Uses the official cross-platform installer from https://code.claude.com/docs/en/quickstart
# First-run auth: claude (prompts for Anthropic login)

function install_claude_code() {
    if command -v claude >/dev/null 2>&1; then
        print_notice "Claude Code already installed: $(claude --version 2>/dev/null || echo 'version unknown')"
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
