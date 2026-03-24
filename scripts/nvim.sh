#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

function neovim_nightly() {
	run_cmd mkdir -p "$HOME/.local/"
	run_cmd_shell "curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz | tar zx --strip-components 1 -C '$HOME/.local/'"
	# for nvim-treesitter
	# https://github.com/nvim-treesitter/nvim-treesitter/blob/68e8181dbcf29330716d380e5669f2cd838eadb5/lua/nvim-treesitter/install.lua#L14
	checkinstall gcc
}

neovim_nightly