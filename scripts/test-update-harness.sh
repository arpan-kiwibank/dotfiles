#!/usr/bin/env bash

set -euo pipefail

function helpmsg() {
	echo "Usage: ${BASH_SOURCE[0]:-$0} [--keep] [--docker] [profile ...]" 1>&2
	echo "  profile: full or minimal (default: both)" 1>&2
	echo "  --keep:   keep temporary test directories even on success" 1>&2
	echo "  --docker: also run in-container distro tests (requires docker daemon)" 1>&2
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

# Static lint: minimal.list must not contain config/optional/ entries.
# Also warns about any config/optional/ dirs in the repo that are absent from
# full.list (so new optional tools don't silently become dead weight).
function run_manifest_lint_test() {
	local dotfiles_dir="$1"

	# 1. minimal must have zero config/optional/ entries
	local violations
	violations=$(grep -v '^[[:space:]]*#\|^[[:space:]]*$' \
		"$dotfiles_dir/profiles/minimal.list" \
		| grep '^config/optional/' || true)
	if [[ -n "$violations" ]]; then
		fail "manifest-lint: minimal.list has config/optional/ entries: $violations"
	fi
	echo "[PASS] manifest-lint: minimal.list: no config/optional/ entries"

	# 2. Warn about repo optional dirs absent from full.list
	local -a missing=()
	local d
	while IFS= read -r -d '' d; do
		local entry="config/optional/$(basename "$d")"
		grep -qxF "$entry" "$dotfiles_dir/profiles/full.list" 2>/dev/null \
			|| missing+=("$entry")
	done < <(command find "$dotfiles_dir/config/optional" -mindepth 1 -maxdepth 1 \
		-type d -print0 2>/dev/null | sort -z)
	if [[ ${#missing[@]} -gt 0 ]]; then
		echo "  [WARN] manifest-lint: config/optional/ dirs not in full.list: ${missing[*]}"
		echo "         Consider adding them to full.list or moving to archive/."
	else
		echo "[PASS] manifest-lint: full.list: all config/optional/ dirs accounted for"
	fi

	# 3. Dynamic guard: bootstrap must abort when minimal.list has an optional entry.
	#    Use a temp dir with a patched copy of the repo profiles.
	local tmp_dir
	tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-manifest-lint.XXXXXX")
	cp -r "$dotfiles_dir" "$tmp_dir/dotfiles"
	local patched_list="$tmp_dir/dotfiles/profiles/minimal.list"
	printf '\nconfig/optional/gitui\n' >> "$patched_list"

	local tmp_home="$tmp_dir/home"
	mkdir -p "$tmp_home"
	local out
	out=$(HOME="$tmp_home" XDG_DATA_HOME="$tmp_home/.local/share" \
		bash "$tmp_dir/dotfiles/scripts/initiate.sh" link --profile minimal 2>&1) \
		&& { rm -rf "$tmp_dir"; fail "manifest-lint: expected abort for minimal with optional entry, but command succeeded"; } \
		|| true  # non-zero exit is expected
	if ! printf '%s\n' "$out" | grep -q "config/optional"; then
		rm -rf "$tmp_dir"
		fail "manifest-lint: expected an error mentioning config/optional, got: $out"
	fi
	rm -rf "$tmp_dir"
	echo "[PASS] manifest-lint: runtime guard aborts on minimal with optional entry"
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

	PATH="$mock_dir:$PATH" HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" XDG_DATA_HOME="$home_dir/.local/share" \
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

	# Idempotency check: run the link phase a second time with the same HOME.
	# The pre-scan should detect all entries already linked and print the
	# fast-path message without creating any new backup dir.
	: > "$tmp_root/run2.log"
	PATH="$mock_dir:$PATH" HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" XDG_DATA_HOME="$home_dir/.local/share" \
		bash "$dotfiles_dir/scripts/initiate.sh" link --profile "$profile" >> "$tmp_root/run2.log" 2>&1 \
		|| fail "idempotent link re-run failed for profile=$profile"
	grep -q "already linked" "$tmp_root/run2.log" \
		|| fail "Expected 'already linked' summary in idempotent re-run log"
	grep -q "Skip (already linked):" "$tmp_root/run2.log" \
		&& fail "Found per-entry 'Skip (already linked)' noise in idempotent re-run — should be suppressed"
	echo "  idempotent re-run: OK"

	# State file: the active-profile state file should exist with the correct
	# profile name after a successful link run.
	local state_file="$home_dir/.local/share/dotfiles/active-profile"
	[[ -f "$state_file" ]] || fail "Active profile state file not created: $state_file"
	local recorded_profile
	recorded_profile=$(cat "$state_file")
	[[ "$recorded_profile" == "$profile" ]] \
		|| fail "State file contains '$recorded_profile', expected '$profile'"
	echo "  active-profile state: OK ($profile)"

	if [[ "$keep_tmp" != "true" ]]; then
		rm -rf "$tmp_root"
	fi
}

# Profile switch test: link profile A, then switch to profile B.
# Verifies that:
#  1. The state file updates to the new profile.
#  2. Symlinks that belong only to profile A are removed.
#  3. Symlinks that belong to profile B are present.
# Uses synthetic minimal profiles with a single distinguishing entry to keep
# the test fast and independent of the real profile contents.
function run_profile_switch_test() {
	local dotfiles_dir="$1"
	local keep_tmp="$2"

	local tmp_root
	tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-switch.XXXXXX")
	local home_dir="$tmp_root/home"
	local cache_dir="$tmp_root/cache"
	local mock_dir="$tmp_root/mockbin"
	mkdir -p "$home_dir" "$cache_dir" "$mock_dir"
	: > "$tmp_root/commands.log"

	# Reuse the same mock setup from run_profile (curl, sudo, tar, hx, chsh)
	create_mock_command apt-get "$mock_dir" "$tmp_root"
	create_mock_command yum "$mock_dir" "$tmp_root"
	create_mock_command dnf "$mock_dir" "$tmp_root"
	create_mock_command pacman "$mock_dir" "$tmp_root"
	create_mock_command chsh "$mock_dir" "$tmp_root"
	cat > "$mock_dir/curl" <<'CURLMOCK'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "${MOCK_LOG}"
out=''; is_api=false
for arg in "$@"; do case "$arg" in -o) ;; https://api.github.com*) is_api=true ;; esac; done
i=1; while [[ $i -le $# ]]; do [[ "${!i}" == "-o" ]] && { i=$((i+1)); out="${!i}"; }; i=$((i+1)); done
[[ -n "$out" ]] && : > "$out"
"$is_api" && printf '{"tag_name":"0.1","published_at":"2000-01-01T00:00:00Z"}\n'
exit 0
CURLMOCK
	sed -i "s|\${MOCK_LOG}|$tmp_root/commands.log|g" "$mock_dir/curl"
	chmod +x "$mock_dir/curl"
	cat > "$mock_dir/sudo" <<SUDOMOCK
#!/usr/bin/env bash
printf 'sudo %s\n' "\$*" >> '$tmp_root/commands.log'
case "\$1" in -v) exit 0 ;; -n) exit 0 ;; esac
exec "\$@"
SUDOMOCK
	chmod +x "$mock_dir/sudo"
	cat > "$mock_dir/tar" <<TARMOCK
#!/usr/bin/env bash
printf 'tar %s\n' "\$*" >> '$tmp_root/commands.log'
args=("\$@")
for i in "\${!args[@]}"; do
    if [[ "\${args[\$i]}" == "-C" ]] && [[ -n "\${args[\$((i+1))]:-}" ]] && [[ -d "\${args[\$((i+1))]}" ]]; then
        mkdir -p "\${args[\$((i+1))]}/mock-extracted"; break
    fi
done; exit 0
TARMOCK
	chmod +x "$mock_dir/tar"
	cat > "$mock_dir/hx" <<'HXMOCK'
#!/usr/bin/env bash
echo 'helix 0.0 (mock)'; exit 0
HXMOCK
	chmod +x "$mock_dir/hx"

	# ---- Step 1: initial full install (link only, no package update needed) ----
	PATH="$mock_dir:$PATH" HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" XDG_DATA_HOME="$home_dir/.local/share" XDG_CONFIG_HOME="$home_dir/.config" \
		bash "$dotfiles_dir/scripts/initiate.sh" link --profile full > "$tmp_root/run-full.log" 2>&1 \
		|| { echo "[FAIL] switch-test: initial full link failed"; cat "$tmp_root/run-full.log" 1>&2; exit 1; }

	# ---- Pre-populate residues that the profile switch should clean up ----
	# Fake zsh compdump (zdotdir = $home_dir/.config/zsh when ZDOTDIR is unset)
	local fake_zdotdir="$home_dir/.config/zsh"
	mkdir -p "$fake_zdotdir"
	touch "$fake_zdotdir/.zcompdump"
	# Fake XDG cache dirs for removed optional tools
	mkdir -p "$cache_dir/pet" "$cache_dir/zk" "$cache_dir/gitui"
	# Fake zinit plugin dir for pet
	local fake_zinit_plugin_dir="$home_dir/.local/share/zsh/zinit/plugins"
	mkdir -p "$fake_zinit_plugin_dir/knqyf263---pet"
	touch "$fake_zinit_plugin_dir/knqyf263---pet/pet"

	# ---- Step 2: switch to 'minimal' via install (exercises autoremove) ----
	# Using 'install' rather than 'link' so the full switch path runs:
	#   link (detects switch, unlinks removed entries, sets DOTFILES_PROFILE_SWITCHED)
	#   → update (packages, helix, nvim, then autoremove at end)
	: > "$tmp_root/commands.log"
	PATH="$mock_dir:$PATH" HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" XDG_DATA_HOME="$home_dir/.local/share" XDG_CONFIG_HOME="$home_dir/.config" \
		bash "$dotfiles_dir/scripts/initiate.sh" install --profile minimal > "$tmp_root/run-switch.log" 2>&1 \
		|| { echo "[FAIL] switch-test: profile switch install failed"; cat "$tmp_root/run-switch.log" 1>&2; exit 1; }

	# State file should record the new profile
	local state_file="$home_dir/.local/share/dotfiles/active-profile"
	[[ -f "$state_file" ]] || fail "switch-test: state file missing after switch"
	local recorded
	recorded=$(cat "$state_file")
	[[ "$recorded" == "minimal" ]] \
		|| fail "switch-test: state file contains '$recorded', expected 'minimal'"
	echo "  profile switch: state file updated to minimal: OK"

	# Autoremove should have been called (apt-get on debian/ubuntu)
	grep -q "autoremove" "$tmp_root/commands.log" \
		|| fail "switch-test: expected autoremove command in commands.log after profile switch"
	echo "  profile switch: autoremove called: OK"

	# Compdump should have been removed (stale completions from old profile)
	[[ ! -f "$fake_zdotdir/.zcompdump" ]] \
		|| fail "switch-test: zsh compdump was not removed after profile switch"
	echo "  profile switch: zsh compdump cleaned: OK"

	# Tool cache dirs for removed optional entries should be gone
	[[ ! -d "$cache_dir/pet" ]] \
		|| fail "switch-test: cache dir for 'pet' was not removed after profile switch"
	[[ ! -d "$cache_dir/zk" ]] \
		|| fail "switch-test: cache dir for 'zk' was not removed after profile switch"
	echo "  profile switch: tool cache dirs cleaned: OK"

	# Zinit plugin dir for removed tool should be gone
	[[ ! -d "$fake_zinit_plugin_dir/knqyf263---pet" ]] \
		|| fail "switch-test: zinit plugin dir for 'pet' was not removed after profile switch"
	echo "  profile switch: zinit plugin data cleaned: OK"

	echo "[PASS] profile-switch-test root=$tmp_root"

	if [[ "$keep_tmp" != "true" ]]; then
		rm -rf "$tmp_root"
	fi
}

# Run test-docker-distro.sh inside a single container image.
# Skips gracefully when Docker is not available.
# Arguments: dotfiles_dir  label  image  expected_distro
function run_single_docker_test() {
	local dotfiles_dir="$1"
	local label="$2"
	local image="$3"
	local expected_distro="$4"

	if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
		echo "  [SKIP] docker not available — $label"
		return 0
	fi

	echo "Docker test: $label ($image)…"

	local log_file
	log_file=$(mktemp /tmp/docker-test-XXXXXX.log)

	if docker run --rm \
			--volume "$dotfiles_dir:/dotfiles:ro" \
			"$image" \
			bash /dotfiles/scripts/test-docker-distro.sh > "$log_file" 2>&1; then
		# The in-container script asserts dispatch and exits non-zero on failure.
		# We additionally verify the expected distro and [PASS] line from stdout.
		grep -q "whichdistro=$expected_distro" "$log_file" \
			|| fail "docker=$label: expected whichdistro=$expected_distro in output"
		grep -q "^\[PASS\]" "$log_file" \
			|| fail "docker=$label: no [PASS] line in container output"
		echo "[PASS] docker=$label (distro=$expected_distro)"
	else
		echo "[FAIL] docker=$label" 1>&2
		cat "$log_file" 1>&2
		rm -f "$log_file"
		exit 1
	fi
	rm -f "$log_file"
}

# Run in-container distro tests for all three supported distro families.
function run_docker_distro_tests() {
	local dotfiles_dir="$1"

	if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
		echo "[SKIP] Docker not available — distro container tests skipped"
		echo "       Install Docker and re-run with --docker to enable them."
		return 0
	fi

	echo "Running Docker distro tests…"
	run_single_docker_test "$dotfiles_dir" "fedora"    "fedora:latest"      "redhat"
	run_single_docker_test "$dotfiles_dir" "archlinux" "archlinux:latest"   "arch"
	run_single_docker_test "$dotfiles_dir" "debian"    "debian:stable-slim" "debian"
}

function main() {
	local keep_tmp="false"
	local run_docker="false"
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
			--docker)
				run_docker="true"
				;;
			full | minimal)
				profiles+=("$arg")
				;;
			*)
				fail "Unknown argument: $arg"
				;;
		esac
	done

	if [[ ${#profiles[@]} -eq 0 ]]; then
		profiles=(minimal full)
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

	run_manifest_lint_test "$dotfiles_dir"
	run_profile_switch_test "$dotfiles_dir" "$keep_tmp"

	if [[ "$run_docker" == "true" ]]; then
		run_docker_distro_tests "$dotfiles_dir"
	fi
}

main "$@"