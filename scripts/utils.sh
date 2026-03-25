#! /bin/bash

function is_dry_run() {
	case "${DOTFILES_DRY_RUN:-false}" in
		1 | true | TRUE | yes | YES | y | Y)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

function is_wsl() {
	# /proc/version contains "microsoft" on WSL2, but Docker containers running on a WSL2 host
	# share the same kernel and therefore show the same string. WSLInterop only exists in a
	# real WSL session, not inside Docker-on-WSL, so we require both conditions.
	grep -qi microsoft /proc/version 2>/dev/null &&
		[[ -e /proc/sys/fs/binfmt_misc/WSLInterop ]]
}

function run_cmd() {
	if is_dry_run; then
		print_notice "[dry-run] $*"
		return 0
	fi
	"$@"
}

function run_cmd_shell() {
	if is_dry_run; then
		print_notice "[dry-run] $*"
		return 0
	fi
	bash -c "$*"
}

function print_default() {
	echo -e "$*"
}

function print_info() {
	echo -e "\e[1;36m$*\e[m" # cyan
}

function print_notice() {
	echo -e "\e[1;35m$*\e[m" # magenta
}

function print_success() {
	echo -e "\e[1;32m$*\e[m" # green
}

function print_warning() {
	echo -e "\e[1;33m$*\e[m" # yellow
}

function print_error() {
	echo -e "\e[1;31m$*\e[m" # red
}

function print_debug() {
	echo -e "\e[1;34m$*\e[m" # blue
}

function chkcmd() {
	if ! builtin command -v "$1"; then
		print_error "${1} command not found"
		exit
	fi
}

function yes_or_no_select() {
	local answer
	print_notice "Are you ready? [yes/no]"
	read -r answer
	case $answer in
		yes | y)
			return 0
			;;
		no | n)
			return 1
			;;
		*)
			yes_or_no_select
			;;
	esac
}

function append_file_if_not_exist() {
	contents="$1"
	target_file="$2"
	if ! grep -q "${contents}" "${target_file}"; then
		echo "${contents}" >>"${target_file}"
	fi
}

function whichdistro() {
	#which yum > /dev/null && { echo redhat; return; }
	#which zypper > /dev/null && { echo opensuse; return; }
	#which apt-get > /dev/null && { echo debian; return; }
	if [ -f /etc/debian_version ]; then
		echo debian
		return
	elif [ -f /etc/fedora-release ]; then
		# echo fedora; return;
		echo redhat
		return
	elif [ -f /etc/redhat-release ]; then
		echo redhat
		return
	elif [ -f /etc/arch-release ]; then
		echo arch
		return
	elif [ -f /etc/alpine-release ]; then
		echo alpine
		return
	fi
}

function checkinstall() {
	local distro
	distro=$(whichdistro)
	if [[ $distro == "redhat" ]]; then
		run_cmd sudo yum clean all
		if ! grep -i "fedora" /etc/redhat-release >/dev/null; then
			run_cmd sudo yum install -y epel-release
			if [[ $(cat /etc/*release | grep '^VERSION=' | cut -d '"' -f 2 | cut -d " " -f 1) -ge 8 ]]; then
				run_cmd sudo dnf install -y 'dnf-command(config-manager)'
				run_cmd sudo dnf config-manager --set-enabled powertools
			fi
		fi
	fi

	local pkgs="$*"
	if [[ $distro == "debian" ]]; then
		pkgs=${pkgs//python-pip/python3-pip}
		run_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y $pkgs
	elif [[ $distro == "redhat" ]]; then
		run_cmd sudo yum install -y $pkgs
	elif [[ $distro == "arch" ]]; then
		run_cmd sudo pacman -S --noconfirm --needed $pkgs
	elif [[ $distro == "alpine" ]]; then
		run_cmd sudo bash -c "$(declare -f append_file_if_not_exist); append_file_if_not_exist http://dl-3.alpinelinux.org/alpine/edge/testing/ /etc/apk/repositories"
		pkgs=${pkgs//python-pip/py-pip}
		run_cmd sudo apk add $pkgs
	else
		:
	fi
}

function git_clone_or_fetch() {
	local repo="$1"
	local dest="$2"
	local name
	name=$(basename "$repo")
	if [ ! -d "$dest/.git" ]; then
		print_default "Installing $name..."
		print_default ""
		run_cmd mkdir -p "$dest"
		run_cmd git clone --depth 1 "$repo" "$dest"
	else
		print_default "Pulling $name..."
		if is_dry_run; then
			print_notice "[dry-run] git pull --depth 1 --rebase in $dest"
		else
			(
				builtin cd "$dest" && git pull --depth 1 --rebase origin "$(basename "$(git symbolic-ref --short refs/remotes/origin/HEAD)")" ||
				print_notice "Exec in compatibility mode [git pull --rebase]" &&
				builtin cd "$dest" && git fetch --unshallow && git rebase origin/"$(basename "$(git symbolic-ref --short refs/remotes/origin/HEAD)")"
			)
		fi
	fi
}

function mkdir_not_exist() {
	if [ ! -d "$1" ]; then
		run_cmd mkdir -p "$1"
	fi
}