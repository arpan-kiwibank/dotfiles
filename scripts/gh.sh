#!/usr/bin/env bash

set -euo pipefail

current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
source "$current_dir"/utils.sh

# Install GitHub CLI (gh) using the official package manager method for each
# supported distro. References: https://github.com/cli/cli/blob/trunk/docs/install_linux.md

function install_gh() {
    if command -v gh >/dev/null 2>&1; then
        print_notice "gh CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    print_info "Installing GitHub CLI (gh)"
    local distro
    distro=$(whichdistro)

    case "$distro" in
        debian)
            # Official Debian/Ubuntu keyring + apt source
            if is_dry_run; then
                print_notice "[dry-run] would add cli.github.com apt source and install gh"
                return 0
            fi
            sudo mkdir -p -m 755 /etc/apt/keyrings
            local tmpfile
            tmpfile=$(mktemp)
            wget -nv -O"$tmpfile" https://cli.github.com/packages/githubcli-archive-keyring.gpg
            sudo cp "$tmpfile" /etc/apt/keyrings/githubcli-archive-keyring.gpg
            rm -f "$tmpfile"
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            sudo mkdir -p -m 755 /etc/apt/sources.list.d
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -q
            sudo apt-get install -y gh
            ;;

        redhat)
            if is_dry_run; then
                print_notice "[dry-run] would add cli.github.com rpm repo and install gh"
                return 0
            fi
            if command -v dnf5 >/dev/null 2>&1; then
                # DNF5 (Fedora 41+)
                sudo dnf install -y dnf5-plugins
                sudo dnf config-manager addrepo \
                    --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
                sudo dnf install -y gh --repo gh-cli
            elif command -v dnf >/dev/null 2>&1; then
                # DNF4 (Fedora ≤40, RHEL 8/9)
                sudo dnf install -y 'dnf-command(config-manager)'
                sudo dnf config-manager --add-repo \
                    https://cli.github.com/packages/rpm/gh-cli.repo
                sudo dnf install -y gh --repo gh-cli
            else
                # yum (Amazon Linux 2)
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo \
                    https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
            fi
            ;;

        arch)
            # Official Arch community package
            run_cmd sudo pacman -S --noconfirm github-cli
            ;;

        alpine)
            # Alpine community package
            run_cmd sudo apk add github-cli
            ;;

        *)
            print_warning "gh CLI: automatic install not supported for distro '$distro'"
            print_notice "  Install manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
            return 0
            ;;
    esac

    print_success "GitHub CLI installed: $(gh --version | head -1)"
}

install_gh
