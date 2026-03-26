#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

# ─── JetBrainsMono Nerd Font ─────────────────────────────────────────────────
# Installs JetBrainsMono Nerd Font to ~/.local/share/fonts/ on native Linux.
#
# WSL: fonts must be installed on the Windows side (the terminal renderer is
# Windows-based). This script prints instructions and returns — nothing is
# installed into the Linux layer.
#
# Ref: https://github.com/ryanoasis/nerd-fonts/releases

NERD_FONT_NAME="JetBrainsMono"
NERD_FONT_ARCHIVE="${NERD_FONT_NAME}.zip"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT_ARCHIVE}"
NERD_FONT_INSTALL_DIR="${HOME}/.local/share/fonts/${NERD_FONT_NAME}"

function install_nerd_fonts() {
    # WSL: renderer is on the Windows side — Linux font install has no effect.
    if is_wsl; then
        print_notice "WSL detected: Nerd Fonts must be installed on the Windows side."
        print_notice "  PowerShell: winget install --id DEVCOM.JetBrainsMonoNerdFont"
        print_notice "  Or download: https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        print_notice "  Then set your terminal font to 'JetBrainsMono Nerd Font Mono'."
        return 0
    fi

    # Already installed?
    if command -v fc-list >/dev/null 2>&1 \
        && fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
        print_notice "JetBrainsMono Nerd Font already installed"
        return 0
    fi

    print_info "Installing JetBrainsMono Nerd Font"

    if is_dry_run; then
        print_notice "[dry-run] would download ${NERD_FONT_URL}"
        print_notice "[dry-run] would install to ${NERD_FONT_INSTALL_DIR}/"
        print_notice "[dry-run] would run: fc-cache -f"
        return 0
    fi

    # unzip must be available — it is in basic-packages.sh
    if ! command -v unzip >/dev/null 2>&1; then
        print_warning "unzip not found — skipping Nerd Font install"
        print_notice "  Install unzip and re-run: bash scripts/fonts.sh"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local archive="$tmp_dir/${NERD_FONT_ARCHIVE}"
    local exit_code=0
    curl -fsSL --retry 3 --retry-delay 2 -o "$archive" "$NERD_FONT_URL" || exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_warning "JetBrainsMono Nerd Font download failed (curl exit ${exit_code} — network or proxy block?)"
        print_notice "  Install manually: curl -fsSL ${NERD_FONT_URL} -o /tmp/${NERD_FONT_ARCHIVE}"
        print_notice "  Then: unzip /tmp/${NERD_FONT_ARCHIVE} -d ${NERD_FONT_INSTALL_DIR}/ && fc-cache -f"
        rm -rf "$tmp_dir"
        return 0
    fi

    # Validate archive before extraction (guards against empty mocked files in CI)
    if ! unzip -t "$archive" >/dev/null 2>&1; then
        print_warning "JetBrainsMono Nerd Font archive is invalid or empty — skipping extraction"
        print_notice "  Re-run manually: bash scripts/fonts.sh"
        rm -rf "$tmp_dir"
        return 0
    fi

    mkdir -p "${NERD_FONT_INSTALL_DIR}"
    # Install only variable TTF/OTF files — skip Windows bitmap fonts (.fon, .pfm)
    unzip -qo "$archive" "*.ttf" "*.otf" -d "${NERD_FONT_INSTALL_DIR}/" 2>/dev/null \
        || unzip -qo "$archive" -d "${NERD_FONT_INSTALL_DIR}/" 2>/dev/null
    rm -rf "$tmp_dir"

    # Rebuild font cache
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "${NERD_FONT_INSTALL_DIR}"
        print_success "JetBrainsMono Nerd Font installed and cache rebuilt"
    else
        print_success "JetBrainsMono Nerd Font installed (fc-cache not found — run it manually)"
    fi
    print_notice "  Set your terminal font to 'JetBrainsMono Nerd Font Mono'"
    print_notice "  VS Code: \"terminal.integrated.fontFamily\": \"JetBrainsMono Nerd Font Mono\""
}

install_nerd_fonts
