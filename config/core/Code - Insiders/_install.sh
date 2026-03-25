#!/usr/bin/env bash

set -ue

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source_dir=$(cd "$current_dir/../Code" && pwd -P)
target_dir="$HOME/.config/$(basename "$current_dir")"
src_list=$(command find "$source_dir" -mindepth 1 -type f | command grep -v '/_install.sh$')

for src_fullpath in $src_list; do
	relative_path=${src_fullpath#"$source_dir/"}
	if [[ ! -e $(dirname "$target_dir/$relative_path") ]]; then
		mkdir -p "$(dirname "$target_dir/$relative_path")"
	fi
	command ln -snf "$src_fullpath" "$target_dir/$relative_path"
done