#! /bin/bash

set -ue

source $(dirname "${BASH_SOURCE[0]:-$0}")/utils.sh

distro=$(whichdistro)
if [[ $distro == "redhat" ]]; then
	checkinstall zsh git tmux bc curl wget gawk python3-pip unzip sqlite sqlite-devel gettext procps jq helix
elif [[ $distro == "debian" ]]; then
	checkinstall zsh git tmux bc curl wget gawk python3-pip unzip sqlite3 gettext procps jq helix
else
	checkinstall zsh git tmux bc curl wget xsel gawk python-pip unzip sqlite gettext procps jq helix
fi

if [[ $distro == "redhat" ]]; then
	:
elif [[ $distro == "arch" ]]; then
	sudo pacman -S --noconfirm --needed tar
elif [[ $distro == "alpine" ]]; then
	sudo apk add g++
elif [[ $distro == "debian" ]]; then
	:
else
	:
fi