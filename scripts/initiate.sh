#! /bin/bash

set -euo pipefail

#--------------------------------------------------------------#
##          Functions                                         ##
#--------------------------------------------------------------#

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [install | update | link] [--profile <name>] [--dry-run | -n] [--allow-desktop] [--help | -h]" 0>&2
	print_default "  install: add require package install and symbolic link to $HOME from dotfiles [default]"
	print_default "  update: add require package install or update."
	print_default "  link: only symbolic link to $HOME from dotfiles."
	print_default "  --profile: full (default) or minimal."
	print_default "  --dry-run: print planned changes without modifying the system."
	print_default "  --allow-desktop: in WSL, link config/desktop/** entries anyway (default: skipped in WSL)."
	print_default ""
}

function ensure_zsh_default_shell() {
	if ! command -v zsh >/dev/null 2>&1; then
		print_warning "zsh is not installed yet; skipping default-shell step"
		return 0
	fi

	if ! command -v chsh >/dev/null 2>&1; then
		print_warning "chsh command not available; skipping default-shell step"
		return 0
	fi

	local current_shell
	if command -v getent >/dev/null 2>&1; then
		current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
	else
		current_shell=$(grep "^$(id -un):" /etc/passwd | cut -d: -f7)
	fi
	local zsh_path
	zsh_path=$(command -v zsh)

	if [[ "$current_shell" == "$zsh_path" ]]; then
		print_notice "Default shell already set to zsh"
		return 0
	fi

	if [[ -r /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
		print_warning "$zsh_path is not listed in /etc/shells; skipping default-shell step"
		return 0
	fi

	if is_dry_run; then
		print_notice "[dry-run] would change default shell to $zsh_path"
		return 0
	fi

	if run_cmd chsh -s "$zsh_path" "$(id -un)"; then
		print_success "Default shell changed to zsh"
	else
		print_warning "Could not change default shell to zsh automatically"
		print_notice "Run manually: chsh -s $zsh_path $(id -un)"
	fi
}

# Remove system packages that are no longer needed after a profile switch.
# Non-fatal: a failure prints a warning and lets the caller decide.
function run_autoremove() {
	print_info "Removing orphaned packages left by the previous profile"
	case "$(whichdistro)" in
		debian)
			run_cmd sudo env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
			;;
		redhat)
			run_cmd sudo yum autoremove -y
			;;
		arch)
			local orphans
			orphans=$(pacman -Qdtq 2>/dev/null) || true
			if [[ -n "$orphans" ]]; then
				# shellcheck disable=SC2086
				run_cmd sudo pacman -Rns $orphans --noconfirm
			else
				print_notice "No orphaned packages to remove"
			fi
			;;
		*)
			print_warning "Package autoremove not supported on this distro; run manually if needed"
			;;
	esac
}

#--------------------------------------------------------------#
##          main                                              ##
#--------------------------------------------------------------#

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source "$current_dir"/utils.sh
	local dotfiles_dir
	if command git -C "$current_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
		dotfiles_dir="$(command git -C "$current_dir" rev-parse --show-toplevel)"
	else
		dotfiles_dir="$(builtin cd "$current_dir/.." && pwd -P)"
	fi

	local is_install="false"
	local is_link="false"
	local is_update="false"
	local action=""
	local dry_run="${DOTFILES_DRY_RUN:-false}"
	local profile="${DOTFILES_PROFILE:-full}"
	local allow_desktop="false"

	while [ $# -gt 0 ]; do
		case ${1} in
			--help | -h)
				helpmsg
				exit 1
				;;
			--dry-run | -n)
				dry_run="true"
				;;
			--allow-desktop)
				allow_desktop="true"
				;;
			--profile)
				if [[ $# -lt 2 ]]; then
					echo "[ERROR] --profile requires a value"
					helpmsg
					exit 1
				fi
				profile="$2"
				shift
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

	case "$profile" in
			full | minimal)
			;;
		*)
				echo "[ERROR] Invalid profile '$profile' (supported: full, minimal)"
			helpmsg
			exit 1
			;;
	esac

	if [[ "$dry_run" == "true" ]]; then
		export DOTFILES_DRY_RUN=true
		print_notice "Dry-run mode enabled"
	fi

	export DOTFILES_PROFILE="$profile"
	print_notice "Profile: $DOTFILES_PROFILE"

	# WSL2 does not provide DRM/GPU access — Hyprland and Sway require bare-metal hardware.
	# Skip config/desktop/** linking unless --allow-desktop is explicitly passed.
	if is_wsl; then
		if [[ "$allow_desktop" == "true" ]]; then
			print_warning "WSL detected: --allow-desktop passed, linking desktop entries anyway"
		else
			export DOTFILES_SKIP_DESKTOP=true
			print_warning "WSL detected: skipping config/desktop/** entries (no DRM/GPU in WSL2)"
			print_notice "  Pass --allow-desktop to link desktop entries anyway"
		fi
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

	# Ensure git and curl are present before anything else runs.
	# Prompt for sudo once, before any package installs begin, and keep the
	# credential alive in the background. link-only skips this entirely.
	if [[ "$is_install" == "true" || "$is_update" == "true" ]]; then
		preflight_check
		ensure_prerequisites
		ensure_sudo
	fi

	if [[ "$is_install" = true ]]; then
		source "$current_dir"/required-packages.sh
	fi

	if [[ "$is_link" = true ]]; then
		source "$current_dir"/home-dir.sh
		
		# Fix permissions on zsh completion directories to satisfy compinit security checks
		if [[ -d "$HOME/.config/zsh/completions.local" ]]; then
			run_cmd chmod 700 "$HOME/.config/zsh" 2>/dev/null || true
			run_cmd chmod 700 "$HOME/.config/zsh/completions.local" 2>/dev/null || true
			run_cmd chmod 644 "$HOME/.config/zsh/completions.local"/* 2>/dev/null || true
			run_cmd chmod 644 "$HOME/.config/zsh/completions.local"/.[^.]* 2>/dev/null || true
		fi
		
		print_info ""
		print_info "#####################################################"
		print_info "$(basename "${BASH_SOURCE[0]:-$0}") link success!!!"
		print_info "#####################################################"
		print_info ""

		# Link-only run: no package phase will follow, so if a profile switch was
		# detected remind the user to use setup.sh for a full switch including
		# orphaned package removal.
		if [[ "${DOTFILES_PROFILE_SWITCHED:-false}" == "true" && "$is_update" != "true" ]]; then
			print_notice "Profile switched (link only). To also remove orphaned packages, re-run via:"
			print_notice "  ./setup.sh --profile $DOTFILES_PROFILE"
		fi
	fi

	if [[ "$is_update" = true ]]; then
		source "$current_dir"/basic-packages.sh
		ensure_zsh_default_shell
		source "$current_dir"/helix.sh
		install_helix || print_warning "Helix install failed; run scripts/helix.sh manually to retry"
		source "$current_dir"/nvim.sh
		neovim_nightly || print_warning "Neovim nightly install failed; run scripts/nvim.sh manually to retry"
		run_cmd mkdir -p "$HOME/.local/bin"
		for bin_file in "$dotfiles_dir"/local-bin/*; do
			[[ -e "$bin_file" ]] || continue
			if [[ "$(basename "$bin_file")" == "hyprland-wrap.sh" && "${DOTFILES_SKIP_DESKTOP:-false}" == "true" ]]; then
				print_notice "WSL (skip desktop): local-bin/hyprland-wrap.sh"
				continue
			fi
			run_cmd ln -snf "$bin_file" "$HOME/.local/bin/"
		done

		# After a profile switch remove packages that are no longer needed.
		if [[ "${DOTFILES_PROFILE_SWITCHED:-false}" == "true" ]]; then
			run_autoremove || print_warning "Package autoremove failed; run manually if needed"
		fi
	fi

	print_info ""
	print_info "#####################################################"
	print_info "$(basename "${BASH_SOURCE[0]:-$0}") update finish!!!"
	print_info "#####################################################"
	print_info ""
	
}

main "$@"
