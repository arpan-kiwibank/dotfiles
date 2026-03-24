#! /bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]:-$0}")"/utils.sh

function contains_exact() {
	local needle="$1"
	shift
	local item
	for item in "$@"; do
		if [[ "$item" == "$needle" ]]; then
			return 0
		fi
	done
	return 1
}

function backup_path_if_exists() {
	local target_path="$1"
	local backupdir="$2"

	if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
		return
	fi

	mkdir_not_exist "$backupdir"
	local basename_target
	basename_target=$(basename "$target_path")
	local backup_target="$backupdir/$basename_target"
	if [[ -e "$backup_target" || -L "$backup_target" ]]; then
		backup_target="$backup_target.$(date '+%s')"
	fi
	run_cmd command mv "$target_path" "$backup_target"
}

function symlink_points_to() {
	local symlink_path="$1"
	local source_path="$2"
	[[ -L "$symlink_path" ]] && [[ "$(readlink -f "$symlink_path")" == "$(readlink -f "$source_path")" ]]
}

function backup_and_link() {
	local link_src_file=$1
	local link_dest_dir=$2
	local backupdir=$3
	local f_filename
	f_filename=$(basename "$link_src_file")
	local f_filepath="$link_dest_dir/$f_filename"
	mkdir_not_exist "$link_dest_dir"

	if install_by_local_installer "$link_src_file" "$link_dest_dir" "$backupdir"; then
		return
	fi

	if symlink_points_to "$f_filepath" "$link_src_file"; then
		print_default "Skip (already linked): $f_filepath"
		return
	fi

	backup_path_if_exists "$f_filepath" "$backupdir"
	print_default "Creating symlink for $link_src_file -> $link_dest_dir"
	run_cmd command ln -snf "$link_src_file" "$f_filepath"
}

function install_by_local_installer() {
	local link_src_file=$1
	local link_dest_dir=$2
	local backupdir=$3

	if [[ ! -d "$link_src_file" ]]; then
		return 1
	fi

	local file_list
	mapfile -t file_list < <(command find "$link_src_file" -name "_install.sh" -type f 2>/dev/null)
	if [[ ${#file_list[@]} -gt 0 ]]; then
		local f_filename
		f_filename=$(basename "$link_src_file")
		local f_filepath="$link_dest_dir/$f_filename"
		backup_path_if_exists "$f_filepath" "$backupdir"

		local f
		for f in "${file_list[@]}"; do
			if is_dry_run; then
				print_notice "[dry-run] installer hook: $f"
			else
				print_notice "Running installer hook: $f"
				DOTFILES_LINK_DEST_DIR="$link_dest_dir" DOTFILES_BACKUP_DIR="$backupdir" bash "$f"
			fi
		done
		return 0
	fi
	return 1
}

function link_config_dir() {
	local dotfiles_dir=$1
	local backupdir="${2}/.config"
	mkdir_not_exist "$backupdir"
	local dest_dir="${HOME}/.config" # ${XDG_CONFIG_HOME}
	mkdir_not_exist "$dest_dir"

	shopt -s nullglob
	for f in "$dotfiles_dir"/.config/??*; do
		backup_and_link "$f" "$dest_dir" "$backupdir"
	done
	shopt -u nullglob
}

function link_to_homedir() {
	print_notice "backup old dotfiles..."
	local tmp_date
	tmp_date=$(date '+%y%m%d-%H%M%S')
	local backupdir="${XDG_CACHE_HOME:-$HOME/.cache}/dotbackup/$tmp_date"
	mkdir_not_exist "$backupdir"
	print_info "create backup directory: $backupdir\n"

	print_info "Creating symlinks"
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	local dotfiles_dir
	if command git -C "$current_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
		dotfiles_dir="$(command git -C "$current_dir" rev-parse --show-toplevel)"
	else
		dotfiles_dir="$(builtin cd "$current_dir/.." && pwd -P)"
	fi

	local -a linkignore=(
		".git"
		".gitmodules"
	)
	if [[ -e "$dotfiles_dir/.linkignore" ]]; then
		while IFS= read -r entry; do
			[[ -z "$entry" || "$entry" == \#* ]] && continue
			linkignore+=("$entry")
		done <"$dotfiles_dir/.linkignore"
	fi
	if [[ "$HOME" != "$dotfiles_dir" ]]; then
		shopt -s nullglob
		for f in "$dotfiles_dir"/.??*; do
			local f_filename
			f_filename=$(basename "$f")
			contains_exact "$f_filename" "${linkignore[@]}" && continue
			[[ "$f_filename" == ".config" ]] && link_config_dir "$dotfiles_dir" "$backupdir" && continue
			backup_and_link "$f" "$HOME" "$backupdir"
		done
		shopt -u nullglob
	fi
}

link_to_homedir