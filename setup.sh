#! /bin/bash

set -ue

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [--all] [--help | -h]" 0>&2
	print_default '  --all'
	print_default ""
}

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source "${current_dir}"/scripts/utils.sh

	while [ $# -gt 0 ]; do
		case ${1} in
			--debug | -d)
				set -uex
				;;
			--help | -h)
				helpmsg
				exit 1
				;;
			*) ;;

		esac
		shift
	done

	if [[ "$" = true ]]; then
		"${current_dir}"/scripts/initiate.sh install
	else
		"${current_dir}"/scripts/initiate.sh install
	fi

	print_info ""
	print_info "#####################################################"
	print_info "$(basename "${BASH_SOURCE[0]:-$0}") install finish!!!"
	print_info "#####################################################"
	print_info ""
}

main "$@"


get_os() {

    local os=""
    local kernelName=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    kernelName="$(uname -s)"

    if [ "$kernelName" == "Darwin" ]; then
        os="macos"
    elif [ "$kernelName" == "Linux" ] && \
         [ -e "/etc/os-release" ]; then
        os="$(. /etc/os-release; printf "%s" "$ID")"
    else
        os="$kernelName"
    fi

    printf "%s" "$os"

}