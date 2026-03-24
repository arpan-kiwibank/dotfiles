#! /bin/bash

set -euo pipefail

#--------------------------------------------------------------#
##          Functions                                         ##
#--------------------------------------------------------------#

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [install | update | link] [--dry-run | -n] [--help | -h]" 0>&2
	print_default "  install: add require package install and symbolic link to $HOME from dotfiles [default]"
	print_default "  update: add require package install or update."
	print_default "  link: only symbolic link to $HOME from dotfiles."
	print_default "  --dry-run: print planned changes without modifying the system."
	print_default ""
}

#--------------------------------------------------------------#
##          main                                              ##
#--------------------------------------------------------------#

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source "$current_dir"/utils.sh

	local is_install="false"
	local is_link="false"
	local is_update="false"
	local action=""
	local dry_run="${DOTFILES_DRY_RUN:-false}"

	while [ $# -gt 0 ]; do
		case ${1} in
			--help | -h)
				helpmsg
				exit 1
				;;
			--dry-run | -n)
				dry_run="true"
				;;
			install)
				action="install"
				;;
			update)
				action="update"
				;;
			link)
				action="link"
				 ;;

			--verbose | --debug)
				set -x
				;;
			*)
				echo "[ERROR] Invalid arguments '${1}'"
				helpmsg
				exit 1
				;;
		esac
		shift
	done

	if [[ "$dry_run" == "true" ]]; then
		export DOTFILES_DRY_RUN=true
		print_notice "Dry-run mode enabled"
	fi

	# default behaviour
	if [[ -z "$action" ]]; then
		action="install"
	fi

	case "$action" in
		install)
		is_install="true"
		is_link="true"
		is_update="true"
		;;
		update)
		is_install="true"
		is_link="false"
		is_update="true"
		;;
		link)
		is_install="false"
		is_link="true"
		is_update="false"
		;;
	esac

	if [[ "$is_install" = true ]]; then
		source "$current_dir"/required-packages.sh
	fi

	if [[ "$is_link" = true ]]; then
		source "$current_dir"/home-dir.sh
		print_info ""
		print_info "#####################################################"
		print_info "$(basename "${BASH_SOURCE[0]:-$0}") link success!!!"
		print_info "#####################################################"
		print_info ""
	fi

	if [[ "$is_update" = true ]]; then
		source "$current_dir"/basic-packages.sh
		source "$current_dir"/nvim.sh
		run_cmd mkdir -p "$HOME/.local/bin"
		run_cmd ln -snf "$current_dir"/bin/* "$HOME/.local/bin/"
	fi

	print_info ""
	print_info "#####################################################"
	print_info "$(basename "${BASH_SOURCE[0]:-$0}") update finish!!!"
	print_info "#####################################################"
	print_info ""
	
}

main "$@"
