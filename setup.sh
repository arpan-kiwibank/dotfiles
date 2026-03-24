#! /bin/bash

set -euo pipefail

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [--debug | -d] [--dry-run | -n] [--help | -h]" 0>&2
	print_default ""
}

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source "${current_dir}"/scripts/utils.sh
	local dry_run="false"

	while [ $# -gt 0 ]; do
		case ${1} in
			--debug | -d)
				set -euxo pipefail
				;;
			--dry-run | -n)
				dry_run="true"
				;;
			--help | -h)
				helpmsg
				exit 1
				;;
			--all)
				# Kept for backward compatibility with old docs; install already performs all phases.
				;;
			*) ;;

		esac
		shift
	done

	if [[ "$dry_run" == "true" ]]; then
		export DOTFILES_DRY_RUN=true
		print_notice "Dry-run mode enabled"
	fi

	"${current_dir}"/scripts/initiate.sh install

	print_info ""
	print_info "#####################################################"
	print_info "$(basename "${BASH_SOURCE[0]:-$0}") install finish!!!"
	print_info "#####################################################"
	print_info ""
}

main "$@"