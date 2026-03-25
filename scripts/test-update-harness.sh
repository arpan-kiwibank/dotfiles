#!/usr/bin/env bash

set -euo pipefail

function helpmsg() {
	echo "Usage: ${BASH_SOURCE[0]:-$0} [--keep] [profile ...]" 1>&2
	echo "  profile: full or hypr-minimal (default: both)" 1>&2
	echo "  --keep: keep temporary test directories even on success" 1>&2
}

function fail() {
	echo "[FAIL] $*" 1>&2
	exit 1
}

function create_mock_command() {
	local command_name="$1"
	local mock_dir="$2"
	local root_dir="$3"
	cat > "$mock_dir/$command_name" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' '$command_name' "\$*" >> '$root_dir/commands.log'
if [[ '$command_name' == 'curl' ]]; then
	out=''
	while [[ \$# -gt 0 ]]; do
		case "\$1" in
			-o)
				out="\$2"
				shift 2
				;;
			*)
				shift
				;;
		esac
	done
	if [[ -n "\$out" ]]; then
		: > "\$out"
	fi
	fi
	exit 0
EOF
	chmod +x "$mock_dir/$command_name"
}

function assert_file_contains() {
	local file_path="$1"
	local expected="$2"
	grep -F "$expected" "$file_path" >/dev/null 2>&1 || fail "Expected '$expected' in $file_path"
}

function assert_symlink_target() {
	local symlink_path="$1"
	local expected_target="$2"
	[[ -L "$symlink_path" ]] || fail "Expected symlink: $symlink_path"
	[[ "$(readlink -f "$symlink_path")" == "$expected_target" ]] || fail "Unexpected target for $symlink_path"
}

function run_profile() {
	local dotfiles_dir="$1"
	local profile="$2"
	local keep_tmp="$3"
	local tmp_root
	tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-update-${profile}.XXXXXX")
	local home_dir="$tmp_root/home"
	local cache_dir="$tmp_root/cache"
	local mock_dir="$tmp_root/mockbin"
	mkdir -p "$home_dir" "$cache_dir" "$mock_dir"
	: > "$tmp_root/commands.log"

	create_mock_command apt-get "$mock_dir" "$tmp_root"
	create_mock_command yum "$mock_dir" "$tmp_root"
	create_mock_command dnf "$mock_dir" "$tmp_root"
	create_mock_command pacman "$mock_dir" "$tmp_root"
        create_mock_command chsh "$mock_dir" "$tmp_root"

        # curl mock: write empty file for download calls (-o), return minimal
        # fake JSON for GitHub API calls (stdout, no -o) so version checks
        # get a parseable response.  Both nvim and Helix version checks are
        # fail-open so even empty responses are safe, but a real-shaped response
        # lets the version-check branch exercise properly.
        cat > "$mock_dir/curl" <<'CURLMOCK'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "${MOCK_LOG}"
out=''
is_api=false
for arg in "$@"; do
        case "$arg" in
                -o) ;;
                api.github.com*) is_api=true ;;
                https://api.github.com*) is_api=true ;;
        esac
done
# Capture -o destination
i=1
while [[ $i -le $# ]]; do
        if [[ "${!i}" == "-o" ]]; then
                i=$((i+1))
                out="${!i}"
        fi
        i=$((i+1))
done
if [[ -n "$out" ]]; then
        : > "$out"
elif "$is_api"; then
        # Return a very old release so version checks always see an update
        # available (ensures the binary-download branch is still exercised).
        printf '{"tag_name":"0.1","published_at":"2000-01-01T00:00:00Z"}\n'
fi
exit 0
CURLMOCK
        # Inject log path so the heredoc can reference the outer variable
        sed -i "s|\${MOCK_LOG}|$tmp_root/commands.log|g" "$mock_dir/curl"
        chmod +x "$mock_dir/curl"

        # sudo mock: handle -v (credential check) and -n true (keepalive) as no-ops;
        # pass everything else through so PATH-mocked commands are still reachable.
        cat > "$mock_dir/sudo" <<SUDOMOCK
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> '$tmp_root/commands.log'
case "\$1" in
    -v)       exit 0 ;;   # ensure_sudo: sudo -v credential validation
    -n)       exit 0 ;;   # ensure_sudo: sudo -n true keepalive check
esac
exec "\$@"
SUDOMOCK
        chmod +x "$mock_dir/sudo"

        # hx mock: reports a very old version so the Helix version check always
        # sees an update available — ensures the binary-fallback download path
        # is exercised on every harness run.
        cat > "$mock_dir/hx" <<'HXMOCK'
#!/usr/bin/env bash
echo 'helix 0.0 (mock)'
exit 0
HXMOCK
        chmod +x "$mock_dir/hx"

	# tar mock: logs the call and creates a fake extracted directory when extracting
	# (so helix/nvim post-extract checks can find the directory they expect)
	cat > "$mock_dir/tar" <<TARMOCK
#!/usr/bin/env bash
printf 'tar %s\n' "\$*" >> '$tmp_root/commands.log'
args=("\$@")
for i in "\${!args[@]}"; do
    if [[ "\${args[\$i]}" == "-C" ]] && [[ -n "\${args[\$((i+1))]:-}" ]] && [[ -d "\${args[\$((i+1))]}" ]]; then
        mkdir -p "\${args[\$((i+1))]}/mock-extracted"
        break
    fi
done
exit 0
TARMOCK
	chmod +x "$mock_dir/tar"

	PATH="$mock_dir:$PATH" HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" \
		bash "$dotfiles_dir/scripts/initiate.sh" update --profile "$profile" > "$tmp_root/run.log" 2>&1 || {
		echo "[FAIL] profile=$profile root=$tmp_root" 1>&2
		sed -n '1,200p' "$tmp_root/run.log" 1>&2
		exit 1
	}

	assert_file_contains "$tmp_root/commands.log" "curl -fL --retry 3 --retry-delay 2 -o"
	assert_file_contains "$tmp_root/commands.log" "tar -tzf"
	assert_file_contains "$tmp_root/commands.log" "tar -xzf"
	assert_file_contains "$tmp_root/commands.log" "apt-get install -y gcc"
	assert_symlink_target "$home_dir/.local/bin/alarm" "$dotfiles_dir/local-bin/alarm"
	# hyprland-wrap.sh is skipped when DOTFILES_SKIP_DESKTOP is true (e.g. WSL)
	if grep -q "WSL (skip desktop): local-bin/hyprland-wrap.sh" "$tmp_root/run.log" 2>/dev/null; then
		[[ ! -e "$home_dir/.local/bin/hyprland-wrap.sh" ]] \
			|| fail "hyprland-wrap.sh should not be linked in WSL"
	else
		assert_symlink_target "$home_dir/.local/bin/hyprland-wrap.sh" "$dotfiles_dir/local-bin/hyprland-wrap.sh"
	fi

	echo "[PASS] profile=$profile root=$tmp_root"
	echo "  commands: $(sed -n '1,6p' "$tmp_root/commands.log" | paste -sd ';' -)"
	echo "  local-bin: $(find "$home_dir/.local/bin" -maxdepth 1 -type l | wc -l | tr -d ' ') symlinks"

	if [[ "$keep_tmp" != "true" ]]; then
		rm -rf "$tmp_root"
	fi
}

function main() {
	local keep_tmp="false"
	local -a profiles=()
	local arg

	for arg in "$@"; do
		case "$arg" in
			--help | -h)
				helpmsg
				exit 0
				;;
			--keep)
				keep_tmp="true"
				;;
			full | hypr-minimal)
				profiles+=("$arg")
				;;
			*)
				fail "Unknown argument: $arg"
				;;
		esac
	done

	if [[ ${#profiles[@]} -eq 0 ]]; then
		profiles=(hypr-minimal full)
	fi

	local script_dir
	script_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	local dotfiles_dir
	if command git -C "$script_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
		dotfiles_dir="$(command git -C "$script_dir" rev-parse --show-toplevel)"
	else
		dotfiles_dir="$(builtin cd "$script_dir/.." && pwd -P)"
	fi

	local profile
	for profile in "${profiles[@]}"; do
		run_profile "$dotfiles_dir" "$profile" "$keep_tmp"
	done
}

main "$@"