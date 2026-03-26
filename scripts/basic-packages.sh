#! /bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]:-$0}")"/utils.sh

distro=$(whichdistro)
if [[ $distro == "redhat" ]]; then
	checkinstall zsh git tmux bc curl wget gawk python3-pip unzip sqlite sqlite-devel gettext procps jq
elif [[ $distro == "debian" ]]; then
	checkinstall zsh git tmux bc curl wget gawk python3-pip unzip sqlite3 gettext procps jq
else
	checkinstall zsh git tmux bc curl wget xsel gawk python-pip unzip sqlite gettext procps jq
fi

if [[ $distro == "redhat" ]]; then
	:
elif [[ $distro == "arch" ]]; then
	checkinstall tar
elif [[ $distro == "debian" ]]; then
	:
else
	print_warning "basic-packages: unknown distro '$distro' — skipping tar install"
fi