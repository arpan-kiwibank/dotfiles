#! /bin/bash

set -euo pipefail

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [--debug | -d] [--dry-run | -n] [initiate options] [--help | -h]" 0>&2
	print_default "  initiate options are passed through (e.g. --profile hypr-minimal)."
	print_default ""
}

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source "${current_dir}"/scripts/utils.sh
	local dry_run="false"
	local -a initiate_args=()

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
			*)
				initiate_args+=("$1")
				;;

		esac
		shift
	done

	if [[ "$dry_run" == "true" ]]; then
		export DOTFILES_DRY_RUN=true
		print_notice "Dry-run mode enabled"
	fi

	"${current_dir}"/scripts/initiate.sh install "${initiate_args[@]}"

	print_info ""
	print_info "#####################################################"
	print_info "$(basename "${BASH_SOURCE[0]:-$0}") install finish!!!"
	print_info "#####################################################"
	print_info ""
}

main "$@"