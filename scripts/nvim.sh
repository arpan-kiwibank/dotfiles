#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

function get_nvim_linux_asset_name() {
	local arch
	arch=$(uname -m)
	case "$arch" in
		x86_64 | amd64)
			echo "nvim-linux-x86_64.tar.gz"
			;;
		aarch64 | arm64)
			echo "nvim-linux-arm64.tar.gz"
			;;
		*)
			print_error "Unsupported architecture for Neovim nightly: $arch"
			return 1
			;;
	esac
}

function neovim_nightly() {
	local asset_name
	asset_name=$(get_nvim_linux_asset_name)
	local url="https://github.com/neovim/neovim/releases/download/nightly/${asset_name}"
	local nvim_bin="$HOME/.local/bin/nvim"
	local tmp_archive

	run_cmd mkdir -p "$HOME/.local/"

	if is_dry_run; then
		print_notice "[dry-run] check nightly release date against $nvim_bin and download if newer"
		print_notice "[dry-run] validate archive and extract to $HOME/.local/"
	else
		# Skip download if the installed binary is at least as new as the latest nightly release.
		# Fail-open: if the API call or date parse fails, latest_epoch stays 0 and we download anyway.
		if [[ -x "$nvim_bin" ]]; then
			local installed_epoch latest_published latest_epoch
			installed_epoch=$(stat -c %Y "$nvim_bin" 2>/dev/null || echo 0)
			latest_published=$(curl -fsSL \
				"https://api.github.com/repos/neovim/neovim/releases/tags/nightly" \
				2>/dev/null \
				| grep -m1 '"published_at"' \
				| grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' || true)
			if [[ -n "$latest_published" ]]; then
				latest_epoch=$(date -d "$latest_published" +%s 2>/dev/null || echo 0)
			else
				latest_epoch=0
			fi
			if [[ "$latest_epoch" -gt 0 && "$installed_epoch" -ge "$latest_epoch" ]]; then
				print_notice "Neovim nightly is up to date ($(nvim --version | head -1))"
				checkinstall gcc
				return 0
			fi
			[[ "$latest_epoch" -gt 0 ]] && print_notice "Neovim nightly update available — downloading…"
		fi

		tmp_archive=$(mktemp)
		run_cmd curl -fL --retry 3 --retry-delay 2 -o "$tmp_archive" "$url"
		if ! tar -tzf "$tmp_archive" >/dev/null 2>&1; then
			print_error "Downloaded Neovim archive is invalid: $url"
			rm -f "$tmp_archive"
			return 1
		fi
		run_cmd tar -xzf "$tmp_archive" --strip-components 1 -C "$HOME/.local/"
		rm -f "$tmp_archive"
		# Touch the binary so its mtime reflects install time (always ≥ published_at),
		# ensuring the version check works correctly on subsequent runs.
		touch "$nvim_bin" 2>/dev/null || true
	fi

	# for nvim-treesitter
	# https://github.com/nvim-treesitter/nvim-treesitter/blob/68e8181dbcf29330716d380e5669f2cd838eadb5/lua/nvim-treesitter/install.lua#L14
	checkinstall gcc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    neovim_nightly
fi