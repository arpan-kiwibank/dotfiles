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
	# Use env vars set by the WSL launcher — immune to filesystem layout changes.
	# WSL_DISTRO_NAME: set for every real WSL session since WSL1.
	# WSL_INTEROP:     the Unix socket path; secondary fallback for minimal distros.
	# Neither is present in Docker containers running on a WSL2 host, which share
	# the same /proc/version kernel string — making env-var detection the only
	# reliable way to distinguish WSL from Docker-on-WSL.
	# Avoid /proc/sys/fs/binfmt_misc/WSLInterop* — Ubuntu 24.04 systemd creates
	# WSLInterop-late instead of WSLInterop, and the name may change again.
	# See: https://github.com/microsoft/WSL/issues/13449
	[[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSL_INTEROP:-}" ]]
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

function preflight_check() {
	# Run before any install/update phase. Hard failures exit; soft issues
	# print a warning and allow bootstrap to continue.
	# Skipped entirely in dry-run mode (environment validity is irrelevant there).
	if is_dry_run; then
		return 0
	fi

	local hard_fail=0

	print_info "Running pre-flight checks…"

	# 1. Distro support
	local distro
	distro=$(whichdistro)
	case "$distro" in
		debian | redhat | arch)
			print_success "  Distro: $distro"
			;;
		alpine)
			print_error "  Distro: Alpine is not supported. Aborting."
			exit 1
			;;
		*)
			print_warning "  Distro: unrecognised — package installs may fail"
			;;
	esac

	# 2. Architecture
	local arch
	arch=$(uname -m)
	case "$arch" in
		x86_64 | amd64 | aarch64 | arm64)
			print_success "  Architecture: $arch"
			;;
		*)
			print_warning "  Architecture: $arch — Neovim and Helix binary downloads are not supported on this arch"
			;;
	esac

	# 3. sudo availability (only relevant for non-root)
	if [[ "$EUID" -ne 0 ]]; then
		if command -v sudo >/dev/null 2>&1; then
			print_success "  sudo: available"
		else
			print_error "  sudo: not found — cannot install packages as non-root"
			hard_fail=1
		fi
	else
		print_success "  sudo: running as root"
	fi

	# 4. Network reachability to GitHub (soft check — proxy/firewall may still
	#    intercept individual downloads, but this catches fully offline machines)
	if curl -fsSL --max-time 5 --head "https://github.com" >/dev/null 2>&1; then
		print_success "  Network: GitHub reachable"
	else
		print_warning "  Network: GitHub unreachable — Neovim and Helix downloads will likely fail"
		print_notice "           Run bash scripts/helix.sh and bash scripts/nvim.sh manually once network is available"
	fi

	if [[ "$hard_fail" -ne 0 ]]; then
		print_error "Pre-flight failed. Fix the issues above and re-run setup.sh."
		exit 1
	fi

	print_info "Pre-flight checks passed."
	print_info ""
}

function ensure_prerequisites() {
	# Install git and curl if absent. Runs before ensure_sudo so the package
	# manager is invoked directly. No-op when both tools are already present
	# or when in dry-run mode.
	if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
		return 0
	fi

	if is_dry_run; then
		print_notice "[dry-run] would install missing prerequisites (git, curl)"
		return 0
	fi

	local distro
	distro=$(whichdistro)

	case "$distro" in
		debian)
			print_notice "Installing prerequisites (git, curl)…"
			if [[ "$EUID" -ne 0 ]]; then
				sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y git curl
			else
				env DEBIAN_FRONTEND=noninteractive apt-get install -y git curl
			fi
			;;
		redhat)
			print_notice "Installing prerequisites (git, curl)…"
			if [[ "$EUID" -ne 0 ]]; then
				sudo dnf install -y git curl 2>/dev/null || sudo yum install -y git curl
			else
				dnf install -y git curl 2>/dev/null || yum install -y git curl
			fi
			;;
		arch)
			print_notice "Installing prerequisites (git, curl)…"
			if [[ "$EUID" -ne 0 ]]; then
				sudo pacman -S --noconfirm --needed git curl
			else
				pacman -S --noconfirm --needed git curl
			fi
			;;
		*)
			print_warning "Unknown distro — cannot install prerequisites automatically."
			print_notice "Install git and curl manually, then re-run setup.sh."
			exit 1
			;;
	esac
}

function ensure_sudo() {
	# No-op when already root (Docker / CI) or in dry-run mode — no password needed.
	if [[ "$EUID" -eq 0 ]] || is_dry_run; then
		return 0
	fi

	if ! command -v sudo >/dev/null 2>&1; then
		print_error "Bootstrap needs to install system packages but 'sudo' is not available."
		print_notice "Run as root, or install sudo first (e.g. su -c 'apt-get install sudo')."
		exit 1
	fi

	print_info ""
	print_info "Bootstrap will install system packages and needs elevated privileges."
	print_notice "You will be prompted for your password once. Sudo access is then kept\nactive for the duration of bootstrap so you are not asked again."
	print_info ""

	if ! sudo -v 2>/dev/null; then
		print_error "Could not obtain sudo credentials. Aborting."
		exit 1
	fi

	# Background keepalive: refresh the sudo credential every 30 s so that
	# slow downloads (neovim nightly, helix release) do not expire the ticket.
	(
		while kill -0 "$$" 2>/dev/null; do
			sudo -n true 2>/dev/null || break
			sleep 30
		done
	) &
	_DOTFILES_SUDO_KEEPALIVE=$!
	trap 'kill "$_DOTFILES_SUDO_KEEPALIVE" 2>/dev/null; trap - EXIT INT TERM' EXIT INT TERM
}

function checkinstall() {
	local distro
	distro=$(whichdistro)
	if [[ $distro == "alpine" ]]; then
		print_error "Alpine Linux is not supported by this bootstrap."
		print_notice "Supported distros: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch Linux."
		exit 1
	fi
	if [[ $distro == "redhat" ]]; then
		# Run yum clean all and EPEL/CRB setup only once per bootstrap session.
		# checkinstall is called multiple times; repeating these is wasteful
		# (yum clean all evicts cached metadata unnecessarily on re-runs).
		if [[ "${_DOTFILES_CHECKINSTALL_RHEL_INIT:-false}" != "true" ]]; then
			run_cmd sudo yum clean all
			# EPEL + extra repos only needed on RHEL/CentOS, not Fedora
			if ! grep -qi "fedora" /etc/redhat-release 2>/dev/null; then
				run_cmd sudo yum install -y epel-release
				# RHEL/CentOS 8: powertools; RHEL/CentOS 9+: crb
				local rhel_ver
				rhel_ver=$(grep -oP '(?<=release )\d+' /etc/redhat-release 2>/dev/null | head -1)
				if [[ "${rhel_ver:-0}" -ge 8 ]]; then
					run_cmd sudo dnf install -y 'dnf-command(config-manager)'
					if [[ "${rhel_ver}" -ge 9 ]]; then
						run_cmd sudo dnf config-manager --set-enabled crb
					else
						run_cmd sudo dnf config-manager --set-enabled powertools
					fi
				fi
			fi
			_DOTFILES_CHECKINSTALL_RHEL_INIT=true
		fi
	fi

	local pkgs="$*"
	if [[ $distro == "debian" ]]; then
		pkgs=${pkgs//python-pip/python3-pip}
		run_cmd sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y $pkgs
	elif [[ $distro == "redhat" ]]; then
		run_cmd sudo yum install -y $pkgs
	elif [[ $distro == "arch" ]]; then
		run_cmd sudo pacman -S --noconfirm --needed $pkgs
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