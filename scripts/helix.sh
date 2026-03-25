#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

function get_helix_linux_arch_suffix() {
	local arch
	arch=$(uname -m)
	case "$arch" in
		x86_64 | amd64)
			echo "x86_64-linux"
			;;
		aarch64 | arm64)
			echo "aarch64-linux"
			;;
		*)
			print_warning "Unsupported architecture for Helix binary fallback: $arch"
			return 1
			;;
	esac
}

function try_install_helix_from_pkg_manager() {
	local distro
	distro=$(whichdistro)

	case "$distro" in
		debian)
			if apt-cache show helix >/dev/null 2>&1; then
				checkinstall helix
				return 0
			fi
			;;
		redhat)
			if command -v dnf >/dev/null 2>&1 && dnf list --available helix >/dev/null 2>&1; then
				checkinstall helix
				return 0
			fi
			if command -v yum >/dev/null 2>&1 && yum list available helix >/dev/null 2>&1; then
				checkinstall helix
				return 0
			fi
			;;
		arch)
			if pacman -Si helix >/dev/null 2>&1; then
				checkinstall helix
				return 0
			fi
			;;
	esac

	return 1
}

function install_helix_binary_fallback() {
	local suffix
	suffix=$(get_helix_linux_arch_suffix)
	local api_url="https://api.github.com/repos/helix-editor/helix/releases/latest"
	local download_url

	# Prefer jq when available; fall back to grep+sed so standalone
	# 'bash scripts/helix.sh' works even before jq is installed.
	if command -v jq >/dev/null 2>&1; then
		download_url=$(curl -fsSL "$api_url" \
			| jq -r ".assets[] | select(.name | endswith(\"${suffix}.tar.xz\")) | .browser_download_url" \
			| head -n1)
	else
		download_url=$(curl -fsSL "$api_url" \
			| grep -o '"browser_download_url": "[^"]*'"${suffix}"'\.tar\.xz"' \
			| grep -o 'https://[^"]*' \
			| head -n1)
	fi

	if [[ -z "$download_url" || "$download_url" == "null" ]]; then
		print_error "Could not find Helix release asset for ${suffix}"
		return 1
	fi

	local tmp_dir
	tmp_dir=$(mktemp -d)
	local archive="$tmp_dir/helix.tar.xz"
	local install_root="$HOME/.local/opt"
	local install_dir="$install_root/helix"

	run_cmd mkdir -p "$install_root"
	run_cmd mkdir -p "$HOME/.local/bin"

	if is_dry_run; then
		print_notice "[dry-run] download $download_url"
		print_notice "[dry-run] extract Helix archive to $install_dir"
		print_notice "[dry-run] symlink $install_dir/hx -> $HOME/.local/bin/hx"
	else
		curl -fL --retry 3 --retry-delay 2 -o "$archive" "$download_url"
		tar -xJf "$archive" -C "$tmp_dir"
		local extracted_dir
		extracted_dir=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)
		if [[ -z "$extracted_dir" ]]; then
			print_error "Helix archive extraction failed"
			rm -rf "$tmp_dir"
			return 1
		fi
		rm -rf "$install_dir"
		mv "$extracted_dir" "$install_dir"
		ln -snf "$install_dir/hx" "$HOME/.local/bin/hx"
		rm -rf "$tmp_dir"
	fi

	print_success "Helix installed via GitHub release fallback"
}

function get_latest_helix_version() {
        curl -fsSL "https://api.github.com/repos/helix-editor/helix/releases/latest" \
                2>/dev/null \
                | grep -m1 '"tag_name"' \
                | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true
}

function install_helix() {
        if command -v hx >/dev/null 2>&1; then
                # Already installed — check whether a newer release exists on GitHub.
                # Fail-open: if the API call fails or the version cannot be parsed,
                # latest_ver is empty and we fall through to re-install.
                local installed_ver latest_ver
                installed_ver=$(hx --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
                latest_ver=$(get_latest_helix_version)
                if [[ -n "$latest_ver" && "$installed_ver" == "$latest_ver" ]]; then
                        print_notice "Helix is up to date ($installed_ver)"
                        return 0
                fi
                [[ -n "$latest_ver" ]] && print_notice "Helix update available: $installed_ver → $latest_ver"
        fi

        if try_install_helix_from_pkg_manager; then
                print_success "Helix installed/updated from package manager"
		return 0
	fi

	print_warning "Helix package not available in current repos; using binary fallback"
	install_helix_binary_fallback
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_helix
fi
