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
	local tmp_archive

	run_cmd mkdir -p "$HOME/.local/"

	if is_dry_run; then
		print_notice "[dry-run] download $url"
		print_notice "[dry-run] validate archive and extract to $HOME/.local/"
	else
		tmp_archive=$(mktemp)
		run_cmd curl -fL --retry 3 --retry-delay 2 -o "$tmp_archive" "$url"
		if ! tar -tzf "$tmp_archive" >/dev/null 2>&1; then
			print_error "Downloaded Neovim archive is invalid: $url"
			rm -f "$tmp_archive"
			return 1
		fi
		run_cmd tar -xzf "$tmp_archive" --strip-components 1 -C "$HOME/.local/"
		rm -f "$tmp_archive"
	fi

	# for nvim-treesitter
	# https://github.com/nvim-treesitter/nvim-treesitter/blob/68e8181dbcf29330716d380e5669f2cd838eadb5/lua/nvim-treesitter/install.lua#L14
	checkinstall gcc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    neovim_nightly
fi