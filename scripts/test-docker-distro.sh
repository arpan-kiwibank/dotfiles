#!/usr/bin/env bash
# In-container distro compatibility test.
#
# Expected invocation (from test-update-harness.sh --docker):
#   docker run --rm -v /path/to/dotfiles:/dotfiles:ro <image> \
#       bash /dotfiles/scripts/test-docker-distro.sh
#
# Purpose:
#   1. Verify whichdistro() returns the expected string for this container's OS.
#   2. Verify checkinstall() dispatches to the correct package manager.
#   3. Verify all bootstrap scripts parse correctly on this distro's bash.
#
# No network access is required. All package managers, curl, tar, hx, and
# chsh are stubbed in /tmp/stubbin so nothing is actually installed.
# The container is always run as root (Docker default), so ensure_sudo is a no-op.

set -euo pipefail

readonly dotfiles_dir=/dotfiles
readonly stubbin=/tmp/stubbin
readonly log=/tmp/commands.log

source "$dotfiles_dir/scripts/utils.sh"

# -----------------------------------------------------------------------
# 1. Distro detection
# -----------------------------------------------------------------------
distro=$(whichdistro)
[[ -n "$distro" ]] || { echo "[FAIL] whichdistro returned empty"; exit 1; }
echo "INFO: whichdistro=$distro"

# -----------------------------------------------------------------------
# 2. Bash syntax check for all bootstrap scripts
# -----------------------------------------------------------------------
for f in "$dotfiles_dir"/scripts/*.sh; do
	bash -n "$f" || { echo "[FAIL] bash syntax error in $f"; exit 1; }
done
echo "INFO: all scripts syntax OK on $(bash --version | head -1)"

# -----------------------------------------------------------------------
# 3. Build stubs — log all calls, never actually install or download
# -----------------------------------------------------------------------
mkdir -p "$stubbin"
: > "$log"
export PATH="$stubbin:$PATH"

# Package managers: log the call and exit 0
for cmd in apt-get yum dnf pacman apt-cache; do
	cat > "$stubbin/$cmd" <<-EOF
	#!/usr/bin/env bash
	printf '%s %s\n' '$cmd' "\$*" >> '$log'
	exit 0
	EOF
	chmod +x "$stubbin/$cmd"
done

# curl: write empty file for -o destination; return minimal JSON for API calls
cat > "$stubbin/curl" <<'CURLSTUB'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> '_LOG_'
out=''; is_api=false
for arg in "$@"; do
	case "$arg" in https://api.github.com*) is_api=true ;; esac
done
i=1; while [[ $i -le $# ]]; do
	[[ "${!i}" == "-o" ]] && { i=$((i+1)); out="${!i}"; }
	i=$((i+1))
done
[[ -n "$out" ]] && : > "$out"
"$is_api" && printf '{"tag_name":"0.1","published_at":"2000-01-01T00:00:00Z"}\n'
exit 0
CURLSTUB
sed -i "s|_LOG_|$log|g" "$stubbin/curl"
chmod +x "$stubbin/curl"

# tar: creates a fake extracted dir for helix/nvim post-extract checks
cat > "$stubbin/tar" <<-TARSTUB
#!/usr/bin/env bash
printf 'tar %s\n' "\$*" >> '$log'
args=("\$@")
for i in "\${!args[@]}"; do
	if [[ "\${args[\$i]}" == "-C" ]] && [[ -n "\${args[\$((i+1))]:-}" ]] && [[ -d "\${args[\$((i+1))]}" ]]; then
		mkdir -p "\${args[\$((i+1))]}/mock-extracted"; break
	fi
done
exit 0
TARSTUB
chmod +x "$stubbin/tar"

# hx: report a very old version so install_helix always sees an update
cat > "$stubbin/hx" <<'HXSTUB'
#!/usr/bin/env bash
echo 'helix 0.0 (in-container stub)'
exit 0
HXSTUB
chmod +x "$stubbin/hx"

# chsh: no-op
cat > "$stubbin/chsh" <<'CHSHSTUB'
#!/usr/bin/env bash
exit 0
CHSHSTUB
chmod +x "$stubbin/chsh"

# wget: used by gh.sh Debian branch to fetch the GitHub CLI GPG keyring.
# Writes empty file to -O destination so subsequent cp succeeds.
cat > "$stubbin/wget" <<WGETSTUB
#!/usr/bin/env bash
printf 'wget %s\n' "\$*" >> '$log'
i=1; while [[ \$i -le \$# ]]; do
    if [[ "\${!i}" == -O* ]]; then
        dest="\${!i#-O}"
        [[ -z "\$dest" ]] && { i=\$((i+1)); dest="\${!i}"; }
        [[ -n "\$dest" ]] && : > "\$dest"
    fi
    i=\$((i+1))
done
exit 0
WGETSTUB
chmod +x "$stubbin/wget"

# sudo: pass through so package-manager stubs in PATH remain reachable.
# Running as root in Docker so ensure_sudo() already returns 0, but
# checkinstall still emits run_cmd sudo <pkg-mgr> commands.
cat > "$stubbin/sudo" <<'SUDOSTUB'
#!/usr/bin/env bash
case "$1" in
	-v | -n) exit 0 ;;
esac
exec "$@"
SUDOSTUB
chmod +x "$stubbin/sudo"

# -----------------------------------------------------------------------
# 4. Run the full update pipeline
# -----------------------------------------------------------------------
# initiate.sh resolves the dotfiles root via:
#   command git -C "$current_dir" rev-parse --show-toplevel (may fail here)
# Fallback: builtin cd "$current_dir/.." && pwd -P  → /dotfiles  ✓
# So no git stub is needed — the directory fallback resolves correctly.

export HOME=/tmp/testhome
export XDG_CACHE_HOME=/tmp/testcache
export XDG_DATA_HOME=/tmp/testhome/.local/share
mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"

bash "$dotfiles_dir/scripts/initiate.sh" update --profile full 2>&1 | tee /tmp/run.log

# -----------------------------------------------------------------------
# 5. Assert correct package manager was dispatched
# -----------------------------------------------------------------------
case "$distro" in
	redhat)
		grep -qE "yum install|dnf install" "$log" \
			|| { echo "[FAIL] expected yum/dnf install in commands.log"; cat "$log"; exit 1; }
		echo "INFO: package dispatch to yum/dnf: OK"
		;;
	arch)
		grep -q "pacman -S" "$log" \
			|| { echo "[FAIL] expected 'pacman -S' in commands.log"; cat "$log"; exit 1; }
		echo "INFO: package dispatch to pacman: OK"
		;;
	debian)
		grep -q "apt-get install" "$log" \
			|| { echo "[FAIL] expected 'apt-get install' in commands.log"; cat "$log"; exit 1; }
		echo "INFO: package dispatch to apt-get: OK"
		;;
	*)
		echo "[FAIL] unexpected distro: $distro"
		exit 1
		;;
esac

echo "[PASS] distro=$distro"
