#! /bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]:-$0}")"/utils.sh

distro=$(whichdistro)
if [[ $distro == "redhat" ]]; then
	checkinstall findutils
fi