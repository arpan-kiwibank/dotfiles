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

function append_manifest_entries() {
	local manifest_path="$1"
	local array_name="$2"
	local -n manifest_entries_ref="$array_name"

	if [[ ! -f "$manifest_path" ]]; then
		print_error "Profile manifest not found: $manifest_path"
		exit 1
	fi

	local entry
	while IFS= read -r entry || [[ -n "$entry" ]]; do
		entry=${entry%$'\r'}
		[[ -z "$entry" || "$entry" == \#* ]] && continue
		if ! contains_exact "$entry" "${manifest_entries_ref[@]}"; then
			manifest_entries_ref+=("$entry")
		fi
	done < "$manifest_path"
}

function load_profile_entries() {
	local dotfiles_dir="$1"
	local profile="$2"
	local array_name="$3"
	local profiles_dir="$dotfiles_dir/profiles"

	case "$profile" in
		full)
			append_manifest_entries "$profiles_dir/full.list" "$array_name"
			;;
		hypr-minimal)
			append_manifest_entries "$profiles_dir/hypr-minimal.list" "$array_name"
			;;
		*)
			print_error "Unsupported profile manifest: $profile"
			exit 1
			;;
	esac
}

function should_ignore_manifest_entry() {
	local manifest_entry="$1"
	shift
	local manifest_basename
	manifest_basename=$(basename "$manifest_entry")
	local ignored_entry
	for ignored_entry in "$@"; do
		[[ "$ignored_entry" == "$manifest_entry" ]] && return 0
		case "$manifest_entry" in
			home/*)
				[[ "$ignored_entry" == "$manifest_basename" ]] && return 0
				;;
			local-bin/*)
				[[ "$ignored_entry" == "local-bin/$manifest_basename" || "$ignored_entry" == "$manifest_basename" ]] && return 0
				;;
			config/*)
				[[ "$ignored_entry" == ".config/$manifest_basename" || "$ignored_entry" == "$manifest_basename" ]] && return 0
				;;
		esac
	done
	return 1
}

function link_manifest_entry() {
	local dotfiles_dir="$1"
	local manifest_entry="$2"
	local backup_root="$3"
	local source_path="$dotfiles_dir/$manifest_entry"

	if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
		print_warning "Skip missing manifest entry: $manifest_entry"
		return
	fi

	if [[ "${DOTFILES_SKIP_DESKTOP:-false}" == "true" && "$manifest_entry" == config/desktop/* ]]; then
		print_notice "WSL (skip desktop): $manifest_entry"
		return
	fi

	case "$manifest_entry" in
		home/*)
			backup_and_link "$source_path" "$HOME" "$backup_root"
			;;
		local-bin/*)
			backup_and_link "$source_path" "$HOME/.local/bin" "$backup_root/.local/bin"
			;;
		config/*)
			backup_and_link "$source_path" "${XDG_CONFIG_HOME:-$HOME/.config}" "$backup_root/.config"
			;;
		*)
			print_warning "Skip unsupported manifest entry: $manifest_entry"
			;;
	esac
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

# Fast pre-scan check: returns 0 if the manifest entry is already correctly linked
# (or is a WSL-skipped desktop entry), 1 if it needs action.
function is_entry_already_linked() {
        local dotfiles_dir="$1"
        local manifest_entry="$2"
        local source_path="$dotfiles_dir/$manifest_entry"

        # Missing source — will be warned about in the real loop
        [[ ! -e "$source_path" && ! -L "$source_path" ]] && return 1

        # Desktop entries skipped in WSL are effectively "handled"
        if [[ "${DOTFILES_SKIP_DESKTOP:-false}" == "true" && "$manifest_entry" == config/desktop/* ]]; then
                return 0
        fi

        local dest_dir
        case "$manifest_entry" in
                home/*)      dest_dir="$HOME" ;;
                local-bin/*) dest_dir="$HOME/.local/bin" ;;
                config/*)    dest_dir="${XDG_CONFIG_HOME:-$HOME/.config}" ;;
                *)           return 1 ;;
        esac

        local f_filename f_filepath
        f_filename=$(basename "$source_path")
        f_filepath="$dest_dir/$f_filename"

        # Entries with _install.sh hooks are always passed to the real loop
        if [[ -d "$source_path" ]]; then
                local installers
                mapfile -t installers < <(command find "$source_path" -name "_install.sh" -type f 2>/dev/null)
                [[ ${#installers[@]} -gt 0 ]] && return 1
        fi

        symlink_points_to "$f_filepath" "$source_path"
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

function link_to_homedir() {
	local tmp_date
	tmp_date=$(date '+%y%m%d-%H%M%S')
	local backupdir="${XDG_CACHE_HOME:-$HOME/.cache}/dotbackup/$tmp_date"

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
			entry=${entry%$'\r'}
			[[ -z "$entry" || "$entry" == \#* ]] && continue
			linkignore+=("$entry")
		done <"$dotfiles_dir/.linkignore"
	fi

	local profile="${DOTFILES_PROFILE:-full}"
	local -a manifest_entries=()
	load_profile_entries "$dotfiles_dir" "$profile" manifest_entries
	print_notice "Using profile manifest: $profile"

        if [[ "$HOME" == "$dotfiles_dir" ]]; then
                return 0
        fi

        # Pre-scan: count how many entries are already correctly linked.
        # If all are up to date, skip the loop (no backup dir needed, no noise).
        local count_total=0 count_linked=0
        local manifest_entry
        for manifest_entry in "${manifest_entries[@]}"; do
                should_ignore_manifest_entry "$manifest_entry" "${linkignore[@]}" && continue
                count_total=$((count_total + 1))
                is_entry_already_linked "$dotfiles_dir" "$manifest_entry" && count_linked=$((count_linked + 1))
        done

        if [[ "$count_linked" -eq "$count_total" && "$count_total" -gt 0 ]]; then
                print_success "All $count_total entries already linked — nothing to do"
                return 0
        fi

        if [[ "$count_linked" -gt 0 ]]; then
                print_notice "Link state: $count_linked/$count_total already linked"
        fi

        # Create backup dir only now that we know work is needed
        mkdir_not_exist "$backupdir"
        print_info "create backup directory: $backupdir\n"

        for manifest_entry in "${manifest_entries[@]}"; do
                if should_ignore_manifest_entry "$manifest_entry" "${linkignore[@]}"; then
                        print_notice "Skip (ignore): $manifest_entry"
                        continue
                fi
                link_manifest_entry "$dotfiles_dir" "$manifest_entry" "$backupdir"
        done
}

link_to_homedir
